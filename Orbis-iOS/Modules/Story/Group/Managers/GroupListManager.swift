//
//  GroupListManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/07/2021.
//

import Foundation
import UIKit
import CoreLocation

class GroupListManager {
    
    let groupFetchSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    
    func invalidateAllNetworkRequests(completion: @escaping responseBlock) {
        self.groupFetchSessionManager.invalidateAllSessionRequests(completion: completion)
    }
    
    func fetchGroupMembers(groupKey: String, searchText: String, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.members, [groupKey]).url
        let parameters: [String: Any] = [
            GroupNetworkParameterKeys.Fetch.name: searchText,
            GroupNetworkParameterKeys.Fetch.page: page,
            GroupNetworkParameterKeys.Fetch.size: limit
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
        groupFetchSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
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
                    let users = try decoder.decode(OrbisUsers.self, from: respData)
                    let tuple = UserSearchResult(users: users.validList, searchText: searchText)
                    completion(tuple, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
}
