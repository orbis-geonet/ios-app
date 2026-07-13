//
//  SubscriptionMembersViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 08/01/2023.
//

import Foundation
import Alamofire

class SubscriptionMembersViewModel {
    var subscription: GroupSubscriptionModel?
    let manager = GroupSubscriptionManager()
    
    var groupModel: Group!
    var groupKey: String {
        return groupModel.groupKey ?? ""
    }
    
    var subscribers: GroupSubscribers = []
    var filteredSubscribers: GroupSubscribers {
        if(searchText.isEmpty) { return subscribers }
        return subscribers.filter({$0.name?.lowercased().contains(searchText.lowercased()) ?? false })
    }
    
    var hasItemsLastPageReached = false
    var pageNumber: Int = 0
    private let offsetVal: Int = 20
    
    var searchText: String = ""
    
    var isSubscriptionSinglePurchase: Bool {
        return subscription?.type == GroupSubscriptionType.oneTime.rawValue
    }
    
    init(group: Group) {
        self.groupModel = group
        searchText = ""
        initializePagination()
    }
    
    func initializePagination() {
        subscribers = []
        hasItemsLastPageReached = false
        pageNumber = 0
    }
    
    var count: Int {
        return filteredSubscribers.count
    }
    
    func getUser(at index: Int) -> GroupSubscriber {
        return filteredSubscribers[index]
    }
    
    var onSubscribersFetched: (() -> Void)?
    var onSubscribersFetchLateResponse: (() -> Void)?
    var onSubscribersFetchedCompletePagination: (() -> Void)?
    var onSubscribersFetchError: ((Error) -> Void)?
    
    func loadSubscribers() {
        guard let subscriptionKey = self.subscription?.subscriptionKey else {
            onSubscribersFetched?()
            return
        }
        initializePagination()
        if isSubscriptionSinglePurchase {
            loadPurchaseUsers(subscriptionKey: subscriptionKey)
            return
        }
        manager.invalidateAllNetworkRequests { [weak self] (_, _) in
            guard let self = self else { return }
            self.manager.getGroupSubscribers(groupKey: self.groupKey, subscriptionKey: subscriptionKey, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
                    guard let strongSelf2 = self else { return }
                    if let error = err {
                        let nsError = error as NSError
                        if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                            return
                        }
                        if let afError = error as? AFError {
                            if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                                return
                            }
                        }
                        self?.onSubscribersFetchError?(error)
                        return
                    }
                    else {
                        if let items = data as? GroupSubscribers {
                            if items.count > 0 {
                                self?.subscribers = items
                                self?.onSubscribersFetched?()
                                self?.pageNumber = strongSelf2.pageNumber + 1
                                self?.hasItemsLastPageReached = false
                            }
                            else {
                                self?.hasItemsLastPageReached = true
                                self?.onSubscribersFetchedCompletePagination?()
                            }
                        }
                        else {
                            self?.onSubscribersFetchError?(ResponseError.invalidData)
                            return
                        }
                    }
            }
        }
    }
    
    func loadMoreSubscribers() {
        guard let subscriptionKey = self.subscription?.subscriptionKey else {
            onSubscribersFetched?()
            return
        }
        if isSubscriptionSinglePurchase {
            loadMorePurchaseUsers(subscriptionKey: subscriptionKey)
            return
        }
        self.manager.getGroupSubscribers(groupKey: self.groupKey, subscriptionKey: subscriptionKey, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
                guard let strongSelf2 = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                        return
                    }
                    if let afError = error as? AFError {
                        if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                            return
                        }
                    }
                    self?.onSubscribersFetchError?(error)
                    return
                }
                else {
                    if let items = data as? GroupSubscribers {
                        if items.count > 0 {
                            items.forEach { user in
                                if(!strongSelf2.subscribers.contains(where: {$0.userKey == user.userKey})) {
                                    self?.subscribers.append(user)
                                }
                            }
                            self?.onSubscribersFetched?()
                            self?.pageNumber = strongSelf2.pageNumber + 1
                            self?.hasItemsLastPageReached = false
                        }
                        else {
                            self?.hasItemsLastPageReached = true
                            self?.onSubscribersFetchedCompletePagination?()
                        }
                    }
                    else {
                        self?.onSubscribersFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
    
    private func loadPurchaseUsers(subscriptionKey: String) {
        manager.invalidateAllNetworkRequests { [weak self] (_, _) in
            guard let self = self else { return }
            self.manager.fetchGroupPurchases(groupKey: self.groupKey, subscriptionKey: subscriptionKey, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
                    guard let strongSelf2 = self else { return }
                    if let error = err {
                        let nsError = error as NSError
                        if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                            return
                        }
                        if let afError = error as? AFError {
                            if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                                return
                            }
                        }
                        self?.onSubscribersFetchError?(error)
                        return
                    }
                    else {
                        if let items = data as? GroupPurchases {
                            if items.count > 0 {
                                self?.subscribers = items.compactMap({ $0.toGroupSubscriber })
                                self?.onSubscribersFetched?()
                                self?.pageNumber = strongSelf2.pageNumber + 1
                                self?.hasItemsLastPageReached = false
                            }
                            else {
                                self?.hasItemsLastPageReached = true
                                self?.onSubscribersFetchedCompletePagination?()
                            }
                        }
                        else {
                            self?.onSubscribersFetchError?(ResponseError.invalidData)
                            return
                        }
                    }
            }
        }
    }
    
    private func loadMorePurchaseUsers(subscriptionKey: String) {
        self.manager.fetchGroupPurchases(groupKey: self.groupKey, subscriptionKey: subscriptionKey, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
                guard let strongSelf2 = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                        return
                    }
                    if let afError = error as? AFError {
                        if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                            return
                        }
                    }
                    self?.onSubscribersFetchError?(error)
                    return
                }
                else {
                    if let items = data as? GroupPurchases {
                        if items.count > 0 {
                            items.forEach { purchase in
                                let user = purchase.toGroupSubscriber
                                if(!strongSelf2.subscribers.contains(where: {$0.userKey == user.userKey})) {
                                    self?.subscribers.append(user)
                                }
                            }
                            self?.onSubscribersFetched?()
                            self?.pageNumber = strongSelf2.pageNumber + 1
                            self?.hasItemsLastPageReached = false
                        }
                        else {
                            self?.hasItemsLastPageReached = true
                            self?.onSubscribersFetchedCompletePagination?()
                        }
                    }
                    else {
                        self?.onSubscribersFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
}
