//
//  SubscriptionActivityViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 08/01/2023.
//

import Foundation

class SubscriptionActivityViewModel {
    var subscriptions: GroupSubscriptions!
    let manager = GroupSubscriptionManager()
    
    var groupModel: Group!
    var groupKey: String {
        return groupModel.groupKey ?? ""
    }
    
    var hasItemsLastPageReached = false
    var pageNumber: Int = 0
    private let offsetVal: Int = 20
    
    var currenctSelectedSubscriptionIndex: Int = 0 {
        didSet {
            onGroupSubscriptionSelectionChanged?(currenctSelectedSubscriptionIndex)
        }
    }
    
    var onGroupSubscriptionsFetched: ((_ isFirstPage: Bool) -> Void)?
    var onGroupSubscriptionsFetchedCompletePagination: (() -> Void)?
    var onGroupSubscriptionsFetchError: ((Error) -> Void)?
    
    var onGroupSubscriptionSelectionChanged: ((Int) -> Void)?
    
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
    
    var count: Int {
        return subscriptions.count
    }
    
    func getGroupSubscriptionItem(at index: Int) -> GroupSubscriptionModel {
        return subscriptions[index]
    }
    
    func loadGroupSubscriptions() {
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
                                self?.onGroupSubscriptionsFetched?(true)
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
                            self?.onGroupSubscriptionsFetched?(false)
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
