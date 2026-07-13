//
//  SignupUser.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 23/04/2021.
//

import Foundation

class SignupUser {
    var email: String?
    var password: String?
    var fullName: String?
    
    var parameters: [String: String] {
        var params = [
            SignupParamKeys.email: email ?? "",
            SignupParamKeys.password: password ?? "",
            SignupParamKeys.displayName: fullName ?? ""
        ]
        if let partnerKey = UserSessionManager.shared.branchPartnerKey, !partnerKey.isEmpty {
            params[SignupParamKeys.partnerKey] = partnerKey
        }
        return params
    }
}
