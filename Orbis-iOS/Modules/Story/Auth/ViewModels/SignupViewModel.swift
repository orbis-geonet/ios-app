//
//  SignupViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 23/04/2021.
//

import Foundation

class SignupViewModel {
    var model: SignupUser!
    var manager = OrbisSignupManager()
    
    init() {
        model = SignupUser()
    }
    
    var fullName: String {
        get {
            return model.fullName ?? ""
        }
        set {
            model.fullName = newValue
        }
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
    
    func tryCreateUser(completion: @escaping responseBlock) {
        validateFields { [weak self] (data, err) in
            if let error = err {
                completion(nil, error)
                return
            }
            else {
                guard let strongSelf = self else {return}
                self?.manager.createUser(withUser: strongSelf.model, completion: completion)
                return
            }
        }
    }
    
    private func validateFields(completion: @escaping responseBlock) {
        if !fullName.isValidField {
            completion(nil, ValidationErrors.emptyFullName)
            return
        }
        if !email.isValidField {
            completion(nil, ValidationErrors.emptyEmail)
            return
        }
        if !password.isValidField {
            completion(nil, ValidationErrors.emptyPassword)
            return
        }
        if !email.isValidEmail {
            completion(nil, ValidationErrors.invalidEmail)
            return
        }
        if !password.isValidPassword {
            completion(nil, ValidationErrors.invalidPassword)
            return
        }
        completion(true, nil)
    }
}
