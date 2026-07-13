//
//  OrbisNotificationManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 06/08/2021.
//

import Foundation

class OrbisNotificationManager {
    
    let notificationNetworkManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    
    func getUnreadNotificationsCount(completion: @escaping responseBlock) {
        let url = GetApiAddress.notifications(.unreadNotificationCount, []).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .get, headers: headers, parameterDestination: .methodDependent, completion: { (data, err) in
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
                    let count = try decoder.decode(OrbisNotificationCount.self, from: respData)
                    completion(count, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func fetchNotifications(page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.notifications(.get, []).url
        let parameters: [String: Any] = [
            PlaceNetworkParameterKeys.Fetch.page: page,
            PlaceNetworkParameterKeys.Fetch.limit: limit
        ]
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        notificationNetworkManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .methodDependent, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, nil)
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let notifications = try decoder.decode(OrbisNotifications.self, from: respData)
                    completion(notifications, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func markNotificationRead(ids: [String], completion: @escaping responseBlock) {
        let url = GetApiAddress.notifications(.setNotificationSeen, []).url
        let parameters: [String: Any] = [
            networkRequestArrayParametersKey: ids
        ]
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        notificationNetworkManager.processApiRequest(urlLink: url, parameters: parameters, method: .post, headers: headers, parameterDestination: .methodDependent, isContentArrayJSON: true, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
            }
        })
    }
    
    func deleteNotification(key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.notifications(.deleteNotification, [key]).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        pendingRequestsNetworkManager.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: headers, parameterDestination: .methodDependent, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        })
    }
    
    // MARK:- Pending Requests
    
    let pendingRequestsNetworkManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    
    func fetchPendingRequests(page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.pendingFollowRequests, []).url
        let parameters: [String: Any] = [
            PlaceNetworkParameterKeys.Fetch.page: page,
            PlaceNetworkParameterKeys.Fetch.limit: limit
        ]
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        pendingRequestsNetworkManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, nil)
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let users = try decoder.decode(OrbisUsers.self, from: respData)
                    completion(users.toPendingRequestNotifications, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func markSeenPendingRequest(userKey: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.seenFollowRequest, [userKey]).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        pendingRequestsNetworkManager.processApiRequest(urlLink: url, parameters: [:], method: .put, headers: headers, parameterDestination: .methodDependent, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        })
    }
    
    func acceptPendingFollowRequest(userKey: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.acceptFollowRequest, [userKey]).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        pendingRequestsNetworkManager.processApiRequest(urlLink: url, parameters: [:], method: .put, headers: headers, parameterDestination: .methodDependent, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        })
    }
    
    func deletePendingRequest(userKey: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.removeFollowRequest, [userKey]).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        pendingRequestsNetworkManager.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: headers, parameterDestination: .methodDependent, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        })
    }
}
