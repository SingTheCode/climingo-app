//
//  ContentView.swift
//  climingo-app
//
//  Created by emart on 7/16/24.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
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
