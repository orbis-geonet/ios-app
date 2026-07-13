//
//  UsersListViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 25/07/2021.
//

import Foundation
import Alamofire

enum UsersListType: String {
    case followers
    case followings
}

class UsersListViewModel {
    var model: OrbisUsers! = []
    let manager = UserSearchManager()
    var hasItemsLastPageReached = false
    var pageNumber: Int = 0
    private let offsetVal: Int = 10
    let type: UsersListType
    let user: OrbisUser
    
    init(user: OrbisUser, type: UsersListType) {
        self.user = user
        self.type = type
        initializePagination()
    }
    
    func initializePagination() {
        model = []
        hasItemsLastPageReached = false
        pageNumber = 0
    }
    
    var count: Int {
        return model.count
    }
    
    func getUserItem(at index: Int) -> OrbisUser {
        return model[index]
    }
    
    var onUsersFetched: (() -> Void)?
    var onUsersFetchedCompletePagination: (() -> Void)?
    var onUsersFetchError: ((Error) -> Void)?
    
    var viewTitle: String {
        switch type {
        case .followings:
            return AppStrings.Profile.following
        case .followers:
            return AppStrings.Profile.followers
        }
    }
    
    func loadUsers() {
        switch type {
        case .followers:
            loadUserFollowers()
            break
        case .followings:
            loadUserFollowings()
            break
        }
    }
    
    func loadMoreUsers() {
        switch type {
        case .followers:
            loadMoreUserFollowers()
            break
        case .followings:
            loadMoreUserFollowings()
            break
        }
    }
    
    private func loadUserFollowers() {
        manager.invalidateSearchProfileSession { [weak self] (_, _) in
            guard let self = self else { return }
            self.manager.fetchUserFollowers(userKey: self.user.userKey!, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
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
                        self?.onUsersFetchError?(error)
                        return
                    }
                    else {
                        if let items = data as? OrbisUsers {
                            if items.count > 0 {
                                self?.model = items
                                self?.onUsersFetched?()
                                self?.pageNumber = strongSelf2.pageNumber + 1
                                self?.hasItemsLastPageReached = false
                            }
                            else {
                                self?.hasItemsLastPageReached = true
                                self?.onUsersFetchedCompletePagination?()
                            }
                        }
                        else {
                            self?.onUsersFetchError?(ResponseError.invalidData)
                            return
                        }
                    }
            }
        }
    }
    
    private func loadMoreUserFollowers() {
        self.manager.fetchUserFollowers(userKey: self.user.userKey!, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
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
                    self?.onUsersFetchError?(error)
                    return
                }
                else {
                    if let items = data as? OrbisUsers {
                        if items.count > 0 {
                            self?.model.append(contentsOf: items)
                            self?.onUsersFetched?()
                            self?.pageNumber = strongSelf2.pageNumber + 1
                            self?.hasItemsLastPageReached = false
                        }
                        else {
                            self?.hasItemsLastPageReached = true
                            self?.onUsersFetchedCompletePagination?()
                        }
                    }
                    else {
                        self?.onUsersFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
    
    // MARK:- Followings
    
    private func loadUserFollowings() {
        manager.invalidateSearchProfileSession { [weak self] (_, _) in
            guard let self = self else { return }
            self.manager.fetchUserFollowings(userKey: self.user.userKey!, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
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
                        self?.onUsersFetchError?(error)
                        return
                    }
                    else {
                        if let items = data as? OrbisUsers {
                            if items.count > 0 {
                                self?.model = items
                                self?.onUsersFetched?()
                                self?.pageNumber = strongSelf2.pageNumber + 1
                                self?.hasItemsLastPageReached = false
                            }
                            else {
                                self?.hasItemsLastPageReached = true
                                self?.onUsersFetchedCompletePagination?()
                            }
                        }
                        else {
                            self?.onUsersFetchError?(ResponseError.invalidData)
                            return
                        }
                    }
            }
        }
    }
    
    private func loadMoreUserFollowings() {
        self.manager.fetchUserFollowings(userKey: self.user.userKey!, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
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
                    self?.onUsersFetchError?(error)
                    return
                }
                else {
                    if let items = data as? OrbisUsers {
                        if items.count > 0 {
                            self?.model.append(contentsOf: items)
                            self?.onUsersFetched?()
                            self?.pageNumber = strongSelf2.pageNumber + 1
                            self?.hasItemsLastPageReached = false
                        }
                        else {
                            self?.hasItemsLastPageReached = true
                            self?.onUsersFetchedCompletePagination?()
                        }
                    }
                    else {
                        self?.onUsersFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
}
