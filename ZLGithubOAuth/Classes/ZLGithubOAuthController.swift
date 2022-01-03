//
//  ZLGithubOAuthController.swift
//  ZLGithubOAuth
//
//  Created by 朱猛 on 2022/1/2.
//

import UIKit
import WebKit
import SnapKit

protocol ZLGithubOAuthControllerDelegate: AnyObject {
    
    // 授权类型
    func getOAuthType(serialNumber: String) -> ZLGithubOAuthType?
    
    /// 授权码 URL
    func getAuthorizeCodeURL(serialNumber: String) -> URL?
    
    ///  授权回调 URL
    func getAuthorizeCodeRedirectURL(serialNumber: String) -> String?
    
    ///  授权成功
    func onAuthorizeCodeSuccess(code: String, serialNumber: String)
    
    ///  授权失败
    func onAuthorizeCodeFail(error: Error, serialNumber: String)
    
    ///  关闭授权
    func onOAuthClose(serialNumber: String)
}

class ZLGithubOAuthController: UIViewController {
    
    //
    private weak var delegate: ZLGithubOAuthControllerDelegate?
    
    /// 流水号 跟踪一次授权流程
    private var serialNumber: String
    
    //
    private var isEnd: Bool = false
    
    init(delegate: ZLGithubOAuthControllerDelegate, serialNumber: String) {
        self.delegate = delegate
        self.serialNumber = serialNumber
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var webView: WKWebView = {
        let webView = WKWebView(frame: CGRect.zero)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        return webView
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("关闭", for: .normal)
        if #available(iOS 13.0, *) {
            button.setTitleColor(UIColor.label, for: .normal)
        } else {
            button.setTitleColor(UIColor.black, for: .normal)
        }
        button.addTarget(self, action: #selector(onCloseButtonClicked), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.startOAuth()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.isEnd {
            self.close()
        }
    }
    
    private func setupUI() {
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        view.addSubview(webView)
        view.addSubview(closeButton)
        
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(20)
            make.right.equalTo(-20)
            make.size.equalTo(CGSize(width: 100, height: 50))
        }
    }
    
    func close() {
        
        webView.stopLoading()
        if let naviationController = self.navigationController {
            naviationController.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func onCloseButtonClicked() {
        delegate?.onOAuthClose(serialNumber: self.serialNumber)
        close()
    }
    
    
    private func startOAuth() {
        guard let type = self.delegate?.getOAuthType(serialNumber: self.serialNumber) else {
            isEnd = true
            return
        }
        
        switch type {
        case .code:
            startCodeOAuth()
        case .device:
            startDevideOAuth()
        }
    }
    
    
    private func startDevideOAuth() {
        // to-do
    }
    
    private func startCodeOAuth() {
        guard let oauthURL = self.delegate?.getAuthorizeCodeURL(serialNumber: self.serialNumber) else {
            isEnd = true
            return
        }
        var request = URLRequest(url: oauthURL)
        request.method = .get
        webView.load(request)
    }
    
    
    private func parseCallBackURL(url: URL) {
        // https://docs.github.com/en/developers/apps/managing-oauth-apps/troubleshooting-authorization-request-errors
        if let queryStr = url.query {
            var code: String?
            var state: String?
            var error: String?
            var error_description: String?
            
            let keyValueArray = queryStr.split(separator: "&")
            for keyValue in keyValueArray {
                let keyValuePair =  String(keyValue).split(separator: "=")
                if "code" == keyValuePair.first {
                    code = String(keyValuePair.last ?? "")
                }
                if "state" == keyValuePair.first {
                    state = String(keyValuePair.last ?? "")
                }
                if "error" == keyValuePair.first {
                    error = String(keyValuePair.last ?? "")
                }
                if "error_description" == keyValuePair.first {
                    error_description = String(keyValuePair.last ?? "")
                }
            }
            if let state = state,
               state == self.serialNumber {
                
                if let code = code {
                    self.delegate?.onAuthorizeCodeSuccess(code: code, serialNumber: self.serialNumber)
                    self.close()
                }
                
                if let error_description = error_description {
                    self.delegate?.onAuthorizeCodeFail(error: ZLGithubOAuthError.authorizeError(desc: error_description), serialNumber: self.serialNumber)
                    self.close()
                }
            }
        }
    }
    
}

extension ZLGithubOAuthController: WKUIDelegate,WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.delegate?.onAuthorizeCodeFail(error: error, serialNumber: serialNumber)
        self.close()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.delegate?.onAuthorizeCodeFail(error: error, serialNumber: serialNumber)
        self.close()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let currentRequestURL = navigationAction.request.url,
           let redirectURL = self.delegate?.getAuthorizeCodeRedirectURL(serialNumber: serialNumber),
           currentRequestURL.absoluteString.hasPrefix(redirectURL) {
            self.parseCallBackURL(url: currentRequestURL)
        }
        decisionHandler(.allow)
        
    }
}