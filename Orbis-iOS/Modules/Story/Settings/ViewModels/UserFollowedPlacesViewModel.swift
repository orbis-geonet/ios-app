//
//  UserFollowedPlacesViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 09/09/2021.
//

import Foundation
import Alamofire

class UserFollowedPlacesViewModel {
    var model: OrbisPlaces! = []
    let manager = OrbisPlaceListManager()
    let detailManager = OrbisPlaceDetailManager()
    var hasItemsLastPageReached = false
    var pageNumber: Int = 0
    private let offsetVal: Int = 10
    var searchText: String = ""
    
    var user: OrbisUser? {
        return UserSessionManager.shared.currentUser
    }
    
    init() {
        searchText = ""
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
    
    func getPlaceItem(at index: Int) -> OrbisPlace {
        return model[index]
    }
    
    func getImageLink(at index: Int) -> String {
        let model = getPlaceItem(at: index)
        return model.placeDominantGroup?.imageName ?? ""
    }
    
    var onPlacesFetched: (() -> Void)?
    var onPlacesFetchLateResponse: (() -> Void)?
    var onPlacesFetchedCompletePagination: (() -> Void)?
    var onPlacesFetchError: ((Error) -> Void)?
    
    func loadFollowedOrbisPlaces() {
        guard let user = user else { return }
        manager.invalidateAllNetworkRequests { [weak self] (_, _) in
            guard let self = self else { return }
            self.manager.fetchUserFollowedPlaces(user: user.userKey!, searchText: self.searchText, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
                    guard let strongSelf2 = self else { return }
                    if let error = err {
                        let nsError = error as NSError
                        if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") || nsError.description.contains("cancelled") {
                            return
                        }
                        if let afError = error as? AFError {
                            if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                                return
                            }
                        }
                        self?.onPlacesFetchError?(error)
                        return
                    }
                    else {
                        if let items = data as? OrbisPlaceSearchResult {
                            if items.searchText != self?.searchText {
                                self?.onPlacesFetchLateResponse?()
                                return
                            }
                            if items.places.count > 0 {
                                self?.model = items.places
                                self?.onPlacesFetched?()
                                self?.pageNumber = strongSelf2.pageNumber + 1
                                self?.hasItemsLastPageReached = false
                            }
                            else {
                                self?.hasItemsLastPageReached = true
                                self?.onPlacesFetchedCompletePagination?()
                            }
                        }
                        else {
                            self?.onPlacesFetchError?(ResponseError.invalidData)
                            return
                        }
                    }
            }
        }
    }
    
    func loadMoreFollowedOrbisPlaces() {
        guard let user = user else { return }
        self.manager.fetchUserFollowedPlaces(user: user.userKey!, searchText: self.searchText, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
                guard let strongSelf2 = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") || nsError.description.contains("cancelled") {
                        return
                    }
                    if let afError = error as? AFError {
                        if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                            return
                        }
                    }
                    self?.onPlacesFetchError?(error)
                    return
                }
                else {
                    if let items = data as? OrbisPlaceSearchResult {
                        if items.searchText != self?.searchText {
                            self?.onPlacesFetchLateResponse?()
                            return
                        }
                        if items.places.count > 0 {
                            self?.model.append(contentsOf: items.places)
                            self?.onPlacesFetched?()
                            self?.pageNumber = strongSelf2.pageNumber + 1
                            self?.hasItemsLastPageReached = false
                        }
                        else {
                            self?.hasItemsLastPageReached = true
                            self?.onPlacesFetchedCompletePagination?()
                        }
                    }
                    else {
                        self?.onPlacesFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
    
    func followUnfollow(place: OrbisPlace, completion: @escaping responseBlock) {
        if place.isFollowing {
            detailManager.unfollowPlace(key: place.placeKey!) { [weak self] data, err in
                guard let self = self else { return }
                if err == nil {
                    self.model.removeAll(where: {$0.placeKey == place.placeKey})
                }
                completion(data, err)
            }
        }
        else {
            detailManager.followPlace(placeKey: place.placeKey!) { [weak self] data, err in
                guard let self = self else { return }
                if err == nil {
                    var newPlace = place
                    newPlace.following = false
                    if !self.model.contains(where: {$0.placeKey == newPlace.placeKey}) {
                        self.model.append(newPlace)
                    }
                }
                completion(data, err)
            }
        }
    }
}
