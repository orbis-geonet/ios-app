//
//  SignupManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 23/04/2021.
//

import Foundation
import FirebaseAuth
import JWTDecode
import FirebaseMessaging

class OrbisSignupManager {
    
    func createUser(withUser user: SignupUser, completion: @escaping responseBlock) {
        let url = GetApiAddress.auth(.signup).url
        let parameter = user.parameters
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: parameter, method: .post, headers: [:], isContentJSON: true, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
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
                        let jwt = try decode(jwt: user.idToken!)
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
        })
    }
    
}
