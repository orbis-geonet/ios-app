//
//  SearchCheckinListViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 07/04/2021.
//

import Foundation
import UIKit
import CoreLocation
import Alamofire

class SearchCheckinListViewModel {
    var model: OrbisPlaces! = []
    let manager = OrbisPlaceListManager()
    var hasItemsLastPageReached = false
    var pageNumber: Int = 0
    private let offsetVal: Int = 10
    private let searchDistanceInKM: Double = 50
    var userLocation: CLLocationCoordinate2D! {
        return UserSessionManager.shared.userCurrentLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
    var searchText: String = ""
    
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
    
    func loadOrbisPlaces() {
        manager.invalidateAllNetworkRequests { [weak self] (_, _) in
            guard let self = self else { return }
            self.manager.fetchPlacesList(location: self.userLocation, distance: self.searchDistanceInKM, searchText: self.searchText, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
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
        self.manager.fetchPlacesList(location: self.userLocation, distance: self.searchDistanceInKM, searchText: self.searchText, page: self.pageNumber, limit: self.offsetVal) { [weak self] (data, err) in
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
