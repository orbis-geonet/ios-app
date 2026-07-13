//
//  OrbisSocialMediaLoginManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 25/04/2021.
//

import Foundation
import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JWTDecode
import FirebaseMessaging
import AuthenticationServices
import CryptoKit

class OrbisSocialMediaLoginManager {
    let twitterAuthProvider = OAuthProvider(providerID: "twitter.com")
    let gidConfig = GIDConfiguration.init(clientID: APPKeys.googleSigninClientId)
    
    init() {
        GIDSignIn.sharedInstance.configuration = gidConfig
    }
    
    func tryGetUserProfile(withToken token: String, refreshToken: String, completion: @escaping responseBlock) {
        let header = [
            "Authorization": "Bearer \(token)"
        ]
        let url = GetApiAddress.profile(.me, []).url
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .get, headers: header) { (data, err) in
            if let error = err {
                completion(nil, error)
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, ResponseError.invalidData)
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let user = try decoder.decode(OrbisUser.self, from: respData)
                    do {
                        let jwt = try decode(jwt: token)
                        user.idToken = token
                        user.refreshToken = refreshToken
                        user.tokenExpiryTimestamp = jwt.expiresAt
                    }
                    catch {
                        completion(nil, error)
                        return
                    }
                    UserSessionManager.shared.saveUsertoDefaults(user: user) { data, err in
                        if let error = err {
                            completion(nil, error)
                        }
                        else {
                            let fcmToken = Messaging.messaging().fcmToken
                            UserSessionManager.shared.updateFirebaseToken(fcmToken: fcmToken!, shouldAddToken: true, completion: completion)
                        }
                    }
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func tryPostUserProfile(withToken token: String, refreshToken: String, parameters: [String: Any?], completion: @escaping responseBlock) {
        let header = [
            "Authorization": "Bearer \(token)"
        ]
        let params = parameters.filter { (data) -> Bool in
            data.value != nil
        }
        let url = GetApiAddress.profile(.me, []).url
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: params as [String : Any], method: .post, headers: header, isContentJSON: true) { (data, err) in
            if let error = err {
                completion(nil, error)
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, ResponseError.invalidData)
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let user = try decoder.decode(OrbisUser.self, from: respData)
                    UserSessionManager.shared.removeBranchPartnerKey()
                    do {
                        let jwt = try decode(jwt: token)
                        user.idToken = token
                        user.refreshToken = refreshToken
                        user.tokenExpiryTimestamp = jwt.expiresAt
                    }
                    catch {
                        completion(nil, error)
                        return
                    }
                    UserSessionManager.shared.saveUsertoDefaults(user: user, completion: completion)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    private func loginWithCredential(credential: AuthCredential, completion: @escaping responseBlock) {
        Auth.auth().signIn(with: credential) { result, error in
            if error != nil {
                // An account with the same email already exists.
                if (error as NSError?)?.code == AuthErrorCode.accountExistsWithDifferentCredential.rawValue {
                    // Get pending credential and email of existing account.
                    let existingAcctEmail = (error! as NSError).userInfo[AuthErrorUserInfoEmailKey] as! String
                    Auth.auth().fetchSignInMethods(forEmail: existingAcctEmail) { (providers, error) in
                        let error = GenericWarningError(title: "Authentication Error", description: "User already signed up using \(providers!.first!.toFirebaseAuthProviderName)", code: 302)
                        completion(nil, error)
                    }
                    return
                }
                completion(nil, error)
                return
            }
            completion(result, nil)
            // User is signed in.
            // IdP data available in authResult.additionalUserInfo.profile.
            // Twitter OAuth access token can also be retrieved by:
            // authResult.credential.accessToken
            // Twitter OAuth ID token can be retrieved by calling:
            // authResult.credential.idToken
            // Twitter OAuth secret can be retrieved by calling:
            // authResult.credential.secret
        }
    }
    
    func tryLoginWithTwitter(completion: @escaping responseBlock) {
        twitterAuthProvider.getCredentialWith(nil) { [weak self] credential, error in
            if error != nil {
                // An account with the same email already exists.
                if (error as NSError?)?.code == AuthErrorCode.accountExistsWithDifferentCredential.rawValue {
                    // Get pending credential and email of existing account.
                    let existingAcctEmail = (error! as NSError).userInfo[AuthErrorUserInfoEmailKey] as! String
                    //                    let pendingCred = (error! as NSError).userInfo[AuthErrorUserInfoUpdatedCredentialKey] as! AuthCredential
                    // Lookup existing account identifier by the email.
                    Auth.auth().fetchSignInMethods(forEmail: existingAcctEmail) { (providers, error) in
                        UIUtil.showGlobalToast(message: "User already signed up using \(providers!.first!.toFirebaseAuthProviderName)")
                        //                        // Existing email/password account.
                        //                        if (providers?.contains(EmailAuthProviderID))! {
                        //
                        //                        }
                        completion(true, nil)
                    }
                    return
                }
                else {
                    completion(nil, error!)
                    return
                }
            }
            // Sign in with the credential.
            if credential != nil {
                self?.loginWithCredential(credential: credential!, completion: completion)
            }
        }
    }
    
    func logoutFacebookUser() {
        FacebookUser.shared = FacebookUser()
        LoginManager().logOut()
    }
    
    func loginThroughFacebook(fromView viewController: UIViewController, completion: @escaping responseBlock) {
        self.logoutFacebookUser()
        LoginManager().logIn(permissions: ["email", "public_profile"], from: viewController) {
            (result, error) in
            if let error = error {
                print("Facebook authentication error: \(error.localizedDescription)")
                completion(nil, error)
            }
            else {
                if (result?.isCancelled)! {
                    print("Facebook authentication canceled")
                    completion(nil, nil)
                }
                else {
                    if result?.token == nil {
                        print("Access not granted")
                        completion(nil, nil)
                    }
                    else {
                        print("Login Successful with result: \(result.debugDescription)")
                        self.getDetailsOfUser(){
                            (data) in
                            if data == nil {
                                print("Empty data extracted")
                                completion(nil, nil)
                            }
                            else{
                                self.saveFacebookUserToObject(withData: data!)
                                self.tryLoginIntoAppUsingFacebookCredentials(completion: {
                                    (user, error) in
                                    completion(user, error)
                                })
                            }
                        }
                    }
                }
                
            }
        }
    }
    
    func saveFacebookUserToObject(withData data: [String: AnyObject]) {
        FacebookUser.shared.fbId = data["id"] as? String
        FacebookUser.shared.fullName = data["name"] as? String
        FacebookUser.shared.email = data["email"] as? String
        FacebookUser.shared.fname = data["first_name"] as? String
        FacebookUser.shared.lname = data["last_name"] as? String
        FacebookUser.shared.gender = data["gender"] as? String
        FacebookUser.shared.dateOfBirth = data["birthday"] as? String
        FacebookUser.shared.userWebsite = data["website"] as? String
        FacebookUser.shared.userBio = data["about"] as? String
        if let locationInfo = data["location"] as? [String: AnyObject] {
            FacebookUser.shared.userCurrentLocation = locationInfo["name"] as? String
        }
        if let hometownInfo = data["hometown"] as? [String: AnyObject] {
            FacebookUser.shared.userHometowm = hometownInfo["name"] as? String
        }
        if let coverPhotoInfo = data["cover"] as? [String: AnyObject] {
            FacebookUser.shared.coverPhotoUrl = coverPhotoInfo["source"] as? String
        }
        if let profilePictureInfo = data["picture"] as? [String: AnyObject] {
            if let profilePictureData = profilePictureInfo["data"] as? [String: AnyObject] {
                FacebookUser.shared.profilePictureUrl = profilePictureData["url"] as? String
            }
        }
    }
    
    func getDetailsOfUser(completion:@escaping (([String: AnyObject]?)->Void)){
        
        GraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, email, gender, birthday, cover.type(large), website, picture.type(large), location, hometown, about"]).start {
            (conn, result, error) in
            if error != nil {
                print("Facebook user data extraction error: \(error.debugDescription)")
                completion(nil)
            }
            else {
                print("Facebook logged in user details: \(result.debugDescription)")
                let convertedResult: [String: AnyObject] = result as! [String: AnyObject]
                completion(convertedResult)
            }
        }
    }
    
    func tryLoginIntoAppUsingFacebookCredentials(completion: @escaping responseBlock) {
        let accessToken = AccessToken.current
        guard let accessTokenString = accessToken?.tokenString else {
            let socialMediaError = NSError(domain: "OrbisV2", code: 301, userInfo: [NSLocalizedDescriptionKey: "Invalid Facebook Access Token."])
            completion(nil, socialMediaError)
            return
        }
        let credential = FacebookAuthProvider.credential(withAccessToken: accessTokenString)
        Auth.auth().fetchSignInMethods(forEmail: FacebookUser.shared.email!) { [weak self] (providers, err) in
            if let error = err {
                completion(nil, error)
                return
            }
            if let providers = providers {
                if providers.count > 0 {
                    if !providers.contains(FacebookAuthProviderID) {
                        let error = GenericWarningError(title: "Authentication Error", description: "User already signed up using \(providers.first!.toFirebaseAuthProviderName)", code: 302)
                        completion(nil, error)
                    }
                    else {
                        FacebookUser.shared.isNewUser = false
                        self?.loginWithCredential(credential: credential, completion: completion)
                    }
                } else {
                    self?.loginWithCredential(credential: credential, completion: completion)
                }
            }
            else {
                self?.loginWithCredential(credential: credential, completion: completion)
            }
        }
        
    }
    
    // MARK:- Google Sign in
    
    func logoutGoogleUser() {
        GIDSignIn.sharedInstance.signOut()
        GoogleUser.shared = GoogleUser()
    }
    
    func loginWithGoogle(from vc: UIViewController) {
        self.logoutGoogleUser()
        GIDSignIn.sharedInstance.signIn(withPresenting: vc) { gidUser, err in
            if let error = err {
                print("\(error.localizedDescription)")
                NotificationCenter.default.post(
                    name: Notification.Name(rawValue: AppNotificationKeys.googleSignInResult),
                    object: error)
            } else if let user = gidUser?.user {
                let googleUser = GoogleUser()
                googleUser.googleId = user.userID
                googleUser.token = user.accessToken.tokenString
                googleUser.idToken = user.idToken?.tokenString
                googleUser.fullName = user.profile?.name
                googleUser.fname = user.profile?.givenName
                googleUser.lname = user.profile?.familyName
                googleUser.email = user.profile?.email
                googleUser.profilePictureUrl = user.profile?.imageURL(withDimension: 100)?.absoluteString
                GoogleUser.shared = googleUser
                NotificationCenter.default.post(
                    name: Notification.Name(rawValue: AppNotificationKeys.googleSignInResult),
                    object: googleUser)
            }
        }
    }
    
    func tryLoginIntoAppUsingGoogleToken(user: GoogleUser, completion: @escaping responseBlock) {
        guard let token = user.token, let idToken = user.idToken else {
            let socialMediaError = NSError(domain: "OrbisV2", code: 302, userInfo: [NSLocalizedDescriptionKey: "Invalid Google Access Token."])
            completion(nil, socialMediaError)
            return
        }
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: token)
        Auth.auth().fetchSignInMethods(forEmail: user.email!) { [weak self] (providers, err) in
            if let error = err {
                completion(nil, error)
                return
            }
            if let providers = providers {
                if providers.count > 0 {
                    if !providers.contains(GoogleAuthProviderID) {
                        let error = GenericWarningError(title: "Authentication Error", description: "User already signed up using \(providers.first!.toFirebaseAuthProviderName)", code: 302)
                        completion(nil, error)
                    }
                    else {
                        GoogleUser.shared.isNewUser = false
                        self?.loginWithCredential(credential: credential, completion: completion)
                    }
                } else {
                    self?.loginWithCredential(credential: credential, completion: completion)
                }
            }
            else {
                self?.loginWithCredential(credential: credential, completion: completion)
            }
        }
    }
    
    // MARK:- Apple Sign in
    
    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    func getAppleSigninRequest(nonce: String) -> ASAuthorizationAppleIDRequest {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        return request
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    
    func tryLoginWithApple(idTokenString: String, email: String, nonce: String, completion: @escaping responseBlock) {
        let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                  idToken: idTokenString,
                                                  rawNonce: nonce)
        Auth.auth().fetchSignInMethods(forEmail: email) { [weak self] (providers, err) in
            if let error = err {
                completion(nil, error)
                return
            }
            if let providers = providers {
                if providers.count > 0 {
                    if !providers.contains("apple.com") {
                        let error = GenericWarningError(title: "Authentication Error", description: "User already signed up using \(providers.first!.toFirebaseAuthProviderName)", code: 302)
                        completion(nil, error)
                    }
                    else {
                        self?.loginWithCredential(credential: credential, completion: completion)
                    }
                } else {
                    self?.loginWithCredential(credential: credential, completion: completion)
                }
            }
            else {
                self?.loginWithCredential(credential: credential, completion: completion)
            }
        }
    }
}
