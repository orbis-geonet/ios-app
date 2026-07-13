//
//  UserBlockListViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 08/11/2021.
//

import Foundation
import Alamofire

class UserBlockListViewModel {
    var model: OrbisUsers! = []
    let profileManager = UserProfileManager()
    let manager = UserSearchManager()
    var hasItemsLastPageReached = false
    var pageNumber: Int = 0
    private let offsetVal: Int = 10
    var user: OrbisUser {
        return UserSessionManager.shared.currentUser!
    }
    
    init() {
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
    
    func loadUsers() {
        loadUserBlockList()
    }
    
    func loadMoreUsers() {
        loadMoreUserBlockList()
    }
    
    private func loadUserBlockList() {
        manager.invalidateSearchProfileSession { [weak self] (_, _) in
            guard let self = self else { return }
            self.manager.fetchUserBlockList(page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
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
    
    private func loadMoreUserBlockList() {
        self.manager.fetchUserBlockList(page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
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
    
    func unblockUser(user: OrbisUser, completion: @escaping responseBlock) {
        profileManager.unblockUser(key: user.userKey!) { [weak self] result, error in
            if let error = error {
                completion(nil, error)
            }
            else {
                self?.model.removeAll(where: {$0.userKey == user.userKey})
                completion(true, nil)
            }
        }
    }
}
