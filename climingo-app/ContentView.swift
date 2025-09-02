import SwiftUI
@preconcurrency import WebKit
import AVFoundation
import Photos

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        sleep(2)
        // WKWebViewConfiguration 설정
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        
        // JavaScript 메시지 핸들러 추가
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "share")
        userContentController.add(context.coordinator, name: "downloadImage")
        webConfiguration.userContentController = userContentController
        
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true // 뒤로가기 및 앞으로가기 제스처 허용
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        // Handle JavaScript alert
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            showAlert(message: message, completionHandler: completionHandler)
        }
        
        // Handle JavaScript confirm
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            showConfirm(message: message, completionHandler: completionHandler)
        }
        
        private func showAlert(message: String, completionHandler: @escaping () -> Void) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                return
            }
            
            let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
                completionHandler()
            }))
            
            rootViewController.present(alert, animated: true, completion: nil)
        }
        
        private func showConfirm(message: String, completionHandler: @escaping (Bool) -> Void) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                return
            }
            
            let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
                completionHandler(true)
            }))
            alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { _ in
                completionHandler(false)
            }))
            
            rootViewController.present(alert, animated: true, completion: nil)
        }
        
        // MARK: - WKScriptMessageHandler
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "share" {
                handleShareMessage(message.body, webView: message.webView)
            } else if message.name == "downloadImage" {
                handleDownloadImageMessage(message.body, webView: message.webView)
            }
        }
        
        private func handleShareMessage(_ messageBody: Any, webView: WKWebView?) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                return
            }
            
            var shareItems: [Any] = []
            var shareText = ""
            var shareUrl: URL?
            
            if let messageDict = messageBody as? [String: Any] {
                if let text = messageDict["text"] as? String {
                    shareText = text
                    shareItems.append(text)
                }
                
                if let urlString = messageDict["url"] as? String,
                   let url = URL(string: urlString) {
                    shareUrl = url
                    shareItems.append(url)
                }
                
                if let title = messageDict["title"] as? String, !title.isEmpty {
                    if !shareText.isEmpty {
                        shareText = "\(title)\n\(shareText)"
                    } else {
                        shareText = title
                    }
                    shareItems.removeAll()
                    shareItems.append(shareText)
                    if let url = shareUrl {
                        shareItems.append(url)
                    }
                }
            } else if let text = messageBody as? String {
                shareItems.append(text)
            }
            
            if shareItems.isEmpty {
                shareItems.append("오늘도 바위를 얻어보세요! - Climingo")
            }
            
            // 웹에 공유 시작 알림
            notifyWebOfShareStart(webView: webView)
            
            let activityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
            
            // 공유 완료 핸들러 추가
            activityViewController.completionWithItemsHandler = { [weak self] activityType, completed, returnedItems, error in
                if let error = error {
                    self?.notifyWebOfShareResult(webView: webView, success: false, activityType: activityType?.rawValue, message: "공유 중 오류가 발생했습니다: \(error.localizedDescription)")
                } else if completed {
                    let activityName = self?.getActivityTypeName(activityType) ?? "알 수 없는 앱"
                    self?.notifyWebOfShareResult(webView: webView, success: true, activityType: activityType?.rawValue, message: "\(activityName)(으)로 공유되었습니다.")
                } else {
                    self?.notifyWebOfShareResult(webView: webView, success: false, activityType: activityType?.rawValue, message: "공유가 취소되었습니다.")
                }
            }
            
            // iPad에서 popover 설정
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityViewController, animated: true, completion: nil)
        }
        
        private func handleDownloadImageMessage(_ messageBody: Any, webView: WKWebView?) {
            guard let messageDict = messageBody as? [String: Any],
                  let urlString = messageDict["url"] as? String,
                  let imageUrl = URL(string: urlString),
                  let webView = webView else {
                notifyWebOfDownloadResult(webView: webView, success: false, message: "잘못된 이미지 URL입니다.")
                return
            }
            
            // 웹에 다운로드 시작 알림
            notifyWebOfDownloadStart(webView: webView)
            
            downloadImage(from: imageUrl, webView: webView)
        }
        
        private func downloadImage(from url: URL, webView: WKWebView) {
            let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.notifyWebOfDownloadResult(webView: webView, success: false, message: "다운로드 실패: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let data = data,
                          let image = UIImage(data: data) else {
                        self?.notifyWebOfDownloadResult(webView: webView, success: false, message: "이미지 형식이 올바르지 않습니다.")
                        return
                    }
                    
                    self?.saveImageToPhotoLibrary(image: image, webView: webView)
                }
            }
            task.resume()
        }
        
        private func saveImageToPhotoLibrary(image: UIImage, webView: WKWebView) {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized, .limited:
                        PHPhotoLibrary.shared().performChanges {
                            PHAssetChangeRequest.creationRequestForAsset(from: image)
                        } completionHandler: { success, error in
                            DispatchQueue.main.async {
                                if success {
                                    self.notifyWebOfDownloadResult(webView: webView, success: true, message: "이미지가 사진 앨범에 저장되었습니다.")
                                } else {
                                    self.notifyWebOfDownloadResult(webView: webView, success: false, message: "사진 앨범 저장에 실패했습니다.")
                                }
                            }
                        }
                    case .denied, .restricted:
                        self.notifyWebOfDownloadResult(webView: webView, success: false, message: "사진 앨범 접근 권한이 필요합니다.")
                    case .notDetermined:
                        self.notifyWebOfDownloadResult(webView: webView, success: false, message: "사진 앨범 접근 권한을 확인할 수 없습니다.")
                    @unknown default:
                        self.notifyWebOfDownloadResult(webView: webView, success: false, message: "알 수 없는 권한 상태입니다.")
                    }
                }
            }
        }
        
        private func notifyWebOfDownloadStart(webView: WKWebView?) {
            let script = "window.onImageDownloadStart && window.onImageDownloadStart();"
            webView?.evaluateJavaScript(script, completionHandler: nil)
        }
        
        private func notifyWebOfDownloadResult(webView: WKWebView?, success: Bool, message: String) {
            let script = """
                window.onImageDownloadComplete && window.onImageDownloadComplete({
                    success: \(success),
                    message: '\(message)'
                });
            """
            webView?.evaluateJavaScript(script, completionHandler: nil)
        }
        
        private func notifyWebOfShareStart(webView: WKWebView?) {
            let script = "window.onShareStart && window.onShareStart();"
            webView?.evaluateJavaScript(script, completionHandler: nil)
        }
        
        private func notifyWebOfShareResult(webView: WKWebView?, success: Bool, activityType: String?, message: String) {
            let activityTypeString = activityType ?? "unknown"
            let script = """
                window.onShareComplete && window.onShareComplete({
                    success: \(success),
                    activityType: '\(activityTypeString)',
                    message: '\(message)'
                });
            """
            webView?.evaluateJavaScript(script, completionHandler: nil)
        }
        
        private func getActivityTypeName(_ activityType: UIActivity.ActivityType?) -> String {
            guard let activityType = activityType else { return "알 수 없는 앱" }
            
            switch activityType {
            case .message:
                return "메시지"
            case .mail:
                return "메일"
            case .copyToPasteboard:
                return "클립보드"
            case .postToFacebook:
                return "Facebook"
            case .postToTwitter:
                return "Twitter"
            case .postToWeibo:
                return "Weibo"
            case .saveToCameraRoll:
                return "사진"
            case .airDrop:
                return "AirDrop"
            default:
                return "다른 앱"
            }
        }
    }
}

struct ContentView: View {
    @State private var showDeveloperMode = false
    @State private var tapCount = 0
    @State private var currentUrl = URL(string: UserDefaults.standard.string(forKey: "currentUrl") ?? "https://app.climingo.xyz")!
    var body: some View {
        
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all) // 배경을 흰색으로 설정
            VStack {
                WebView(url: currentUrl)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
            }
            .padding(.horizontal, 0) // 수평 패딩을 0으로 설정
            .padding(.top, 1) // 상단 패딩이 0이면 노치 위로 배경이 보임
            .padding(.bottom, 0) // 하단 패딩을 0으로 설정
            .onAppear {
                requestPermissions()
            }
            
            if showDeveloperMode {
                DeveloperModeView(currentUrl: $currentUrl)
            }
            
            GeometryReader { geometry in
                Color.clear
                    .frame(width: 80, height: 30)
                    .position(x: geometry.size.width / 2, y: 10)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tapCount += 1
                        if tapCount == 7 {
                            tapCount = 0
                            authenticateDeveloper()
                        }
                    }
            }
            .frame(width: UIScreen.main.bounds.width, height: 20)
            .position(x: UIScreen.main.bounds.width / 2, y: 10)
        }
    }
    
    
    private func authenticateDeveloper() {
        let password = "climb_dev"
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let alert = UIAlertController(title: "Developer Mode", message: "비밀번호를 입력하세요", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
            if let input = alert.textFields?.first?.text, input == password {
                showDeveloperMode = true
            } else {
                let errorAlert = UIAlertController(title: "", message: "비밀번호가 틀렸습니다.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "확인", style: .default))
                rootViewController.present(errorAlert, animated: true)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        rootViewController.present(alert, animated: true)
    }
    
    private func requestPermissions() {
        // Request Camera Permission
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                print("카메라 접근이 허용되었습니다.")
            } else {
                print("카메라 접근이 거부되었습니다.")
            }
        }
        
        // Request Photo Library Permission
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                print("앨범 접근이 허용되었습니다.")
            case .denied, .restricted:
                print("앨범 접근이 제한되었습니다.")
            case .notDetermined:
                print("앨범 접근이 거부되었습니다.")
            default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
}