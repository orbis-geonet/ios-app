//
//  AdminSubscriptionManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 06/01/2023.
//

import Foundation

class AdminSubscriptionManager {
    func getSubscriptionCommissionInfo(completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.subscriptionCommisionInfo, []).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
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
                    let info = try decoder.decode(SubscriptionCommisionInfo.self, from: respData)
                    completion(info, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func createGroupSubscription(groupKey: String, param: [String: Any], completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.groupSubscription, [groupKey]).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: param, method: .post, headers: headers, isContentJSON: true) { (data, err) in
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
                    let subscription = try decoder.decode(GroupSubscriptionModel.self, from: respData)
                    completion(subscription, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func editGroupSubscription(groupKey: String, param: [String: Any], completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.groupSubscription, [groupKey]).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: param, method: .put, headers: headers, isContentJSON: true) { (data, err) in
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
                    let subscription = try decoder.decode(GroupSubscriptionModel.self, from: respData)
                    completion(subscription, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func deleteGroupSubscription(groupKey: String, subscriptionKey: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.groupSubscriptionDetail, [groupKey, subscriptionKey]).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: headers) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
            }
        }
    }
    
    func activateGroupSubscriptions(groupKey: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.groupSubscriptionActivate, [groupKey]).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .post, headers: headers) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
            }
        }
        
    }
    
    func deactivateGroupSubscriptions(groupKey: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.groupSubscriptionDeactivate, [groupKey]).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: ["sure": true], method: .post, headers: headers, parameterDestination: .queryString) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
            }
        }
        
    }
    
}
