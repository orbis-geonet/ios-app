//
//  GroupSubscriptionManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 07/01/2023.
//

import Foundation

class GroupSubscriptionManager {
    let groupSubscriptionsFetchSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    
    func invalidateAllNetworkRequests(completion: @escaping responseBlock) {
        self.groupSubscriptionsFetchSessionManager.invalidateAllSessionRequests(completion: completion)
    }
    
    func getGroupSubscriptions(groupKey: String, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.groupSubscription, [groupKey]).url
        let parameters: [String: Any] = [
            GroupNetworkParameterKeys.Fetch.page: page,
            GroupNetworkParameterKeys.Fetch.size: limit
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
        groupSubscriptionsFetchSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString) { (data, err) in
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
                    let subscriptions = try decoder.decode(GroupSubscriptions.self, from: respData)
                    completion(subscriptions, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }

    func getGroupSubscribers(groupKey: String, subscriptionKey: String, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.groupSubscribers, [groupKey]).url
        let parameters: [String: Any] = [
            GroupSubscriptionApiParamKeys.Create.subscriptionKey: subscriptionKey,
            GroupNetworkParameterKeys.Fetch.page: page,
            GroupNetworkParameterKeys.Fetch.size: limit
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
        groupSubscriptionsFetchSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString) { (data, err) in
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
                    let subscribers = try decoder.decode(GroupSubscribers.self, from: respData)
                    completion(subscribers, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func fetchGroupPurchases(groupKey: String, subscriptionKey: String, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.groupPurchases, [groupKey]).url
        let parameters: [String: Any] = [
            GroupSubscriptionApiParamKeys.List.purchaseKey: subscriptionKey,
            GroupNetworkParameterKeys.Fetch.page: page,
            GroupNetworkParameterKeys.Fetch.size: limit
        ]
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        groupSubscriptionsFetchSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers) { (data, err) in
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
                    let purchases = try decoder.decode(GroupPurchases.self, from: respData)
                    completion(purchases, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func getGroupSubscriptionStatistic(groupKey: String, subscriptionKey: String, type: SubscriptionGraphFilterValue, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.groupSubscriptionStatistics, [groupKey, subscriptionKey]).url
        let parameters: [String: Any] = [
            GroupSubscriptionApiParamKeys.Graph.type: type.rawValue.uppercased()
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
        groupSubscriptionsFetchSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString) { (data, err) in
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
                    let statResult = try decoder.decode(GroupSubscriptionStatistic.self, from: respData)
                    completion(statResult, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func getGroupPurchaseStatistic(groupKey: String, subscriptionKey: String, type: SubscriptionGraphFilterValue, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.groupPurchaseStatistics, [groupKey, subscriptionKey]).url
        let parameters: [String: Any] = [
            GroupSubscriptionApiParamKeys.Graph.type: type.rawValue.uppercased()
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
        groupSubscriptionsFetchSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString) { (data, err) in
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
                    let statResult = try decoder.decode(GroupSubscriptionStatistic.self, from: respData)
                    completion(statResult, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func getStripeTokens(subscriptionKey: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.subcribe, [subscriptionKey]).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        groupSubscriptionsFetchSessionManager.processApiRequest(urlLink: url, parameters: [:], method: .post, headers: headers) { (data, err) in
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
                    let stripeToken = try decoder.decode(OrbisStripeTokenModel.self, from: respData)
                    completion(stripeToken, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func getStripeToken(purchaseKey: String, quantity: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.purchase, [purchaseKey]).url
        let params: [String: Any] = [GroupSubscriptionApiParamKeys.Buy.number: quantity]
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        groupSubscriptionsFetchSessionManager.processApiRequest(urlLink: url, parameters: params, method: .post, headers: headers, parameterDestination: .queryString) { (data, err) in
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
                    let stripeToken = try decoder.decode(OrbisStripeTokenModel.self, from: respData)
                    completion(stripeToken, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func cancelSubscription(key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.unsubcribe, [key]).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        groupSubscriptionsFetchSessionManager.processApiRequest(urlLink: url, parameters: [:], method: .post, headers: headers) { (data, err) in
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
    
    func fetchUserSubscriptions(completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.userSubscrptions, []).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        groupSubscriptionsFetchSessionManager.processApiRequest(urlLink: url, parameters: [:], method: .get, headers: headers) { (data, err) in
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
                    let subscriptions = try decoder.decode(GroupConsumedSubscriptions.self, from: respData)
                    completion(subscriptions, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func fetchUserPurchases(completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.userPurchases, []).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        groupSubscriptionsFetchSessionManager.processApiRequest(urlLink: url, parameters: [:], method: .get, headers: headers) { (data, err) in
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
                    let purchases = try decoder.decode(UserPurchases.self, from: respData)
                    completion(purchases, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
}
