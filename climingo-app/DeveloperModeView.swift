//
//  SwiftUIView.swift
//  climingo-app
//
//  Created by emart on 8/8/24.
//

import SwiftUI

struct DeveloperModeView: View {
    @Binding var currentUrl: URL
    
    var body: some View {
        VStack {
            Text("Developer Mode")
                .font(.largeTitle)
                .padding()
            
            Button(action: {
                changeUrl(to: "https://dev-app.climingo.xyz")
            }) {
                Text("Dev")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: {
                changeUrl(to: "https://stg-app.climingo.xyz")
            }) {
                Text("Stg")
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: {
                changeUrl(to: "https://app.climingo.xyz")
            }) {
                Text("Prd")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding()
    }
    
    private func changeUrl(to urlString: String) {
        currentUrl = URL(string: urlString)!
        UserDefaults.standard.set(urlString, forKey: "currentUrl")
        exit(0) // 앱 종료
    }
}

#Preview {
    ContentView()
}
