//
//  ViewController.swift
//  ZLGithubOAuth
//
//  Created by zhumeng on 01/02/2022.
//  Copyright (c) 2022 zhumeng. All rights reserved.
//

import UIKit
import ZLGithubAPISwift
import SnapKit
import Toast_Swift
import ZLGithubOAuth

class ViewController: UIViewController, ZLGithubOAuthManagerDelegate {
    
    func onOAuthStatusChanged(status: ZLGithubOAuthStatus) {
        switch status{
        case .initialized:
            self.loginStatusLabel.text = "login: initialized"
        case .authorize:
            self.loginStatusLabel.text = "login: authorize"
        case .getToken:
            self.loginStatusLabel.text = "login: getToken"
        case .success:
            self.loginStatusLabel.text = "login: success"
        case .fail:
            self.loginStatusLabel.text = "login: fail"
        }
    }
    
    func onOAuthSuccess(token: String) {
        UserDefaults.standard.set(token, forKey: "token")
        view.makeToast("login success")
        reset()
    }
    
    func onOAuthFail(status: ZLGithubOAuthStatus, error: String) {
        view.makeToast(error)
        reset()
    }
    
    
    ///  data
    var requestResult: String = ""
    
    /// View
    lazy var loginButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .blue
        button.setTitleColor(.white, for: .normal)
        button.setTitle("login", for: .normal)
        button.setTitle("logout", for: .selected)
        return button
    }()
    
    lazy var requestButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .blue
        button.setTitleColor(.white, for: .normal)
        button.setTitle("request", for: .normal)
        return button
    }()
    
    lazy var resetButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .blue
        button.setTitleColor(.white, for: .normal)
        button.setTitle("resetButton", for: .normal)
        return button
    }()
    
    lazy var clearButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .blue
        button.setTitleColor(.white, for: .normal)
        button.setTitle("clearCookies", for: .normal)
        return button
    }()
    
    lazy var loginStatusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        label.textColor = .black
        label.backgroundColor = .gray
        return label
    }()
    
    lazy var requestResultLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        label.textColor = .black
        label.backgroundColor = .gray
        return label
    }()
    
    lazy var oauthManager: ZLGithubOAuthManager = {
       ZLGithubOAuthManager(client_id: "38f62c4abb3b3bf3f216",
                            client_secret: "8a914b07d2905adc6d9f7dea993d5e7fb2133491",
                            redirect_uri: "https://www.existorlive.cn/callback")
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        reloadUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func setupUI() {
        
        view.addSubview(loginStatusLabel)
        view.addSubview(requestResultLabel)
        view.addSubview(requestButton)
        view.addSubview(loginButton)
        view.addSubview(resetButton)
        view.addSubview(clearButton)
        
        loginStatusLabel.snp.makeConstraints { make in
            make.top.equalTo(30)
            make.right.equalTo(-20)
            make.left.equalTo(20)
            make.height.equalTo(50)
        }
        
        requestResultLabel.snp.makeConstraints { make in
            make.top.equalTo(loginStatusLabel.snp.bottom).offset(20)
            make.right.equalTo(-20)
            make.left.equalTo(20)
            make.height.equalTo(50)
        }
        
        requestButton.snp.makeConstraints { make in
            make.top.equalTo(requestResultLabel.snp.bottom).offset(20)
            make.right.equalTo(-20)
            make.left.equalTo(20)
            make.height.equalTo(50)
        }
        requestButton.addTarget(self, action: #selector(sendRequest), for: .touchUpInside)
        
        loginButton.snp.makeConstraints { make in
            make.top.equalTo(requestButton.snp.bottom).offset(20)
            make.right.equalTo(-20)
            make.left.equalTo(20)
            make.height.equalTo(50)
        }
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
        
        resetButton.snp.makeConstraints { make in
            make.top.equalTo(loginButton.snp.bottom).offset(20)
            make.right.equalTo(-20)
            make.left.equalTo(20)
            make.height.equalTo(50)
        }
        resetButton.addTarget(self, action: #selector(reset), for: .touchUpInside)
        
        clearButton.snp.makeConstraints { make in
            make.top.equalTo(resetButton.snp.bottom).offset(20)
            make.right.equalTo(-20)
            make.left.equalTo(20)
            make.height.equalTo(50)
        }
        clearButton.addTarget(self, action: #selector(clear), for: .touchUpInside)
        
        
    }
    
    @objc func sendRequest() {
        
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            view.makeToast("No Login")
            return
        }
        
        view.makeToastActivity(.center)
        
        ZLGithubHttpClient.shared.setToken(token: token)
        
        ZLGithubHttpClient.shared.provider.request(ZLGithubRepoRequest(login: "existorlive", name: "SecretFile"), callbackQueue: nil) { [weak self] result in
            guard let self = self else { return }
            self.view.hideToastActivity()
            switch result {
            case .success(let data):
                self.requestResult = "success"
                print(data)
            case .failure(let error):
                self.requestResult = "fail"
                print(error)
            }
            self.reloadUI()
        }
    }
    
    
    @objc func login() {
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            
            oauthManager.startOAuth(type:.code,
                                    delegate: self,
                                    vcBlock: { vc in
                self.present(vc, animated: true, completion: nil)
                
            }, scopes: [.user,.repo,.gist,.admin_org], allow_signup: false, force: false)
            
            return
        }
        
        UserDefaults.standard.set(nil, forKey: "token")
        view.makeToast("logout success")
        reset()
    }
    
    @objc func reset() {
        requestResult = ""
        reloadUI()
    }
    
    @objc func clear() {
        ZLGithubOAuthManager.clearCookies()
    }
    
    @objc func isLogin() -> Bool {
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            return false
        }
        return true
    }

    func reloadUI() {
        loginStatusLabel.text = isLogin() ? "Logined" : "No Login"
        loginButton.isSelected = isLogin()
        requestResultLabel.text = requestResult
    }
}

