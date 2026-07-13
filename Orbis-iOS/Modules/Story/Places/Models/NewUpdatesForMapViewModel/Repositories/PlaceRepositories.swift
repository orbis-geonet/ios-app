//
//  PlaceRepositories.swift
//  Orbis-iOS
//
//  Created by Kamran on 30/10/2024.
//


import Foundation
import Combine
import CoreLocation

class PlaceRepository {
    private let apiInterface = ApiServiceImplementation()
    private let prefManager = PrefManager()
    
   
    
    private func getToken() -> String {
        
        if let token = UserSessionManager.shared.currentUser?.idToken {
            return token
        }
        return ""
    }
    
    func createPlace(createPlaceBody: CreatePlaceBody) -> AnyPublisher<PlaceDetails, Error> {
        let token = getToken()
        return apiInterface.createPlace(token: token, createPlaceBody: createPlaceBody)
    }
    
    func ratePlace(ratePlaceBody: RatePlaceBody) -> AnyPublisher<RatePlaceModel, Error> {
        let token = getToken()
        return apiInterface.ratePlace(token: token, ratePlaceBody: ratePlaceBody)
    }
    
    func getEvents(placeKey: String, page: Int) -> AnyPublisher<[FeedPost], Error> {
        let token = getToken()
       // return apiInterface.getEventBy(token: token, placeKey: placeKey, page: page, pageSize: 25)
        return apiInterface.getEventBy(token: token, key: placeKey, pastEvents: false, page: page, size: 25)
    }
    
    func findPlacesForMap(latitude: Double, longitude: Double, page: Int) -> AnyPublisher<[PlaceDetails], Error> {
        return apiInterface.findPlacesForMap(latitude: latitude, longitude: longitude, distance: 50, page: page, size: 10)
    }
    
    func findPolygonPlacesForMap(latitude: Double, longitude: Double, page: Int) -> AnyPublisher<[PolygonPlaceDetails], Error> {
        return apiInterface.findPolygonPlacesForMap(latitude: latitude, longitude: longitude, distance: 25, page: page, size: 20)
    }
    
    func findGroupsForMap(latitude: Double, longitude: Double, page: Int) -> AnyPublisher<[String], Error> {
        let token = getToken()
        return apiInterface.findGroupsForMap(token: token, latitude: latitude, longitude: longitude, distance: 25, page: page, size: 700)
    }
    
    func getPlaceDetails(placeKey: String) -> AnyPublisher<PlaceDetails, Error> {
        let token = getToken()
        return apiInterface.getPlaceDetails(token: token, placeKey: placeKey)
    }
    
    func getPolygonPlaceDetails(placeKey: String) -> AnyPublisher<PolygonPlaceDetails, Error> {
        return apiInterface.getPolygonPlaceDetails(placeKey: placeKey)
    }
    
    func getPolygonPlaceStatus(checkInPolygonCoordinateKey: String) -> AnyPublisher<CheckInStatus, Error> {
        return apiInterface.getPolygonPlaceStatus(checkInPolygonCoordinateKey: checkInPolygonCoordinateKey)
    }
    
    func getPlaces(latitude: Double, longitude: Double, name: String, page: Int, distance: Int) -> AnyPublisher<[PlaceDetails], Error> {
        let token = getToken()
        return apiInterface.getPlaces(token: token, latitude: latitude, longitude: longitude, name: name, page: page, size: 25, distance: distance)
    }
    
    func createPost(postBody: PostBody) -> AnyPublisher<FeedPost, Error> {
        let token = getToken()
        return apiInterface.createPost(token: token, postBody: postBody)
    }
    
    func getPlaceFeedFirst(placeKey: String) -> AnyPublisher<Feed, Error> {
        let token = getToken()
        return apiInterface.getPlaceFeedFirst(token: token, placeKey: placeKey, size: 20)
    }
    
    func getPlaceFeed(placeKey: String, nextPage: String) -> AnyPublisher<Feed, Error> {
        let token = getToken()
        return apiInterface.getPlaceFeed(token: token, placeKey: placeKey, size: 20, nextPage: nextPage)
    }
    
    func followPlace(placeKey: String) -> AnyPublisher<Void, Error> {
        let token = getToken()
        return apiInterface.followPlace(token: token, placeKey: placeKey)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    func unfollowPlace(placeKey: String) -> AnyPublisher<Void, Error> {
        let token = getToken()
        return apiInterface.unfollowPlace(token: token, placeKey: placeKey)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    func updatePlace(placeUpdateBody: PlaceUpdateBody, placeKey: String) -> AnyPublisher<PlaceDetails, Error> {
        let token = getToken()
        return apiInterface.updatePlace(token: token, placeKey: placeKey, placeUpdateBody: placeUpdateBody)
    }
    
    func getLocationInfo(latitude: Double, longitude: Double) -> AnyPublisher<MapCenterAddressResponse, Error> {
        let token = getToken()
        
        return apiInterface.getLocationInfo(token: token, latitude: latitude, longitude: longitude)
        
//        if token.isEmpty{
//            return apiInterface.fetchCityDetails(using: CLGeocoder(), latitude: latitude, longitude: longitude)
//        } else {
//            return apiInterface.getLocationInfo(token: token, latitude: latitude, longitude: longitude)
//        }
    }
}
