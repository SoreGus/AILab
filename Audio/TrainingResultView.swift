//
//  TrainingResultView.swift
//  Audio
//
//  Created by Gustavo Soré on 28/05/24.
//

import SwiftUI
import WebKit

struct TrainingResultView: View {
    @Binding var isPresented: Bool
    var result: String

    var body: some View {
        VStack {
            if result.contains("<html") {
                WebView(htmlContent: result)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text(result)
                    .font(.headline)
                    .padding()
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                isPresented = false
            }) {
                Text("Fechar")
                    .bold()
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 10)
    }
}

struct WebView: UIViewRepresentable {
    let htmlContent: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: nil)
    }
}

