//
//  CreatePlaceViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 04/04/2021.
//

import Foundation
import GoogleMaps

class CreatePlaceModel {
    var publisher: OrbisUser?
    var groupPublisher: Group?
    var type: OrbisPlaceType?
    var name: String?
    var address: String?
    var placeLocation: CLLocationCoordinate2D?
    var userLocation: CLLocationCoordinate2D!
}

class CreatePlaceViewModel {
    var placeTypes: [OrbisPlaceType] = [
        .location, .building, .bar, .house, .castle, .sportsCenter, .fastFood, .shopping, .restaurant, .music, .beach, .school, .twoBuildings, .house2, .park
    ]
    var recommendedGroups = Groups()
    var model = CreatePlaceModel()
    var selectedTypeIndex: Int?
    var userLocation: CLLocationCoordinate2D {
        //return UserSessionManager.shared.userCurrentLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        //MARK: we changed it to current map location
        return Constants.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
    private let recommendedListLimit = 5
    let createManager = OrbisCreatePlaceManager()
    
    init() {
        model = CreatePlaceModel()
        model.userLocation = self.userLocation
        recommendedGroups = Groups()
        resetMapData()
    }
    
    var typeCount: Int {
        return placeTypes.count
    }
    
    var toCreateParams: [String: Any] {
        var params = [String: Any]()
        let placeCoordinatesParam = [
            PlaceNetworkParameterKeys.Create.longitude: placeLocation!.longitude,
            PlaceNetworkParameterKeys.Create.latitude: placeLocation!.latitude
        ]
        let userCoordinatesParam = [
            PlaceNetworkParameterKeys.Create.longitude: model.userLocation.longitude,
            PlaceNetworkParameterKeys.Create.latitude: model.userLocation.latitude
        ]
        params[PlaceNetworkParameterKeys.Create.coordinates] = placeCoordinatesParam
        params[PlaceNetworkParameterKeys.Create.userCoordinates] = userCoordinatesParam
        params[PlaceNetworkParameterKeys.Create.name] = self.placeName
        params[PlaceNetworkParameterKeys.Create.type] = self.type!.rawValue
        params[PlaceNetworkParameterKeys.Create.source] = AppValues.iosSource
        params[PlaceNetworkParameterKeys.Create.address] = self.address
        params[PlaceNetworkParameterKeys.Create.groupCreatedKey] = self.groupPublisher!.groupKey
        return params
    }
    
    var address: String? = nil
    
    var placeAddress: CLLocationCoordinate2D? {
        get {
            return model.placeLocation
        }
        set {
            model.placeLocation = newValue
        }
    }
    
    var publisher: OrbisUser? {
        get {
            return model.publisher
        }
        set {
            model.publisher = newValue
        }
    }
   
//    var groupPublisher: Group? { original
    var groupPublisher: Group? {
        get {
            return model.groupPublisher
        }
        set {
            model.groupPublisher = newValue
        }
    }
    
    var type: OrbisPlaceType? {
        get {
            return model.type
        }
        set {
            model.type = newValue
        }
    }
    
    var placeName: String {
        get {
            return model.name ?? ""
        }
        set {
            model.name = newValue
        }
    }
    
    var placeLocation: CLLocationCoordinate2D? {
        get {
            guard let placeLoc = model.placeLocation else {
                return nil
            }
            return CLLocationCoordinate2D(latitude: placeLoc.latitude, longitude: placeLoc.longitude)
        }
        set {
            model.placeLocation = newValue
        }
    }
    
    var publisherName: String {
        return publisher?.name ?? groupPublisher?.name ?? AppStrings.Places.chooseGroup
    }
    
    var publisherProPicLink: String {
        return publisher?.proPicLink ?? groupPublisher?.imageName ?? ""
    }
    
    var groupBaseColor: UIColor {
        guard let _ = groupPublisher else { return .clear }
        if let strokeColor = groupPublisher?.strokeColorHex {
            return UIColor.hexStringToUIColor(hex: strokeColor)
        }
        return groupPublisher?.baseColor ?? .clear
    }
    
    var publisherBorderWidth: CGFloat {
        if let _ = groupPublisher {
            return 3.toCGFloat.relativeToIphone8Width()
        }
        return 0
    }
    
    var placeTypeImage: UIImage {
        return model.type?.correspondingImage() ?? UIImage()
    }
    
    // Map Model
    var mapMarkers: [GMSMarker] = []
    
    private let markerBorderInMeter: CLLocationDistance = 15
    
    struct MarkerRadiusInMeter {
        static let big = 300
        static let small = 150
    }
    
    func resetMapData() {
        mapMarkers = []
    }
    
    func addPlaceMarkerToMap(mapView: GMSMapView, place: OrbisPlace) {
        // Creates a marker for store
        let customMarkerIconHolderView = PlaceMarkerView(image: place.placeType.correspondingImage() ?? UIImage(), bgColor: .white, size: CGSize(width: 60.toCGFloat.relativeToIphone8Width(), height: 60.toCGFloat.relativeToIphone8Width()))
        let customMarker = PlaceGMSMarker(place: place)
        customMarker.position = CLLocationCoordinate2D(latitude: place.coordinates!.latitude!, longitude: place.coordinates!.longitude!)
        customMarker.map = mapView
        customMarker.iconView = customMarkerIconHolderView
//        customMarker.isDraggable = true
        mapMarkers.append(customMarker)
    }
    
    func loadRecommendedGroups(completion: @escaping responseBlock) {
        createManager.fetchRecommendedGroupList(location: userLocation, limit: recommendedListLimit) { [weak self] data, err in
            if let groups = data as? Groups {
                self?.recommendedGroups = groups
                completion(true, nil)
            }
            else {
                completion(nil, err ?? ResponseError.invalidData)
            }
        }
    }
    
    func validateFirstScreenFields(completion: @escaping responseBlock) {
        if !placeName.isValidField {
            completion(nil, ValidationErrors.emptyPlaceName)
            return
        }
        if groupPublisher == nil {
            completion(nil, ValidationErrors.emptyPlaceGroup)
            return
        }
        if self.type == nil {
            completion(nil, ValidationErrors.emptyPlaceType)
            return
        }
        completion(true, nil)
    }
    
    func validateSecondScreenFields(completion: @escaping responseBlock) {
        validateFirstScreenFields { [weak self] success, err in
            guard let self = self else { return }
            if let error = err {
                completion(nil, error)
            }
            else {
                if self.placeLocation == nil {
                    completion(nil, ValidationErrors.emptyPlaceLocation)
                }
                else {
                    completion(true, nil)
                }
            }
        }
    }
    
    func tryCreatePlace(completion: @escaping responseBlock) {
        validateSecondScreenFields { [weak self] data, err in
            if let error = err {
                completion(nil, error)
            }
            else {
                self?.proceedTryCreatePlace(completion: completion)
            }
        }
    }
    
    private func proceedTryCreatePlace(completion: @escaping responseBlock) {
        let createParam = toCreateParams
        createManager.createPlace(param: createParam, completion: completion)
    }
}
