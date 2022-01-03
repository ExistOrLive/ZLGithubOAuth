//
//  ZLGithubOAuthManager.swift
//  ZLGithubOAuth
//
//  Created by zhumeng on 01/02/2022.
//  Copyright (c) 2022 zhumeng. All rights reserved.
//

import Alamofire
import UIKit
import WebKit

// https://docs.github.com/en/developers/apps/building-oauth-apps/authorizing-oauth-apps

/// 授权方式
public enum ZLGithubOAuthType: Int {
    case code             // 授权码方式
    case device           // 设备授权方式 beta
}

/// 授权状态
public enum ZLGithubOAuthStatus: Int {
    case initialized
    case authorize
    case getToken
    case success
    case fail
}

public enum ZLGithubOAuthError: Error {
    case authorizeError(desc: String)
    
    public var localizedDescription: String {
        switch self {
        case .authorizeError(let desc):
            return desc
        }
    }
}

public protocol ZLGithubOAuthManagerDelegate: NSObjectProtocol {
    
    func onOAuthStatusChanged(status: ZLGithubOAuthStatus)
    
    func onOAuthSuccess(token: String)
    
    func onOAuthFail(status: ZLGithubOAuthStatus, error: String)
}


public class ZLGithubOAuthManager: NSObject {
    
    // most import config
    private let client_id: String
    private let client_secret: String
    private let redirect_uri: String
    
    private var scopes: [ZLGithubScope] = []
    private var allow_signup = false
    
    // status
    private var oauthStatus: ZLGithubOAuthStatus = .initialized
    
    // delegate
    private weak var delegate: ZLGithubOAuthManagerDelegate?
    
    // VC
    private var vc: ZLGithubOAuthController?
    
    // serialNumer 跟踪一次OAuth流程
    private var serialNumber: String?
    
    // Alamofire Session
    private lazy var session: Session = {
        var session = Session(startRequestsImmediately:false)
        return session
    }()
    
    public init(client_id: String,
                client_secret: String,
                redirect_uri: String) {
        
        self.client_id = client_id
        self.client_secret = client_secret
        self.redirect_uri = redirect_uri
        
        super.init()
    }
    
    
    /// 开始授权
    public func startOAuth(type: ZLGithubOAuthType,
                           delegate: ZLGithubOAuthManagerDelegate,
                           vcBlock: (UIViewController) -> Void,
                           scopes: [ZLGithubScope] = [],
                           allow_signup: Bool = false,
                           force: Bool = false ) {
        
        if !force &&
            oauthStatus != .initialized {
            delegate.onOAuthFail(status: .initialized, error: "another oauth progress is running")
            return
        }
        
        reset()
        self.delegate = delegate
        self.scopes = scopes
        self.allow_signup = allow_signup
        self.serialNumber = ZLGithubOAuthManager.generateOAuthSerialNumber()
        
        self.onStatusChange(status: .initialized)
    
        switch type {
        case .code:
            startCodeOAuth(delegate: delegate,
                           vcBlock: vcBlock,
                           scopes: scopes,
                           allow_signup: allow_signup)
        case .device:
            startDeviceOAuth(delegate: delegate,
                             vcBlock: vcBlock,
                             scopes: scopes)
        }
        
    }
    
    
    public static func clearCookies() {
        
        // 删除 WKWebView Cookies
        let set = Set([WKWebsiteDataTypeCookies,WKWebsiteDataTypeSessionStorage])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: set, modifiedSince:date) {
            
        }
        
        // 删除 HTTPCookieStorage Cookies
        if let url = URL(string: githubMainURL),
           let cookies = HTTPCookieStorage.shared.cookies(for: url) {
            cookies.forEach { cookie in
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
    }
    
    /// 授权码授权
    private func startCodeOAuth(delegate: ZLGithubOAuthManagerDelegate,
                               vcBlock: (UIViewController) -> Void,
                               scopes: [ZLGithubScope] = [],
                               allow_signup: Bool = false,
                               force: Bool = false ) {
        
        let vc = ZLGithubOAuthController(delegate: self, serialNumber: serialNumber ?? "")
        vc.modalPresentationStyle = .fullScreen
        self.vc = vc
        
        self.onStatusChange(status: .authorize)
        vcBlock(vc)
    }
    
    
    /// 设备授权
    private func startDeviceOAuth(delegate: ZLGithubOAuthManagerDelegate,
                                  vcBlock: (UIViewController) -> Void,
                                  scopes: [ZLGithubScope] = []) {
        
        // to-do 
    }

}

extension ZLGithubOAuthManager {
   
    /// 生成流水号
    private static func generateOAuthSerialNumber() -> String {
        // 时间戳 + 3位随机数
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
        let dateStr = dateFormatter.string(from: Date())
        return "\(dateStr)\(arc4random()%10)\(arc4random()%10)\(arc4random()%10)"
    }
    
    /// 修改状态
    private func onStatusChange(status: ZLGithubOAuthStatus) {
        self.oauthStatus = status
        self.delegate?.onOAuthStatusChanged(status: status)
    }
    
    /// 重置状态
    private func reset() {
        vc?.close()
        oauthStatus = .initialized
        delegate = nil
        vc = nil
        scopes = []
        allow_signup = false
    }
    
    ///
    private func onOAuthSuccess(token: String) {
        self.delegate?.onOAuthSuccess(token: token)
        self.onStatusChange(status: .success)
        self.reset()
    }
    
    private func onOAuthFail(status: ZLGithubOAuthStatus, error: String) {
        self.delegate?.onOAuthFail(status: status, error: error)
        self.onStatusChange(status: .fail)
        self.reset()
    }
    
    private func getAccessToken(code: String) {
        
        vc = nil
        onStatusChange(status: .getToken)
     
        let params = ["client_id":client_id,
                      "client_secret":client_secret,
                      "code":code,
                      "redirect_uri":redirect_uri]
        
        let httpHeaders = HTTPHeaders(["Accept":"application/json"])
        let request = session.request(ZLGithubOAuthManager.accessTokenURL,
                                      method: .post,
                                      parameters: params,
                                      headers:httpHeaders)
        
        request.responseJSON { [weak self] response in
            
            guard let self = self else { return }
            
            switch(response.result) {
            case .success(let result):
                if let resDic = result as? [String : String],
                   let token  = resDic["access_token"] {
                    self.onOAuthSuccess(token: token)
                } else {
                    self.onOAuthFail(status: .getToken, error: "decode token error")
                }
            case .failure(let error):
                self.onOAuthFail(status: .getToken, error: error.localizedDescription)
            }
            
            self.reset()
        }
        
        request.resume()
    }
}

extension ZLGithubOAuthManager: ZLGithubOAuthControllerDelegate {

    func getOAuthType(serialNumber: String) -> ZLGithubOAuthType? {
        guard serialNumber == self.serialNumber,
              oauthStatus == .authorize else { return nil}
        return .code
    }
    
    func getAuthorizeCodeURL(serialNumber: String) -> URL? {
        guard serialNumber == self.serialNumber,
              oauthStatus == .authorize else { return nil}
        
        var urlComponents = URLComponents(string: ZLGithubOAuthManager.authrizeCodeURL)
        let params = ["client_id":client_id,
                      "redirect_uri":redirect_uri,
                      "scope":ZLGithubScope.generateGithubScopeStr(scope: scopes),
                      "state":serialNumber,
                      "allow_signup":allow_signup ? "true" : "false"]
        let tmpEncoder = URLEncodedFormEncoder()
        do {
            let queryStr: String = try tmpEncoder.encode(params)
            urlComponents?.percentEncodedQuery = queryStr
            if let url = urlComponents?.url {
                return url
            } else {
                self.onOAuthFail(status: oauthStatus, error: "parameters encode fail")
                return nil
            }
        } catch {
            self.onOAuthFail(status: oauthStatus, error: error.localizedDescription)
            return nil
        }
    }
    
    func getAuthorizeCodeRedirectURL(serialNumber: String) -> String? {
        guard serialNumber == self.serialNumber,
              oauthStatus == .authorize else { return nil}
        return redirect_uri
    }
    
    func onAuthorizeCodeSuccess(code: String, serialNumber: String) {
        guard serialNumber == self.serialNumber,
              oauthStatus == .authorize else { return }
        self.getAccessToken(code: code)
    }
    
    func onAuthorizeCodeFail(error: Error,serialNumber: String) {
        guard serialNumber == self.serialNumber,
              oauthStatus == .authorize else { return }
        self.onOAuthFail(status: oauthStatus, error: error.localizedDescription)
    }
    
    func onOAuthClose(serialNumber: String){
        guard serialNumber == self.serialNumber,
              oauthStatus == .authorize else { return }
        self.onOAuthFail(status: oauthStatus, error: "cancel")
    }
}


extension ZLGithubOAuthManager {
    /// 授权码授权URL
    static let authrizeCodeURL = "https://github.com/login/oauth/authorize"
    
    ///
    static let accessTokenURL = "https://github.com/login/oauth/access_token"
    
    /// 设备授权URL
    static let deviceCodeURL = "https://github.com/login/device/code"
    
    ///
    static let githubMainURL = "https://github.com"
}
