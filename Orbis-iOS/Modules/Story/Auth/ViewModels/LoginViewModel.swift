//
//  LoginViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 23/04/2021.
//

import Foundation

class LoginViewModel {
    var model: LoginUser!
    let manager = OrbisLoginManager()
    
    init() {
        UserSessionManager.shared.logoutFirebase() {
            _,_ in
        }
        model = LoginUser()
    }
    
    var email: String {
        get {
            return model.email ?? ""
        }
        set {
            model.email = newValue.trimmingCharacters(in: .whitespaces)
        }
    }
    
    var password: String {
        get {
            return model.password ?? ""
        }
        set {
            model.password = newValue
        }
    }
    
    func tryLogin(completion: @escaping responseBlock) {
        validateFields { [weak self] (data, err) in
            if let error = err {
                completion(nil, error)
            }
            else {
                guard let strongSelf = self else {return}
                strongSelf.manager.loginUser(withUser: strongSelf.model) { (data, err) in
                    if let error = err {
                        completion(nil, error)
                    }
                    else {
                        if let _ = data as? Bool {
                            completion(true, nil)
                        }
                        else {
                            completion(nil, ResponseError.invalidData)
                        }
                    }
                }
            }
        }
    }
    
    private func validateFields(completion: @escaping responseBlock) {
        if !email.isValidField {
            completion(nil, ValidationErrors.emptyEmail)
            return
        }
        if !password.isValidField {
            completion(nil, ValidationErrors.emptyPassword)
            return
        }
        completion(true, nil)
    }
}
