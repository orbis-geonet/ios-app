//
//  UserGroupListManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 25/07/2021.
//

import Foundation
import UIKit
import CoreLocation

class UserGroupListManager {
    
    let groupFetchSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    
    func invalidateAllNetworkRequests(completion: @escaping responseBlock) {
        self.groupFetchSessionManager.invalidateAllSessionRequests(completion: completion)
    }
    
    func fetchUserMemberGroups(userKey: String, searchText: String, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.memberOfGroups, [userKey]).url
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
                    let groups = try decoder.decode(Groups.self, from: respData)
                    let tuple: GroupSearchResult = (groups: groups, searchText: searchText)
                    completion(tuple, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    
    func fetchUserAdminGroups(userKey: String, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.adminOfGroups, [userKey]).url
        let parameters: [String: Any] = [
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
                    let groups = try decoder.decode(Groups.self, from: respData)
                    completion(groups, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
}
