//
//  NotificationListViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 10/04/2021.
//

import Foundation
import Alamofire

class NotificationListViewModel {
    var data: OrbisNotifications = []
    let manager = OrbisNotificationManager()
    let notificationSeenManager = OrbisNotificationManager()
    
    var onNotificationsFetched: (() -> Void)?
    var onNotificationsFetchedCompletePagination: (() -> Void)?
    var onNotificationsFetchError: ((Error) -> Void)?
    var onNotificationsRead: (() -> Void)?
    
    var hasItemsLastPageReached = false
    var pageNumber: Int = 0
    private let offsetVal: Int = 10
    
    init() {
        initializePagination()
    }
    
    var count: Int {
        return data.count
    }
    
    func getNotificationModel(at index: Int) -> OrbisNotification {
        return data[index]
    }
    
    func initializePagination() {
        data = []
        hasItemsLastPageReached = false
        pageNumber = 0
    }
    
    func loadNotifications() {
        self.manager.fetchNotifications(page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
            guard let self = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                        return
                    }
                    self.onNotificationsFetchError?(error)
                    return
                }
                else {
                    if let items = data as? OrbisNotifications {
                        if items.count > 0 {
                            self.data = items
                            self.onNotificationsFetched?()
                            self.markNotificationsAsRead(ids: items.getUnreadNotificationsIds())
                            self.pageNumber += 1
                            self.hasItemsLastPageReached = false
                        }
                        else {
                            self.hasItemsLastPageReached = true
                            self.onNotificationsFetchedCompletePagination?()
                        }
                    }
                    else {
                        self.onNotificationsFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
    
    func loadMoreNotifications() {
        self.manager.fetchNotifications(page: self.pageNumber, limit: self.offsetVal)  { [weak self] (data, err) in
            guard let self = self else { return }
                if let error = err {
                    if let afError = error as? AFError {
                        if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                            return
                        }
                    }
                    self.onNotificationsFetchError?(error)
                    return
                }
                else {
                    if let items = data as? OrbisNotifications {
                        if items.count > 0 {
                            self.data.append(contentsOf: items)
                            self.markNotificationsAsRead(ids: items.getUnreadNotificationsIds())
                            self.onNotificationsFetched?()
                            self.pageNumber += 1
                            self.hasItemsLastPageReached = false
                        }
                        else {
                            self.hasItemsLastPageReached = true
                            self.onNotificationsFetchedCompletePagination?()
                        }
                    }
                    else {
                        self.onNotificationsFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
    
    func markNotificationsAsRead(ids: [String]) {
        guard !ids.isEmpty else { return }
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] timer in
            timer.invalidate()
            self?.performNotificationsMarkRead(ids: ids)
        }
    }
    
    private func performNotificationsMarkRead(ids: [String]) {
        notificationSeenManager.markNotificationRead(ids: ids) { [weak self] data, err in
            if let error = err {
                debugPrint("Error marking notifications seen \(error.localizedDescription)")
            }
            else {
                ids.forEach { key in
                    self?.setNotificationSeen(forKey: key)
                }
                self?.onNotificationsRead?()
            }
        }
    }
    
    private func setNotificationSeen(forKey key: String) {
        guard let index = self.data.firstIndex(where: {$0.notificationKey == key}), var notification = self.data.first(where: {$0.notificationKey == key}) else { return }
        notification.seen = true
        data[index] = notification
    }
    
    func deleteNotification(notification: OrbisNotification, completion: @escaping responseBlock) {
        if notification.notifType == .followRequest {
            guard let userKey = notification.fromUser?.userKey else {
                completion(nil, nil)
                return
            }
            manager.deletePendingRequest(userKey: userKey) { [weak self] data, err in
                if let error = err {
                    completion(nil, error)
                }
                else {
                    self?.data.removeAll(where: {(($0.notifType == .followRequest) && ($0.fromUser?.userKey == userKey))})
                    completion(true, nil)
                }
            }
        }
        else {
            manager.deleteNotification(key: notification.notificationKey!) { [weak self] data, err in
                if let error = err {
                    completion(nil, error)
                }
                else {
                    self?.data.removeAll(where: { $0.notificationKey == notification.notificationKey })
                    completion(true, nil)
                }
            }
        }
    }
    
    // MARK:- Pending requests
    
    func fetchPendingRequests() {
        self.manager.fetchPendingRequests(page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
            guard let self = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                        return
                    }
                    self.onNotificationsFetchError?(error)
                    return
                }
                else {
                    if let items = data as? OrbisNotifications {
                        if items.count > 0 {
                            self.data = items
                            self.markPendingNotificationsAsRead(ids: items.getUnreadPendingNotificationIds())
                            self.onNotificationsFetched?()
                            self.pageNumber += 1
                            self.hasItemsLastPageReached = false
                        }
                        else {
                            self.hasItemsLastPageReached = true
                            self.onNotificationsFetchedCompletePagination?()
                        }
                    }
                    else {
                        self.onNotificationsFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
    
    func fetchMorePendingRequests() {
        self.manager.fetchPendingRequests(page: self.pageNumber, limit: self.offsetVal)  { [weak self] (data, err) in
            guard let self = self else { return }
                if let error = err {
                    if let afError = error as? AFError {
                        if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                            return
                        }
                    }
                    self.onNotificationsFetchError?(error)
                    return
                }
                else {
                    if let items = data as? OrbisNotifications {
                        if items.count > 0 {
                            self.data.append(contentsOf: items)
                            self.markPendingNotificationsAsRead(ids: items.getUnreadPendingNotificationIds())
                            self.onNotificationsFetched?()
                            self.pageNumber += 1
                            self.hasItemsLastPageReached = false
                        }
                        else {
                            self.hasItemsLastPageReached = true
                            self.onNotificationsFetchedCompletePagination?()
                        }
                    }
                    else {
                        self.onNotificationsFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
    
    func acceptFollowRequest(forUser user: OrbisUser, completion: @escaping responseBlock) {
        self.manager.acceptPendingFollowRequest(userKey: user.userKey!) { [weak self] data, err in
            if let error = err {
                completion(nil, error)
            }
            else {
                self?.data.removeAll(where: {(($0.notifType == .followRequest) && ($0.fromUser?.userKey == user.userKey))})
                completion(true, nil)
            }
        }
    }
    
    func markPendingNotificationsAsRead(ids: [String]) {
        guard !ids.isEmpty else { return }
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] timer in
            timer.invalidate()
            self?.performPendingNotificationsMarkRead(ids: ids)
        }
    }
    
    private func performPendingNotificationsMarkRead(ids: [String]) {
        ids.forEach { [weak self] id in
            notificationSeenManager.markSeenPendingRequest(userKey: id) { [weak self] data, err in
                if let error = err {
                    debugPrint("Error marking pending notification seen \(error.localizedDescription)")
                }
                else {
                    ids.forEach { key in
                        self?.setPendingNotificationSeen(forUserKey: key)
                    }
                    self?.onNotificationsRead?()
                }
            }
        }
    }
    
    private func setPendingNotificationSeen(forUserKey key: String) {
        guard let index = self.data.firstIndex(where: {$0.fromUser?.userKey == key}), var notification = self.data.first(where: {$0.fromUser?.userKey == key}) else { return }
        notification.seen = true
        data[index] = notification
    }
}
