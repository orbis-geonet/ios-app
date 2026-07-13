//
//  SettingsSocialViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 12/04/2021.
//

import Foundation
import UIKit
import Alamofire

class SettingsSocialViewModel {
    let detailManager = UserProfileManager()
    let manager = UserGroupListManager()
    let subscriptionManager = GroupSubscriptionManager()
    var adminGroups: Groups = []
    var userSubscriptions: GroupConsumedSubscriptions = []
    var userPurchases: UserPurchases = []
    var user: OrbisUser? {
        return UserSessionManager.shared.currentUser
    }
    
    var onUserDetailUpdateError: ((Error) -> Void)?
    var onUserDetailUpdateSuccess: (() -> Void)?
    
    var pageNumber: Int = 0
    private let offsetVal: Int = 10
    var hasItemsLastPageReached = false
    
    var onGroupsFetched: (() -> Void)?
    var onGroupsFetchedCompletePagination: (() -> Void)?
    var onGroupsFetchError: ((Error) -> Void)?
    
    var onUserSubscriptionsFetched: (() -> Void)?
    var onUserSubscriptionsFetchError: ((Error) -> Void)?
    
    var onUserPurchasesFetched: (() -> Void)?
    var onUserPurchasesFetchError: ((Error) -> Void)?
    
    init() {
        userSubscriptions = []
        initializeAdminGroupPagination()
    }
    
    func initializeAdminGroupPagination() {
        adminGroups = []
        hasItemsLastPageReached = false
        pageNumber = 0
    }
    
    var groupCount: Int {
        return adminGroups.count
    }
    
    func getGroupModel(at index: Int) -> Group {
        return adminGroups[index]
    }
    
    var subscriptionsCount: Int {
        return userSubscriptions.count
    }
    
    func getSubscriptionModel(at index: Int) -> GroupConsumedSubscription {
        return userSubscriptions[index]
    }
    
    var purchasesCount: Int {
        return userPurchases.count
    }
    
    func getPurchaseModel(at index: Int) -> UserPurchaseModel {
        return userPurchases[index]
    }
    
    func replaceGroup(group: Group) {
        if let index = self.adminGroups.firstIndex(where: {$0.groupKey == group.groupKey}) {
            adminGroups[index] = group
        }
    }
    
    var isAccountPrivate: Bool {
        return user?.accountPrivate ?? false
    }
    
    func updateAccountPrivateStatus(value: Bool) {
        guard let user = self.user else { return }
        let param: [String: Any] = [UserProfileDomainParameterKeys.Update.accountPrivate: value]
        detailManager.updateUserData(userKey: user.userKey!, withParam: param) { [weak self] (data, err) in
            if let error = err {
                self?.onUserDetailUpdateError?(error)
                return
            }
            if let user = data as? OrbisUser {
                UserSessionManager.shared.saveUpdatedUserData(user: user) { data,err in
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: AppNotificationKeys.userDidUpdate), object: nil)
                }
                self?.onUserDetailUpdateSuccess?()
            }
            else {
                self?.onUserDetailUpdateError?(ResponseError.invalidData)
            }
        }
    }
    
    func loadAdminGroups() {
        guard let user = self.user else { return }
        manager.invalidateAllNetworkRequests { [weak self] (_, _) in
            guard let self = self else { return }
            self.manager.fetchUserAdminGroups(userKey: user.userKey!, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
                    guard let strongSelf2 = self else { return }
                    if let error = err {
                        let nsError = error as NSError
                        if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                            return
                        }
                        self?.onGroupsFetchError?(error)
                        return
                    }
                    else {
                        if let items = data as? Groups {
                            if items.count > 0 {
                                items.forEach { group in
                                    if !strongSelf2.adminGroups.contains(where: {$0.groupKey == group.groupKey}) {
                                        strongSelf2.adminGroups.append(group)
                                    }
                                }
                                self?.onGroupsFetched?()
                                self?.pageNumber = strongSelf2.pageNumber + 1
                                self?.hasItemsLastPageReached = false
                            }
                            else {
                                self?.hasItemsLastPageReached = true
                                self?.onGroupsFetchedCompletePagination?()
                            }
                        }
                        else {
                            self?.onGroupsFetchError?(ResponseError.invalidData)
                            return
                        }
                    }
            }
        }
    }
    
    func loadMoreAdminGroups() {
        guard let user = self.user else { return }
        self.manager.fetchUserAdminGroups(userKey: user.userKey!, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
                guard let strongSelf2 = self else { return }
                if let error = err {
                    if let afError = error as? AFError {
                        if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                            return
                        }
                    }
                    self?.onGroupsFetchError?(error)
                    return
                }
                else {
                    if let items = data as? Groups {
                        if items.count > 0 {
                            items.forEach { group in
                                if !strongSelf2.adminGroups.contains(where: {$0.groupKey == group.groupKey}) {
                                    strongSelf2.adminGroups.append(group)
                                }
                            }
                            self?.onGroupsFetched?()
                            self?.pageNumber = strongSelf2.pageNumber + 1
                            self?.hasItemsLastPageReached = false
                        }
                        else {
                            self?.hasItemsLastPageReached = true
                            self?.onGroupsFetchedCompletePagination?()
                        }
                    }
                    else {
                        self?.onGroupsFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
    
    func fetchUserSubscriptions() {
        self.subscriptionManager.fetchUserSubscriptions { [weak self] result, error in
            if let subscriptions = result as? GroupConsumedSubscriptions {
                self?.userSubscriptions = subscriptions
                self?.onUserSubscriptionsFetched?()
            } else {
                self?.onUserSubscriptionsFetchError?(error ?? CommonError.invalidDataFormat)
            }
        }
    }
    
    func fetchUserPurchases() {
        self.subscriptionManager.fetchUserPurchases { [weak self] result, error in
            if let purchases = result as? UserPurchases {
                self?.userPurchases = purchases
                self?.onUserPurchasesFetched?()
            } else {
                self?.onUserPurchasesFetchError?(error ?? CommonError.invalidDataFormat)
            }
        }
    }
    
    func cancelSubscription(forSubscription key: String, completion: @escaping responseBlock) {
        self.subscriptionManager.cancelSubscription(key: key) {
            [weak self] result, error in
            if let error = error {
                completion(nil, error)
            } else {
                self?.userSubscriptions.removeAll(where: {$0.subscriptionKey == key})
                completion(true, nil)
            }
        }
    }
}
