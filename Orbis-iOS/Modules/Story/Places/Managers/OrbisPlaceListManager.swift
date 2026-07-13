//
//  OrbisPlaceListManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 13/05/2021.
//

import Foundation
import UIKit
import CoreLocation
import Alamofire

typealias OrbisPlaceSearchResult = (places: OrbisPlaces, searchText: String)

class OrbisPlaceListManager {
    
    let orbisPlacesFetchSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    
    func invalidateAllNetworkRequests(completion: @escaping responseBlock) {
        self.orbisPlacesFetchSessionManager.invalidateAllSessionRequests(completion: completion)
    }
    
    func fetchPlacesList(location: CLLocationCoordinate2D, distance: Double, searchText: String, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.place(.fetchCreate, []).url
        let parameters: [String: Any] = [
            PlaceNetworkParameterKeys.Fetch.latitude: location.latitude,
            PlaceNetworkParameterKeys.Fetch.longitude: location.longitude,
            PlaceNetworkParameterKeys.Fetch.distance: distance,
            PlaceNetworkParameterKeys.Fetch.name: searchText,
            PlaceNetworkParameterKeys.Fetch.page: page,
            PlaceNetworkParameterKeys.Fetch.limit: limit
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
        orbisPlacesFetchSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, nil)
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let places = try decoder.decode(OrbisPlaces.self, from: respData)
                    let tuple: OrbisPlaceSearchResult = (places: places, searchText: searchText)
                    completion(tuple, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func fetchGroupOwnedPlaces(group key: String, searchText: String, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.place(.fetchCreate, []).url
        let parameters: [String: Any] = [
            PlaceNetworkParameterKeys.Fetch.groupOwned: key,
            PlaceNetworkParameterKeys.Fetch.name: searchText,
            PlaceNetworkParameterKeys.Fetch.page: page,
            PlaceNetworkParameterKeys.Fetch.limit: limit
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
        orbisPlacesFetchSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, nil)
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let places = try decoder.decode(OrbisPlaces.self, from: respData)
                    let tuple: OrbisPlaceSearchResult = (places: places, searchText: searchText)
                    completion(tuple, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func fetchUserFollowedPlaces(user key: String, searchText: String, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.followings, [key]).url
        let parameters: [String: Any] = [
            UserProfileDomainParameterKeys.Search.type: UserFollowingListType.place.rawValue.uppercased(),
            PlaceNetworkParameterKeys.Fetch.name: searchText,
            PlaceNetworkParameterKeys.Fetch.page: page,
            PlaceNetworkParameterKeys.Fetch.limit: limit
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
        orbisPlacesFetchSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, nil)
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let items = try decoder.decode(UserFollowingItems.self, from: respData)
                    let fetchedPlaces: OrbisPlaces = items.filter({$0.listType == .place}).filter({$0.place != nil}).map({$0.place!})
                    var places = OrbisPlaces()
                    fetchedPlaces.forEach { place in
                        var modifiedPlace = place
                        modifiedPlace.following = true
                        places.append(modifiedPlace)
                    }
                    let tuple: OrbisPlaceSearchResult = (places: places, searchText: searchText)
                    completion(tuple, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func tryRemovePlaceFromGroup(groupKey: String, placeKey: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.removePlaceFromGroup, [groupKey, placeKey]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: header) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        }
    }
}
