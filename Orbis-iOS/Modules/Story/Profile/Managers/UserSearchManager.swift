//
//  UserSearchManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 23/07/2021.
//

import Foundation

class UserSearchManager {
    let profileSearchSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    
    // MARK:- Search Profile
    
    func invalidateSearchProfileSession(completion: @escaping responseBlock) {
        profileSearchSessionManager.invalidateAllSessionRequests(completion: completion)
    }
    
    func searchProfile(searchText: String, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.search, []).url
        let parameters: [String: Any] = [
            UserProfileDomainParameterKeys.Search.name: searchText,
            UserProfileDomainParameterKeys.Search.page: page,
            UserProfileDomainParameterKeys.Search.limit: limit
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
        profileSearchSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
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
                    let tuple: UserSearchResult = (users: users.validList, searchText: searchText)
                    completion(tuple, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func fetchUserFollowers(userKey: String, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.followers, [userKey]).url
        let parameters: [String: Any] = [
            UserProfileDomainParameterKeys.Search.page: page,
            UserProfileDomainParameterKeys.Search.limit: limit
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
        profileSearchSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
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
                    completion(users.validList, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func fetchUserFollowings(userKey: String, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.followings, [userKey]).url
        let parameters: [String: Any] = [
            UserProfileDomainParameterKeys.Search.type: UserFollowingListType.user.rawValue.uppercased(),
            UserProfileDomainParameterKeys.Search.page: page,
            UserProfileDomainParameterKeys.Search.limit: limit
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
        profileSearchSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
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
                    let items = try decoder.decode(UserFollowingItems.self, from: respData)
                    let users: OrbisUsers = items.filter({$0.listType == .user}).filter({$0.user != nil}).map({$0.user!})
                    completion(users.validList, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func fetchUserBlockList(page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.blockedUsers, []).url
        let parameters: [String: Any] = [
            UserProfileDomainParameterKeys.Search.page: page,
            UserProfileDomainParameterKeys.Search.limit: limit
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
        profileSearchSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
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
                    completion(users, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
}
