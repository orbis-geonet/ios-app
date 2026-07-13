//
//  GroupOwnedPlacesViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 14/06/2021.
//

import Foundation
import Alamofire

class GroupOwnedPlacesViewModel {
    let group: Group!
    var model: OrbisPlaces! = []
    let manager = OrbisPlaceListManager()
    var hasItemsLastPageReached = false
    var pageNumber: Int = 0
    private let offsetVal: Int = 10
    var searchText: String = ""
    
    init(group: Group) {
        self.group = group
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
    
    func removePlaceFromGroup(place: OrbisPlace, completion: @escaping responseBlock) {
        manager.tryRemovePlaceFromGroup(groupKey: self.group.groupKey!, placeKey: place.placeKey!) { [weak self] result, error in
            if let error = error {
                completion(nil, error)
            }
            else {
                self?.model.removeAll(where: {$0.placeKey == place.placeKey})
                completion(true, nil)
            }
        }
    }
    
    func loadOrbisPlaces() {
        manager.invalidateAllNetworkRequests { [weak self] (_, _) in
            guard let self = self else { return }
            self.manager.fetchGroupOwnedPlaces(group: self.group.groupKey!, searchText: self.searchText, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
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
    
    func loadMoreOrbisPlaces() {
        self.manager.fetchGroupOwnedPlaces(group: self.group.groupKey!, searchText: self.searchText, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
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
    
}
