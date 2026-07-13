//
//  LoginManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 23/04/2021.
//

import Foundation
import JWTDecode
import FirebaseMessaging

class OrbisLoginManager {
    
    func loginUser(withUser user: LoginUser, completion: @escaping responseBlock) {
        let url = GetApiAddress.auth(.login).url
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: user.parameters, method: .post, headers: [:], isContentJSON: true, completion: { (data, err) in
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
