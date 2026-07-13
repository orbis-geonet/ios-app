//
//  GroupDetailManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 29/04/2021.
//

import Foundation

class GroupDetailManager {
    
    let groupFeedSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    let groupEventSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    let groupAdminsSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    let groupBannedUsersSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    
    func fetchGroupAdmins(forGroup key: String, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.admins, ["\(key)"]).url
        let parameters: [String: Any] = [
            GroupNetworkParameterKeys.Fetch.page: page,
            GroupNetworkParameterKeys.Fetch.size: limit
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .none, accept: .none)
        groupAdminsSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
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
    
    func fetchGroupBannedUsers(forGroup key: String, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.bannedUsers, ["\(key)"]).url
        let parameters: [String: Any] = [
            GroupNetworkParameterKeys.Fetch.page: page,
            GroupNetworkParameterKeys.Fetch.size: limit
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .none, accept: .none)
        groupBannedUsersSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
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
    
    func syncGroupDetail(forGroup key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.fetchDetails, [key]).url
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .get, headers: headers) { (data, err) in
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
                    let group = try decoder.decode(Group.self, from: respData)
                    completion(group, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    func fetchGroupMembers(
        forGroup key: String,
        page: Int,
        limit: Int,
        completion: @escaping responseBlock
    ) {
        let url = GetApiAddress.group(.members, ["\(key)"]).url

        let parameters: [String: Any] = [
            GroupNetworkParameterKeys.Fetch.page: page,
            GroupNetworkParameterKeys.Fetch.size: limit
        ]

        let isAuthenticated = UserSessionManager.shared.currentUser != nil

        let headers = NetworkRequestManager.shared.getHeader(
            authorized: isAuthenticated,
            contentType: .none,
            accept: .none
        )

        NetworkRequestManager.shared.processApiRequest(
            urlLink: url,
            parameters: parameters,
            method: .get,
            headers: headers,
            parameterDestination: .queryString
        ) { data, err in

            if let error = err {
                completion(nil, error)
                return
            }

            guard let respData = data as? Data else {
                completion(nil, ResponseError.invalidData)
                return
            }

            do {
                let users = try JSONDecoder().decode(OrbisUsers.self, from: respData)
                completion(users, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    func tryJoinGroup(groupKey key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.members, [key]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .put, headers: header) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        }
    }
    
    func tryLeaveGroup(groupKey key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.members, [key]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: header) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        }
    }
    
    func tryAssignNewAdmin(groupKey key: String, user: OrbisUser, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.addAdmin, [key, user.userKey!]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .put, headers: header) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        }
    }
    
    func tryRemoveAdmin(fromGroup key: String, user: OrbisUser, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.addAdmin, [key, user.userKey!]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: header) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        }
    }
    
    func tryBanUser(fromGroup key: String, user: OrbisUser, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.banUnbanUser, [key, user.userKey!]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .put, headers: header) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        }
    }
    
    func tryUnbanUser(fromGroup key: String, user: OrbisUser, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.banUnbanUser, [key, user.userKey!]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: header) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        }
    }
    
    func tryFollowGroup(groupKey key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.followers, [key]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .put, headers: header) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        }
    }
    
    func tryUnfollowGroup(groupKey key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.followers, [key]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: header) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        }
    }
    
    func tryDeleteGroup(groupKey key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.fetchDetails, [key]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: header) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        }
    }
    
    func fetchGroupFeed(groupKey key: String, from: String, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.fetchFeed, ["\(key)"]).url
        var parameters: [String: Any] = [
            GroupNetworkParameterKeys.Fetch.nextPage: from,
            GroupNetworkParameterKeys.Fetch.size: limit
        ]
        if from.isEmpty {
            parameters.removeValue(forKey: GroupNetworkParameterKeys.Fetch.nextPage)
        }
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let header = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .none, accept: .none)
        groupFeedSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: header, parameterDestination: .queryString, completion: { (data, err) in
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
                    let groupFeed = try decoder.decode(OrbisFeedPaginatedResponse.self, from: respData)
                    completion(groupFeed, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func fetchGroupEvents(groupKey key: String, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.events, ["\(key)"]).url
        let parameters: [String: Any] = [
            GroupNetworkParameterKeys.Fetch.page: page,
            GroupNetworkParameterKeys.Fetch.size: limit
        ]
        let headers = NetworkRequestManager.shared.getHeader(authorized: UserSessionManager.shared.currentUser != nil, contentType: .none, accept: .none)
        groupEventSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
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
                    let placeEvents = try decoder.decode(OrbisFeedPosts.self, from: respData)
                    completion(placeEvents, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func reportGroup(key: String, text: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.report, [key]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: ["reportText": text], method: .post, headers: header, isContentJSONString: true) { data, err in
            if let error = err {
                debugPrint("Error reporting group \(error.localizedDescription)")
                completion(nil, error)
            }
            else {
                completion(true, nil)
            }
        }
    }
    
    func hideStories(fromGroup key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.hideStories, [key]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .put, headers: header) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        }
    }
    
    func unhideStories(fromGroup key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.hideStories, [key]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: header) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        }
    }
}
