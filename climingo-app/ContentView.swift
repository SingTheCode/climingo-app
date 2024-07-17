import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
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
    }
}

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all) // 배경을 흰색으로 설정
            VStack {
                WebView(url: URL(string: "https://app.climingo.xyz")!)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
            }
            .padding(.horizontal, 0) // 수평 패딩을 0으로 설정
            .padding(.top, 1) // 상단 패딩이 0이면 노치 위로 배경이 보임
            .padding(.bottom, 0) // 하단 패딩을 0으로 설정
        }
    }
}

#Preview {
    ContentView()
}
