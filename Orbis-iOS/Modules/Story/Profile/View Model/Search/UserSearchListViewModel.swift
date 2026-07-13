//
//  UserSearchListViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 03/04/2021.
//

import Foundation
import Alamofire

class UserSearchListViewModel {
    var model: OrbisUsers! = []
    let manager = UserSearchManager()
    var hasItemsLastPageReached = false
    var pageNumber: Int = 0
    private let offsetVal: Int = 10
    var searchText: String = ""
    
    init(searchText text: String) {
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
    
    func getUserItem(at index: Int) -> OrbisUser {
        return model[index]
    }
    
    var onUsersFetched: (() -> Void)?
    var onUsersFetchLateResponse: (() -> Void)?
    var onUsersFetchedCompletePagination: (() -> Void)?
    var onUsersFetchError: ((Error) -> Void)?
    
    func loadUsers() {
        guard !searchText.isEmpty else {
            initializePagination()
            self.onUsersFetched?()
            return
        }
        manager.invalidateSearchProfileSession { [weak self] (_, _) in
            guard let self = self else { return }
            self.manager.searchProfile(searchText: self.searchText, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
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
                        if let items = data as? UserSearchResult {
                            if items.searchText != self?.searchText {
                                self?.onUsersFetchLateResponse?()
                                return
                            }
                            if items.users.count > 0 {
                                self?.model = items.users
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
    
    func loadMoreUsers() {
        self.manager.searchProfile(searchText: self.searchText, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
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
                    if let items = data as? UserSearchResult {
                        if items.searchText != self?.searchText {
                            self?.onUsersFetchLateResponse?()
                            return
                        }
                        if items.users.count > 0 {
                            self?.model.append(contentsOf: items.users)
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
