//
//  InstagramConnectViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 12/07/2021.
//

import UIKit
import WebKit

class InstagramConnectViewController: UIViewController {
    @IBOutlet weak var webViewContainer: UIView!
    
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var connectUrl: URL!
    var webView: WKWebView!
    var onSuccessfullAuthorize: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadUrl()
    }

    private func setupWebView() {
        webView = WKWebView(frame: webViewContainer.bounds)
        webViewContainer.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: webViewContainer.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: webViewContainer.trailingAnchor),
            webView.topAnchor.constraint(equalTo: webViewContainer.topAnchor),
            webView.bottomAnchor.constraint(equalTo: webViewContainer.bottomAnchor)
        ])
        webView.allowsBackForwardNavigationGestures = true
        webView.uiDelegate = self
        webView.navigationDelegate = self
    }
    
    private func loadUrl() {
        webView.load(URLRequest(url: connectUrl))
    }
    
    func checkRequestForCallbackURL(request: URLRequest) -> Bool {
        let requestURLString = (request.url?.absoluteString)! as String
        if requestURLString.hasPrefix(InstaAPI.INSTAGRAM_REDIRECT_URI) {
            return false
        }
        return true
    }

    struct InstaAPI{
        static let INSTAGRAM_AUTHURL = "https://api.instagram.com/oauth/authorize/"
        static let INSTAGRAM_REDIRECT_URI = "https://orbis-v2.rj.r.appspot.com/igoauth/callback"
    }
}

extension InstagramConnectViewController: WKUIDelegate, WKNavigationDelegate {
    func webViewDidClose(_ webView: WKWebView) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if checkRequestForCallbackURL(request: navigationAction.request) {
            decisionHandler(.allow)
        }
        else {
            decisionHandler(.allow)
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] timer in
                self?.onSuccessfullAuthorize?()
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }
}
