//
//  OrbisMapPlacesManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 07/05/2021.
//

import Foundation
import CoreLocation
import Alamofire

typealias MapPlacesFetchResult = (result: OrbisPlaces, location: CLLocationCoordinate2D, distance: Double)

typealias MapPlacesFetchResultPolygon = (result: PolygonPlacesDetails, location: CLLocationCoordinate2D, distance: Double)

public class ISOCommonFormatter {
    static var shared = ISO8601DateFormatter()
}

class OrbisMapPlacesManager {
    
    let mapPlacesFetchSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    
    private lazy var formatter = ISOCommonFormatter.shared
    
    func invalidateAllNetworkRequests(completion: @escaping responseBlock) {
        self.mapPlacesFetchSessionManager.invalidateAllSessionRequests(completion: completion)
    }
    
    func fetchPlaces(location: CLLocationCoordinate2D, distance: Double, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = "https://orbisv2-production.appspot.com/polygon-calculations/polygons-page" //GetApiAddress.place(.mapPlaces, []).url
        let parameters: [String: Any] = [
            PlaceNetworkParameterKeys.Fetch.latitude: location.latitude,
            PlaceNetworkParameterKeys.Fetch.longitude: location.longitude,
            PlaceNetworkParameterKeys.Fetch.distance: distance,
            PlaceNetworkParameterKeys.Fetch.page: page,
            PlaceNetworkParameterKeys.Fetch.limit: limit
        ]
        
        print("+++ Req url: \(url)")
        print("+++ Req para: \(parameters)")
        mapPlacesFetchSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: [:], parameterDestination: .queryString, completion: { (data, err) in
            if let error = err {
                if let afError = error as? AFError {
                    if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                        completion(nil, nil)
                        return
                    }
                }
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
                    let tuple: MapPlacesFetchResult = (result: places.removingInvalidMapPlaces(with: self.formatter).sorted(by: {$0.calculatedSize(with: self.formatter) < $1.calculatedSize(with: self.formatter)}), location: location, distance: distance)
                    completion(tuple, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func fetchPlaceDetail(withKey key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.place(.details, [key]).url
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let header = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .none, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .get, headers: header) { (data, err) in
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
                    let group = try decoder.decode(OrbisPlace.self, from: respData)
                    completion(group, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func fetchMapCenterAddress(location: CLLocationCoordinate2D, completion: @escaping responseBlock) {
        let url = GetApiAddress.place(.mapCurrentAddress, []).url
        let parameters: [String: Any] = [
            PlaceNetworkParameterKeys.Fetch.latitude: location.latitude,
            PlaceNetworkParameterKeys.Fetch.longitude: location.longitude
        ]
        mapPlacesFetchSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: [:], parameterDestination: .queryString, completion: { (data, err) in
            if let error = err {
                if let afError = error as? AFError {
                    if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                        completion(nil, nil)
                        return
                    }
                }
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
                    var placeNameResponse = try decoder.decode(MapCenterAddressResponse.self, from: respData)
                    placeNameResponse.centerCoordinate = location
                    completion(placeNameResponse, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
}

//MARK: Polygon section

extension OrbisMapPlacesManager {
    
    func fetchPlacesPolygon(location: CLLocationCoordinate2D, distance: Double, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = "https://orbisv2-production.appspot.com/polygon-calculations/polygons-page" //GetApiAddress.place(.mapPlaces, []).url
        let parameters: [String: Any] = [
            PlaceNetworkParameterKeys.Fetch.latitude: location.latitude,
            PlaceNetworkParameterKeys.Fetch.longitude: location.longitude,
            PlaceNetworkParameterKeys.Fetch.distance: distance,
            PlaceNetworkParameterKeys.Fetch.page: page,
            PlaceNetworkParameterKeys.Fetch.limit: limit
        ]
        
        print("+++ Req url: \(url)")
        print("+++ Req para: \(parameters)")
        mapPlacesFetchSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: [:], parameterDestination: .queryString, completion: { (data, err) in
            if let error = err {
                if let afError = error as? AFError {
                    if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                        completion(nil, nil)
                        return
                    }
                }
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
                    let places = try decoder.decode(PolygonPlacesDetails.self, from: respData)
                    let tuple: MapPlacesFetchResultPolygon = (result: places, location: location, distance: distance)
//                    (result: places.removingInvalidMapPlaces(with: self.formatter).sorted(by: {$0.calculatedSize(with: self.formatter) < $1.calculatedSize(with: self.formatter)}), location: location, distance: distance)
                    completion(tuple, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
}
