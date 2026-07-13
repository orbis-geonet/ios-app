//
//  UserGroupListViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 25/07/2021.
//

import Foundation
import CoreLocation
import Alamofire

enum UserGroupListType: String {
    case member
    case admin
    case following
}

class UserGroupListViewModel {
    var model: Groups! = []
    let manager = UserGroupListManager()
    var hasItemsLastPageReached = false
    var pageNumber: Int = 0
    private let offsetVal: Int = 10
    var searchText: String = ""
    let user: OrbisUser
    let type: UserGroupListType
    
    init(type: UserGroupListType, user: OrbisUser, searchText text: String) {
        self.type = type
        self.user = user
        searchText = text
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
    
    func getGroupItem(at index: Int) -> Group {
        return model[index]
    }
    
    var onGroupsFetched: (() -> Void)?
    var onGroupsFetchLateResponse: (() -> Void)?
    var onGroupsFetchedCompletePagination: (() -> Void)?
    var onGroupsFetchError: ((Error) -> Void)?
    
    func loadGroups() {
        switch type {
        case .admin:
            break
        case .following:
            break
        case .member:
            loadUserMemberGroups()
            break
        }
    }
    
    func loadMoreGroups() {
        switch type {
        case .admin:
            break
        case .following:
            break
        case .member:
            loadMoreUserMemberGroups()
            break
        }
    }
    
    private func loadUserMemberGroups() {
        manager.invalidateAllNetworkRequests { [weak self] (_, _) in
            guard let self = self else { return }
            self.manager.fetchUserMemberGroups(userKey: self.user.userKey!, searchText: self.searchText, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
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
                        if let items = data as? GroupSearchResult {
                            if items.searchText != self?.searchText {
                                self?.onGroupsFetchLateResponse?()
                                return
                            }
                            if items.groups.count > 0 {
                                self?.model = items.groups
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
    
    private func loadMoreUserMemberGroups() {
        self.manager.fetchUserMemberGroups(userKey: self.user.userKey!, searchText: self.searchText, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
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
                    if let items = data as? GroupSearchResult {
                        if items.searchText != self?.searchText {
                            self?.onGroupsFetchLateResponse?()
                            return
                        }
                        if items.groups.count > 0 {
                            self?.model.append(contentsOf: items.groups)
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
