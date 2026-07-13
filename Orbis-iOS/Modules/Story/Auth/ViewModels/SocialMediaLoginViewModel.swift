//
//  SocialMediaLoginViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 25/04/2021.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import JWTDecode

class SocialMediaLoginViewModel {
    let manager = OrbisSocialMediaLoginManager()
    
    // Unhashed nonce.
    var currentNonce: String?
    
    func tryLoginWithTwitter(completion: @escaping responseBlock) {
        manager.tryLoginWithTwitter {
            (data, err) in
            if let error = err {
                completion(nil, error)
            }
            else {
                guard let result = data as? AuthDataResult else {
                    completion(nil, CommonError.invalidUser)
                    return
                }
                var twitterUser = TwitterUser()
                if let userInfo = result.additionalUserInfo?.profile {
                    twitterUser = TwitterUser(fromDict: userInfo)
                }
                result.user.getIDTokenForcingRefresh(true) { [weak self] (token, err) in
                    guard let userToken = token else {
                        completion(nil, CommonError.invalidUser)
                        return
                    }
                    self?.manager.tryGetUserProfile(withToken: userToken, refreshToken: result.user.refreshToken!) {
                        [weak self] (data, err) in
                        if let error = err {
                            completion(nil, error)
                        }
                        else {
                            guard let user = UserSessionManager.shared.currentUser else {
                                completion(nil, CommonError.invalidUser)
                                return
                            }
                            var shouldPost = (user.name == nil)
                            if let name = user.name, name.isEmpty {
                                shouldPost = true
                            }
                            let twitterFullName = twitterUser.fullName ?? twitterUser.calculatedFullName
                            if shouldPost && !twitterFullName.isEmpty {
                                var param: [String: Any?] = [
                                    SignupParamKeys.displayName: twitterUser.fullName ?? twitterUser.calculatedFullName,
                                    SignupParamKeys.gender: twitterUser.gender,
                                    SignupParamKeys.dob: twitterUser.dateOfBirth,
                                    SignupParamKeys.providerImageUrl: twitterUser.profilePictureUrl
                                ]
                                if let partnerKey = UserSessionManager.shared.branchPartnerKey, !partnerKey.isEmpty {
                                    param[SignupParamKeys.partnerKey] = partnerKey
                                }
                                self?.manager.tryPostUserProfile(withToken: userToken, refreshToken: result.user.refreshToken!, parameters: param, completion: completion)
                            }
                            else {
                                completion(true, nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func tryLoginWithGoogle(from vc: UIViewController) {
        manager.loginWithGoogle(from: vc)
    }
    
    func tryLoginWithFacebook(fromView viewController: UIViewController, completion: @escaping responseBlock) {
        manager.loginThroughFacebook(fromView: viewController) { (data, err) in
            if let error = err {
                completion(nil, error)
            }
            else {
                guard let result = data as? AuthDataResult else {
                    completion(nil, CommonError.invalidUser)
                    return
                }
                result.user.getIDTokenForcingRefresh(true) { [weak self] (token, err) in
                    guard let userToken = token else {
                        completion(nil, CommonError.invalidUser)
                        return
                    }
                    if FacebookUser.shared.isNewUser {
                        var param: [String: Any?] = [
                            SignupParamKeys.displayName: FacebookUser.shared.fullName ?? FacebookUser.shared.calculatedFullName,
                            SignupParamKeys.gender: FacebookUser.shared.gender,
                            SignupParamKeys.dob: FacebookUser.shared.dateOfBirth,
                            SignupParamKeys.providerImageUrl: FacebookUser.shared.profilePictureUrl
                        ]
                        if let partnerKey = UserSessionManager.shared.branchPartnerKey, !partnerKey.isEmpty {
                            param[SignupParamKeys.partnerKey] = partnerKey
                        }
                        self?.manager.tryPostUserProfile(withToken: userToken, refreshToken: result.user.refreshToken!, parameters: param, completion: completion)
                    }
                    else {
                        self?.manager.tryGetUserProfile(withToken: userToken, refreshToken: result.user.refreshToken!, completion: completion)
                    }
                }
            }
        }
    }
    
    func tryLoginWithGoogle(withUser user: GoogleUser, completion: @escaping responseBlock) {
        manager.tryLoginIntoAppUsingGoogleToken(user: user) { (data, err) in
            if let error = err {
                completion(nil, error)
            }
            else {
                guard let result = data as? AuthDataResult else {
                    completion(nil, CommonError.invalidUser)
                    return
                }
                result.user.getIDTokenForcingRefresh(true) { [weak self] (token, err) in
                    guard let userToken = token else {
                        completion(nil, CommonError.invalidUser)
                        return
                    }
                    if GoogleUser.shared.isNewUser {
                        var param: [String: Any?] = [
                            SignupParamKeys.displayName: GoogleUser.shared.fullName ?? GoogleUser.shared.calculatedFullName,
                            SignupParamKeys.gender: GoogleUser.shared.gender,
                            SignupParamKeys.dob: GoogleUser.shared.dateOfBirth,
                            SignupParamKeys.providerImageUrl: GoogleUser.shared.profilePictureUrl
                        ]
                        if let partnerKey = UserSessionManager.shared.branchPartnerKey, !partnerKey.isEmpty {
                            param[SignupParamKeys.partnerKey] = partnerKey
                        }
                        self?.manager.tryPostUserProfile(withToken: userToken, refreshToken: result.user.refreshToken!, parameters: param, completion: completion)
                    }
                    else {
                        self?.manager.tryGetUserProfile(withToken: userToken, refreshToken: result.user.refreshToken!, completion: completion)
                    }
                    
                }
            }
        }
    }
    
    func getAppleSigninRequest() -> ASAuthorizationAppleIDRequest {
        let nonce = manager.randomNonceString()
        self.currentNonce = nonce
        return manager.getAppleSigninRequest(nonce: nonce)
    }
    
    func tryLoginWithApple(idTokenString: String, appleIdCredential: ASAuthorizationAppleIDCredential, completion: @escaping responseBlock) {
        guard let nonce = currentNonce else {
            completion(nil, ResponseError.requestFailed)
            return
        }
        guard let jwt = try? decode(jwt: idTokenString) else {
            completion(nil, ResponseError.requestFailed)
            return
        }
        var userEmail = jwt.claim(name: "email").string ?? ""
        if let email = appleIdCredential.email, !email.isEmpty {
            userEmail = email
        }
        guard !userEmail.isEmpty else {
            debugPrint("Could not get email from user")
            completion(nil, ValidationErrors.appleSignInEmptyEmail)
            return
        }
        manager.tryLoginWithApple(idTokenString: idTokenString, email: userEmail, nonce: nonce) { [weak self] data, err in
            if let error = err {
                completion(nil, error)
            }
            else {
                guard let result = data as? AuthDataResult else {
                    completion(nil, CommonError.invalidUser)
                    return
                }
                result.user.getIDTokenForcingRefresh(true) { [weak self] (token, err) in
                    guard let userToken = token else {
                        completion(nil, CommonError.invalidUser)
                        return
                    }
                    self?.manager.tryGetUserProfile(withToken: userToken, refreshToken: result.user.refreshToken!) {
                        [weak self] (data, err) in
                        if let error = err {
                            completion(nil, error)
                        }
                        else {
                            guard let user = UserSessionManager.shared.currentUser else {
                                completion(nil, CommonError.invalidUser)
                                return
                            }
                            var shouldPost = (user.name == nil)
                            if let name = user.name, name.isEmpty {
                                shouldPost = true
                            }
                            var appleUserName: String = (appleIdCredential.fullName?.givenName ?? "") + " " + (appleIdCredential.fullName?.familyName ?? "")
                            let nameToValidate = appleUserName.replacingOccurrences(of: " ", with: "")
                            if nameToValidate.isEmpty {
                                appleUserName = "Orbis User"
                            }
                            if shouldPost && !appleUserName.isEmpty {
                                var param: [String: Any?] = [
                                    SignupParamKeys.displayName: appleUserName
                                ]
                                if let partnerKey = UserSessionManager.shared.branchPartnerKey, !partnerKey.isEmpty {
                                    param[SignupParamKeys.partnerKey] = partnerKey
                                }
                                self?.manager.tryPostUserProfile(withToken: userToken, refreshToken: result.user.refreshToken!, parameters: param, completion: completion)
                            }
                            else {
                                completion(true, nil)
                            }
                        }
                    }
                    
                }
            }
        }
    }
}
