//
//  SafariView.swift
//  Decentralized
//
//  Created by Nekilc on 2024/10/11.
//

import Foundation
import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        nsView.load(request)
    }
}
