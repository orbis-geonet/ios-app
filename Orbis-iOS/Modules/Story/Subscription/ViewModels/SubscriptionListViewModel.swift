//
//  SubscriptionListViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 07/01/2023.
//

import Foundation

class SubscriptionListViewModel {
    var subscriptions: GroupSubscriptions = []
    let manager = GroupSubscriptionManager()
    let adminManager = AdminSubscriptionManager()
    
    var groupModel: Group!
    var groupKey: String {
        return groupModel.groupKey ?? ""
    }
    var hasItemsLastPageReached = false
    var pageNumber: Int = 0
    private let offsetVal: Int = 20
    
    var onGroupSubscriptionsFetched: (() -> Void)?
    var onGroupSubscriptionsFetchedCompletePagination: (() -> Void)?
    var onGroupSubscriptionsFetchError: ((Error) -> Void)?
    
    var isMainAdmin: Bool {
        return groupModel.isMainAdmin ?? false
    }
    
    init(group: Group) {
        self.groupModel = group
        initializePagination()
    }
    
    func initializePagination(clearItems: Bool = true) {
        if(clearItems) {
            subscriptions = []
        }
        hasItemsLastPageReached = false
        pageNumber = 0
    }
    
    var isAdmin: Bool {
        return groupModel.isAdmin ?? false
    }
    
    var count: Int {
        return subscriptions.count
    }
    
    func getGroupSubscriptionItem(at index: Int) -> GroupSubscriptionModel {
        return subscriptions[index]
    }
    
    func isSubscriptionSinglePurchase(key: String) -> Bool {
        guard let index = subscriptions.firstIndex(where: {$0.subscriptionKey == key}) else { return false }
        return subscriptions[index].type == GroupSubscriptionType.oneTime.rawValue
    }
    
    func updateSubscriptionStatus(key: String, isSubscriber: Bool) {
        guard let index = subscriptions.firstIndex(where: {$0.subscriptionKey == key}) else { return }
        subscriptions[index].isSubscriber = isSubscriber
    }
    
    func loadGroupSubscriptions() {
        initializePagination()
        manager.invalidateAllNetworkRequests { [weak self] (_, _) in
            guard let self = self else { return }
            self.manager.getGroupSubscriptions(groupKey: self.groupKey, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
                    guard let strongSelf2 = self else { return }
                    if let error = err {
                        let nsError = error as NSError
                        if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                            return
                        }
                        self?.onGroupSubscriptionsFetchError?(error)
                        return
                    }
                    else {
                        if let items = data as? GroupSubscriptions {
                            if items.count > 0 {
                                items.forEach { subscription in
                                    if let index = strongSelf2.subscriptions.firstIndex(where: {$0.subscriptionKey == subscription.subscriptionKey}) {
                                        strongSelf2.subscriptions[index] = subscription
                                    } else {
                                        strongSelf2.subscriptions.append(subscription)
                                    }
                                }
                                self?.pageNumber = strongSelf2.pageNumber + 1
                                self?.hasItemsLastPageReached = false
                                self?.onGroupSubscriptionsFetched?()
                            }
                            else {
                                self?.hasItemsLastPageReached = true
                                self?.onGroupSubscriptionsFetchedCompletePagination?()
                            }
                        }
                        else {
                            self?.onGroupSubscriptionsFetchError?(ResponseError.invalidData)
                            return
                        }
                    }
            }
        }
    }
    
    func loadMoreGroupSubscriptions() {
        self.manager.getGroupSubscriptions(groupKey: self.groupKey, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
                guard let strongSelf2 = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                        return
                    }
                    self?.onGroupSubscriptionsFetchError?(error)
                    return
                }
                else {
                    if let items = data as? GroupSubscriptions {
                        if items.count > 0 {
                            items.forEach { subscription in
                                if let index = strongSelf2.subscriptions.firstIndex(where: {$0.subscriptionKey == subscription.subscriptionKey}) {
                                    strongSelf2.subscriptions[index] = subscription
                                } else {
                                    strongSelf2.subscriptions.append(subscription)
                                }
                            }
                            self?.pageNumber = strongSelf2.pageNumber + 1
                            self?.hasItemsLastPageReached = false
                            self?.onGroupSubscriptionsFetched?()
                        }
                        else {
                            self?.hasItemsLastPageReached = true
                            self?.onGroupSubscriptionsFetchedCompletePagination?()
                        }
                    }
                    else {
                        self?.onGroupSubscriptionsFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
    
    func tryDeleteSubscription(at index: Int, completion: @escaping responseBlock) {
        guard let key = subscriptions[index].subscriptionKey else {
            completion(nil, CommonError.invalidDataFormat)
            return
        }
        guard isMainAdmin else {
            completion(nil, ValidationErrors.notAuthorized)
            return
        }
        adminManager.deleteGroupSubscription(groupKey: groupKey, subscriptionKey: key) { [weak self] result, error in
            if let error = error {
                completion(nil, error)
            } else {
                self?.subscriptions.removeAll(where: { $0.subscriptionKey == key })
                completion(result, error)
            }
        }
    }
}

// Normal User point of view
extension SubscriptionListViewModel {
    
    func getStripeTokenFromServer(forSubscription key: String, completion: @escaping responseBlock) {
        manager.getStripeTokens(subscriptionKey: key, completion: completion)
    }
    
    func getStripeTokenFromServer(forPurchase key: String, quantity: Int, completion: @escaping responseBlock) {
        manager.getStripeToken(purchaseKey: key, quantity: quantity, completion: completion)
    }
    
    func cancelSubscription(forSubscription key: String, completion: @escaping responseBlock) {
        manager.cancelSubscription(key: key, completion: completion)
    }
}
