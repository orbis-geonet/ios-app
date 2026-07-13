//
//  GroupListViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 30/03/2021.
//

import Foundation
import CoreLocation
import Alamofire

class GroupListViewModel {
    var model: Groups! = []
    let manager = GroupManager()
    var hasItemsLastPageReached = false
    var pageNumber: Int = 0
    private let rankedOffsetVal: Int = 25
    private let offsetVal: Int = 10
    var userLocation: CLLocationCoordinate2D! {
        return UserSessionManager.shared.userCurrentLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
    var searchText: String = ""
    var hasRankedListFetched = false
    
    @Published var cachedGroups: [GroupDetails] = []
    let groupRepositories = GroupRepositories()
    
    var selfUser: OrbisUser? {
        return UserSessionManager.shared.currentUser
    }
    
    var isLoggedIn: Bool {
        if let user = selfUser, let key = user.userKey, !key.isEmpty {
            return true
        }
        return false
    }
    
    var isInitialcachedGroupsLoad = true
    
    init(searchText text: String) {
        searchText = text
        initializePagination()
    }
    
    func initializePagination() {
        model = []
        hasItemsLastPageReached = false
        pageNumber = 0
        hasRankedListFetched = false
    }
    
    var count: Int {
        return model.count
    }
    
    func getGroupItem(at index: Int) -> Group {
        return model[index]
    }
    
    var onGroupsFetched: (() -> Void)?
    var onGroupsRankingFetched: (() -> Void)?
    var onGroupsFetchLateResponse: (() -> Void)?
    var onGroupsFetchedCompletePagination: (() -> Void)?
    var onGroupsFetchError: ((Error) -> Void)?
    
    func loadGroups() {
        manager.invalidateAllNetworkRequests { [weak self] (_, _) in
            guard let self = self else { return }
            if self.searchText.isEmpty && self.hasRankedListFetched == false {
//                self.manager.fetchRankedGroupList(location: self.userLocation, limit: self.rankedOffsetVal) { [weak self] (data, err) in
//                    guard let strongSelf2 = self else { return }
                self.manager.fetchRankedGroupList(location: Constants.location!.coordinate, limit: self.rankedOffsetVal) { [weak self] (data, err) in
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
                        self?.onGroupsFetchError?(error)
                        return
                    }
                    else {
                        if let items = data as? Groups {
                            if !strongSelf2.searchText.isEmpty {
                                self?.hasRankedListFetched = true
                                self?.onGroupsFetchLateResponse?()
                                return
                            }
                            if items.count > 0 {
                                self?.model = items
                            }
                            self?.onGroupsRankingFetched?()
                            self?.hasRankedListFetched = true
                        }
                        else {
                            self?.onGroupsFetchError?(ResponseError.invalidData)
                            return
                        }
                    }
                }
            }
            else {
                self.manager.fetchGroupList(location: self.userLocation, searchText: self.searchText, showMembers: false, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
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
                                    items.groups.forEach { group in
                                        if !strongSelf2.model.contains(where: {$0.groupKey == group.groupKey}) {
                                            strongSelf2.model.append(group)
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
    }
    
    func loadMoreGroups() {
        self.manager.fetchGroupList(location: self.userLocation, searchText: self.searchText, showMembers: false, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
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
                            items.groups.forEach { group in
                                if !strongSelf2.model.contains(where: {$0.groupKey == group.groupKey}) {
                                    strongSelf2.model.append(group)
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
//MARK: Cache Management:-
extension GroupListViewModel {
    
    func getCachedGroups(city: String, userLoggedIn: Bool) {
        DispatchQueue.global(qos: .background).async {
            // Create a Realm instance specific to this background thread
            let groups = self.groupRepositories.getCachedGroups(city: city, loggedIn: userLoggedIn)
            
            DispatchQueue.main.async {
                // Assign results back on the main thread to avoid thread conflicts
                self.cachedGroups = groups
            }
        }
    }

    func cacheGroups(groups: [Groups], city: String, loggedIn: Bool) {
        DispatchQueue.global(qos: .background).async {
            // Assuming 'groups' is of type [[Group]]
            // Convert Groups to GroupDetails on the background thread
            let groupDetails: [GroupDetails] = groups.flatMap { $0.map { $0.toGroupDetails() } }
            
            // Use a background Realm instance to perform the caching operation
            self.groupRepositories.cacheGroups(groups: groupDetails, city: city, loggedIn: loggedIn)
        }
    }

    func deleteCachedGroups(city: String, loggedIn: Bool) {
        DispatchQueue.global(qos: .background).async {
            // Use a background Realm instance to safely delete groups
            self.groupRepositories.deleteGroupsFromCache(city: city, loggedIn: loggedIn)
        }
    }

}
