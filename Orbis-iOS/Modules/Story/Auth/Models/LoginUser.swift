//
//  LoginUser.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 23/04/2021.
//

import Foundation

class LoginUser {
    var email: String?
    var password: String?
    
    var parameters: [String: String] {
        return [
            SignupParamKeys.email: email!,
            SignupParamKeys.password: password!
        ]
    }
}
