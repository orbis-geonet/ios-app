//
//  OrbisCreatePlaceManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 13/05/2021.
//

import Foundation
import CoreLocation

class OrbisCreatePlaceManager {
    
    func fetchRecommendedGroupList(location: CLLocationCoordinate2D, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.recommendedGroups, []).url
        let parameters: [String: Any] = [
            GroupNetworkParameterKeys.Fetch.latitude: location.latitude,
            GroupNetworkParameterKeys.Fetch.longitude: location.longitude,
            GroupNetworkParameterKeys.Fetch.size: limit
        ]
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, ResponseError.invalidData)
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let groups = try decoder.decode(Groups.self, from: respData)
                    completion(groups, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func createPlace(param: [String: Any], completion: @escaping responseBlock) {
        let url = GetApiAddress.place(.fetchCreate, []).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: param, method: .post, headers: headers, isContentJSON: true) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, ResponseError.invalidData)
                    return
                }
                
               
                let decoder = JSONDecoder()
                do {
                    //TODO: testing code
                    let PlaceDetails = try decoder.decode(PlaceDetails.self, from: respData)
                    
                    let place = try decoder.decode(OrbisPlace.self, from: respData)
                    CreatePlaceSharedManager.shared.addPlaceIdToNewlyBlockedObserver(placeKey: place.placeKey!)
                    //completion(place, nil) original code
                    completion(PlaceDetails, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
}
