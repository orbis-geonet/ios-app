//
//  GroupMembersListViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 03/05/2021.
//

import Foundation
import Alamofire

class GroupMembersListViewModel {
    var group: Group!
    var members: OrbisUsers = []
    let manager = GroupListManager()
    var hasItemsLastPageReached = false
    var pageNumber: Int = 0
    private let offsetVal: Int = 10
    let type: UserGroupListType
    
    var searchText: String = ""
    
    init(group: Group) {
        type = .member
        self.group = group
        searchText = ""
        initializePagination()
        self.members = []
    }
    
    func initializePagination() {
        members = []
        hasItemsLastPageReached = false
        pageNumber = 0
    }
    
    var count: Int {
        return members.count
    }
    
    func getUser(at index: Int) -> OrbisUser {
        return members[index]
    }
    
    var onGroupMembersFetched: (() -> Void)?
    var onGroupMembersFetchLateResponse: (() -> Void)?
    var onGroupMembersFetchedCompletePagination: (() -> Void)?
    var onGroupMembersFetchError: ((Error) -> Void)?
    
    func loadUsers() {
        switch type {
        case .admin:
            break
        case .following:
            break
        case .member:
            loadGroupMembers()
            break
        }
    }
    
    func loadMoreUsers() {
        switch type {
        case .admin:
            break
        case .following:
            break
        case .member:
            lodMoreGroupMembers()
            break
        }
    }
    
    private func loadGroupMembers() {
        manager.invalidateAllNetworkRequests { [weak self] (_, _) in
            guard let self = self else { return }
            self.manager.fetchGroupMembers(groupKey: self.group.groupKey!, searchText: self.searchText, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
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
                        self?.onGroupMembersFetchError?(error)
                        return
                    }
                    else {
                        if let items = data as? UserSearchResult {
                            if items.searchText != self?.searchText {
                                self?.onGroupMembersFetchLateResponse?()
                                return
                            }
                            if items.users.count > 0 {
                                self?.members = items.users
                                self?.onGroupMembersFetched?()
                                self?.pageNumber = strongSelf2.pageNumber + 1
                                self?.hasItemsLastPageReached = false
                            }
                            else {
                                self?.hasItemsLastPageReached = true
                                self?.onGroupMembersFetchedCompletePagination?()
                            }
                        }
                        else {
                            self?.onGroupMembersFetchError?(ResponseError.invalidData)
                            return
                        }
                    }
            }
        }
    }
    
    private func lodMoreGroupMembers() {
        self.manager.fetchGroupMembers(groupKey: self.group.groupKey!, searchText: self.searchText, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
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
                    self?.onGroupMembersFetchError?(error)
                    return
                }
                else {
                    if let items = data as? UserSearchResult {
                        if items.searchText != self?.searchText {
                            self?.onGroupMembersFetchLateResponse?()
                            return
                        }
                        if items.users.count > 0 {
                            self?.members.append(contentsOf: items.users)
                            self?.onGroupMembersFetched?()
                            self?.pageNumber = strongSelf2.pageNumber + 1
                            self?.hasItemsLastPageReached = false
                        }
                        else {
                            self?.hasItemsLastPageReached = true
                            self?.onGroupMembersFetchedCompletePagination?()
                        }
                    }
                    else {
                        self?.onGroupMembersFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
}
