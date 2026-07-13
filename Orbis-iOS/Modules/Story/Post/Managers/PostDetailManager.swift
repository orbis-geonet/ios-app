//
//  PostDetailManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 11/08/2021.
//

import Foundation

class PostDetailManager {
    
    func fetchPostDetails(withKey key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.post(.details, [key]).url
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
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
                    let post = try decoder.decode(OrbisFeedPost.self, from: respData)
                    completion(post, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
}
