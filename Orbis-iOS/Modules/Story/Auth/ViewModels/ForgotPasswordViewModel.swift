//
//  ForgotPasswordViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/04/2021.
//

import Foundation
import FirebaseAuth

class ForgotPasswordViewModel {
    
    func trySendEmailResetLink(forEmail email: String, completion: @escaping responseBlock) {
        Auth.auth().fetchSignInMethods(forEmail: email) { (providers, err) in
            if let error = err {
                completion(nil, error)
            }
            else {
                if let signinMethods = providers {
                    if signinMethods.contains(EmailAuthProviderID) {
                        Auth.auth().sendPasswordReset(withEmail: email) { (err2) in
                            if let error2 = err2 {
                                completion(nil, error2)
                            }
                            else {
                                completion(true, nil)
                            }
                        }
                    }
                    else {
                        completion(nil, ValidationErrors.socialMediaLoginUsed)
                    }
                }
                else {
                    completion(nil, ValidationErrors.emailNotFound)
                }
            }
        }
        
    }
}
