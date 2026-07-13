//
//  MapViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/03/2021.
//

import Foundation
import UIKit
import GoogleMaps
import MapKit
import SDWebImage
import Combine

struct BrazilCoordinate {
    static let longitude = -46.671462399999996
    static let latitude = -23.592959999999998
}

struct NewYorkCoordinates {
    static let longitude = -74.0060//-73.971321
    static let latitude = 40.7128//40.7831
}
//let NewYork = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)

enum PlaceMapType {
    case small
    case big
}

enum OrbisPlaceSize: Double {
    case size500 = 500
    case size250 = 250
    case size150 = 150
    case size100 = 100
    case size50 = 50
    case size25 = 25
}

enum OrbisMapZoomRadius: Double {
    case size500 = 3000 // 500 * 6
    case size200 = 1200 // 200 * 6
    case size100 = 600 // 100 * 6
    case size50 = 300 // 50 * 6
    case size20 = 120  // 20* 6
}

enum OrbisPlaceCircleSizeCase {
    case get500
    case lt500get250
    case lt250get150
    case lt150get100
    case lt100get50
    case lt50get25
    case lt25
}

class MapViewModel {
    var mapView: GMSMapView!
    
    //
    @Published var mapPosition: GMSCameraPosition!
    @Published var selectedMarker: OrbisMapOverlayMarker?
    //
    
    @Published var centerCoordinatePlaceModel: MapCenterAddressResponse?
    
//    var mapData = [String: OrbisPlace]() //[OrbisPlace]()
    var mapData = [String: OrbisPlace]()
    var mapMarkers: [String: OrbisMapOverlayMarker] = [:] //[OrbisMapOverlayMarker] = []
    var mapMarkerContainers = [String: OrbisMarkerContainer]() //[OrbisMarkerContainer]()
    var activeGlowOverlay: OrbisMapOverlayCircle?
    let messagesManager = OrbisConversationManager()
    let notificationManager = OrbisNotificationManager()
    
    private let markerBorderInMeter: CLLocationDistance = 30
    private let glowRadiusMultiplier: CLLocationDistance = 2.8
    var shouldRemoveGlowOverlay = true
    let placesManager = OrbisMapPlacesManager()
    private let placeNameFetchManager = OrbisMapPlacesManager()
    var hasItemsLastPageReached = false
    var pageNumber: Int = 0
    private let offsetVal: Int = 20
    private let mapFetchDistanceInKM: Double = AppValues.mapFetchDistanceInKM
    private let firebaseObservableDistanceInMeter: Double = 60000
    var mapCenterCoordinate: CLLocationCoordinate2D?
    
    var mapImageInstances: [String: UIImage] = [:]
    var isCameraMoving = false
    var mapMovingBlockPlaces = [String: OrbisPlace]() //[OrbisPlace]()
    
    let firebaseManager = FirebaseDatabaseManager()
    var observerHandles = [UInt]()
    var boundingHashes = [String]()
    var firebaseObserverHandleMappings = [String: [UInt]]()
    var mapCachedImages = [String: UIImage]()
    
    var onPlaceSizeChangeNotifier: ((OrbisPlace) -> Void)?
    var onGroupOwnerShipChangeNotifier: ((OrbisPlace) -> Void)?
    var onFetchedPlaceForMapNotifier: ((OrbisPlace) -> Void)?
    var onFirstPageLoadComplete: (() -> Void)?
    var onMapSelectedMarkerRemoved: (() -> Void)?
    
    let formatter = ISOCommonFormatter.shared
    
    let synchronizedPlaceFetchQueue = DispatchQueue(label: "MapPlaceFetchQueue", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: .global())
    
    let forLoopOperationQueue = OperationQueue()
    
    
    //MARK: Polygon variables Kamran
    var placeOverlays: [GMSGroundOverlay: PolygonPlaceDetails] = [:]
    var focusPolygonMarkers: [GMSMarker: PolygonPlaceDetails] = [:]
    var pendingPlaces: [String: PolygonPlaceDetails] = [:]
    private var willBePlaceOverlays: [PolygonPlaceDetails] = []
    var associatedPolygons: [GMSOverlay: GMSPolygon?] = [:]
    private var lastOverlayUpdatedTime: TimeInterval = 0
    var isGroundOverlayClicked2 = false
    private var polygons: [String: GMSPolygon] = [:]
    var scaleAnimationTimer: Timer?
    var isAnimatingPolygon: Bool = false
    var visiblePolygonPlacesByKey: [String: PolygonPlaceDetails] = [:]

    
    
    
    init(mapView: GMSMapView) {
        self.mapView = mapView
        initializePagination()
        resetMapData()
        handleFirebaseObserverHandlers()
        
        // OP Queue
        forLoopOperationQueue.name = "forLoopQueue"
        forLoopOperationQueue.qualityOfService = .background
        forLoopOperationQueue.maxConcurrentOperationCount = 6
    }
    
    private func handleFirebaseObserverHandlers() {
        firebaseManager.onPlaceSizeChildChanged = {
            [weak self] changeResult in
            guard let self = self else {return}
            guard self.boundingHashes.contains(changeResult.hash) else { return }
            guard let centerCoordinate = self.mapCenterCoordinate else { return }
            guard changeResult.data.liesInsideObservableRegion(forMapCenterCoordinate: centerCoordinate, visibleRadius: self.mapFetchDistanceInKM * 1000) else { return }
            guard let placeKey = changeResult.data.placeKey else { return }
            debugPrint("Place change data incoming from Firebase: \(placeKey)")
            if CreatePlaceSharedManager.shared.newlyCreatedListContains(key: placeKey) { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else {return}
                if CreatePlaceSharedManager.shared.blockedPlaceIdsCount > 0 {
                    debugPrint("Blocked place change data \(placeKey)")
                    CreatePlaceSharedManager.shared.sizeChangeWaitingBuffer.append(changeResult)
                    return
                }
                //if self.mapData.contains(where: {$0.placeKey == placeKey}) {
                if let _ = self.mapData[placeKey] {
                    debugPrint("Updating existing place from firebase")
                    self.updatePlaceSizeForExistingPlace(placeKey: placeKey, changePlace: changeResult.data)
                }
                else {
                    debugPrint("Fetching new place from firebase change listener")
                    self.fetchAndAddUnavailablePlaceFromServer(key: placeKey)
                }
            }
        }
        firebaseManager.onGroupOwnershipChildChanged = {
            [weak self] changeResult in
            guard let self = self else {return}
            guard self.boundingHashes.contains(changeResult.hash) else { return }
            guard let centerCoordinate = self.mapCenterCoordinate else { return }
            guard changeResult.data.liesInsideObservableRegion(forMapCenterCoordinate: centerCoordinate, visibleRadius: self.mapFetchDistanceInKM * 1000) else { return }
            guard let placeKey = changeResult.data.placeKey else { return }
            debugPrint("Group ownership change data incoming from Firebase: \(placeKey)")
            if CreatePlaceSharedManager.shared.newlyCreatedListContains(key: placeKey) { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else {return}
                //if self.mapData.contains(where: {$0.placeKey == placeKey}) {
                if let _ = self.mapData[placeKey] {
                    self.updateGroupOwnershipForExistingPlace(placeKey: placeKey, changedGroupOwner: changeResult.data)
                }
                else {
                    self.fetchAndAddUnavailablePlaceFromServer(key: placeKey)
                }
            }
        }
    }
    
    func addMarkersInCamerMovingBlockedList(completion: @escaping responseBlock) {
        debugPrint("Adding map markers from moving blocked list")
        debugPrint("Blocked list count = \(self.mapMovingBlockPlaces.count)")
        guard let mapCenterCoordinates = self.mapCenterCoordinate else { return }
        let mapCenterLoc = CLLocation(latitude: mapCenterCoordinates.latitude, longitude: mapCenterCoordinates.longitude)
        //self.mapData.removeAll(where: {!$0.isWithinVisibleRange(ofDistance: self.mapFetchDistanceInKM * 1000, fromCoordinates: mapCenterLoc)})
        
        // Loop
//        for (key, mapDataItem) in mapData {
//            if !mapDataItem.isWithinVisibleRange(ofDistance: self.mapFetchDistanceInKM * 1000, fromCoordinates: mapCenterLoc) {
//                mapData[key] = nil
//            }
//        }
        
        let group = DispatchGroup()
//        self.mapMovingBlockPlaces.forEach { [weak self] place in
//            guard let self = self else {
//                return
//            }
//            group.enter()
//            self.addStoreToMap(mapView: self.mapView, orbisPlace: place, isNewlyCreatedPlace: true)
//            group.leave()
//        }
        
        // Loop
        for (_, place) in mapMovingBlockPlaces {
            group.enter()
            self.addStoreToMap(mapView: self.mapView, orbisPlace: place, isNewlyCreatedPlace: true)
            group.leave()
        }
        mapMovingBlockPlaces = [:]
        group.notify(queue: .main) {
            completion(true, nil)
        }
    }
    
    func runUpdateFromWaitingBuffer(completion: @escaping responseBlock) {
        debugPrint("Running change waiting buffer")
        debugPrint("Waiting buffer count = \(CreatePlaceSharedManager.shared.sizeChangeWaitingBuffer.count)")
        let group = DispatchGroup()
        
        // Loop
        CreatePlaceSharedManager.shared.sizeChangeWaitingBuffer.forEach { [weak self] changeResult in
            guard let self = self else {
                return
            }
            group.enter()
            self.applyAffectedPlaceUpdateFromBuffer(changeResult: changeResult)
            group.leave()
            
        }
        CreatePlaceSharedManager.shared.sizeChangeWaitingBuffer = []
        group.notify(queue: .main) {
            completion(true, nil)
        }
    }
    
    private func applyAffectedPlaceUpdateFromBuffer(changeResult: PlaceSizesChildChangedResult) {
        guard self.boundingHashes.contains(changeResult.hash) else { return }
        guard let centerCoordinate = self.mapCenterCoordinate else { return }
        guard changeResult.data.liesInsideObservableRegion(forMapCenterCoordinate: centerCoordinate, visibleRadius: self.mapFetchDistanceInKM * 1000) else { return }
        guard let placeKey = changeResult.data.placeKey else { return }
        //if self.mapData.contains(where: {$0.placeKey == placeKey}) {
        if let _ = self.mapData[placeKey] {
            self.updatePlaceSizeForExistingPlace(placeKey: placeKey, changePlace: changeResult.data)
        }
        else {
            self.fetchAndAddUnavailablePlaceFromServer(key: placeKey)
        }
    }
    
    func initializePagination() {
        pageNumber = 0
        hasItemsLastPageReached = false
    }
    
    func resetMapData() {
        mapMarkers = [:]
        mapMarkerContainers = [:]
        mapCachedImages = [:]
        activeGlowOverlay?.map = nil
        activeGlowOverlay = nil
    }
    
    func updateFirebaseObserverHandles() {
        //Loop
        for handle in observerHandles {
            firebaseManager.removeObserver(handle: handle)
        }
        observerHandles = []
        firebaseManager.removeAllObservers()
        boundingHashes = []
    }
    
    private func fetchAndAddUnavailablePlaceFromServer(key: String) {
        self.synchronizedPlaceFetchQueue.async {
            [weak self] in
            guard let self = self else { return }
            self.placesManager.fetchPlaceDetail(withKey: key) { [weak self] data, err in
                guard let self = self else { return }
                if let error = err {
                    debugPrint("Error in fetching place details: \(error.localizedDescription)")
                }
                else {
                    if let place = data as? OrbisPlace {
                        if CreatePlaceSharedManager.shared.newlyCreatedListContains(key: place.placeKey!) { return }
                        //if self.mapData.contains(where: {$0.placeKey == place.placeKey}) {
                        if let placeKey = place.placeKey, let _ = self.mapData[placeKey] {
                            //let position = arr.firstIndex(where: {$0.placeKey == place.placeKey})!
                            guard place.calculatedSize(with: self.formatter) > 0 else {
                                self.removeMarkerFromMap(placeKey: place.placeKey!)
                                return
                            }
                            
                            //self.mapData[position] = place
                            self.mapData[placeKey] = place
                        }
                        else {
                            guard let lastSize = place.lastSize, lastSize > 0, place.calculatedSize(with: self.formatter) > 0 else { return }
                            //self.mapData.append(place)
                            let placeKey = place.placeKey ?? "Unknown"
                            self.mapData[placeKey] = place
                        }
                        self.onFetchedPlaceForMapNotifier?(place)
                    }
                }
            }
            
        }
    }
    
    private func updatePlaceSizeForExistingPlace(placeKey: String, changePlace: PlaceSizesFirebaseModel) {
        //guard var place = mapData.first(where: {$0.placeKey == placeKey}), let position = mapData.firstIndex(where: {$0.placeKey == placeKey}) else { return }
        guard var place = mapData[placeKey] else { return }
        guard changePlace.hasChanged(withRespectToPlace: place) else {
            debugPrint("place changed data not changed for place \(placeKey)")
            return
        }
        place.lastSize = changePlace.lastSize
        place.lastSizeChangeTimestamp = Date(timeIntervalSince1970: (changePlace.lastSizeChangeTimestamp ?? 0)/1000).iso8601withFractionalSeconds
        place.lastCheckInTimestamp = Date(timeIntervalSince1970: (changePlace.lastCheckInTimestamp ?? 0)/1000).iso8601withFractionalSeconds
        guard place.calculatedSize(with: formatter) > 0 else {
            removeMarkerFromMap(placeKey: place.placeKey!)
            return
        }
        //mapData[position] = place
        self.mapData[placeKey] = place
        onPlaceSizeChangeNotifier?(place)
    }
    
    private func updateGroupOwnershipForExistingPlace(placeKey: String, changedGroupOwner group: GroupOwnershipFirebaseModel) {
        //guard var place = mapData.first(where: {$0.placeKey == placeKey}), let position = mapData.firstIndex(where: {$0.placeKey == placeKey}) else { return }
        guard var place = mapData[placeKey] else { return }
        guard group.hasChanged(withRespectToPlace: place) else { return }
        place.dominantGroup = group.toOrbisGroup
        place.dominantGroupKey = group.groupKey
        //mapData[position] = place
        self.mapData[placeKey] = place
        onGroupOwnerShipChangeNotifier?(place)
    }
    
    func removeMarkerFromMap(placeKey: String) {
        //mapData.removeAll(where: {$0.placeKey == placeKey})
        // Loop
        for (key, _) in mapData {
            if key == placeKey {
                mapData[key] = nil
            }
        }
        removeAllUnnecessaryMarkers()
    }
    
    func addUpdatePlaceToMapFromObserver(mapView: GMSMapView, place: OrbisPlace, isNewlyCreatedPlace: Bool) {
        print("+++ addUpdatePlaceToMapFromObserver")
        guard !isCameraMoving else {
            //if !mapMovingBlockPlaces.contains(where: {$0.placeKey == place.placeKey}) {
            //    mapMovingBlockPlaces.append(place)
            //}
            if let placeKey = place.placeKey, mapMovingBlockPlaces[placeKey] == nil {
                mapMovingBlockPlaces[placeKey] = place
            }
            return
        }
        //if mapMarkers.contains(where: {$0.mapPlaceId == place.placeKey}) {
        if let placeKey = place.placeKey, let _ = mapMarkers[placeKey] {
            // update existing marker
            //guard let marker = mapMarkers.first(where: {$0.mapPlaceId == place.placeKey}) else {
            //  return
            //}
            guard let placeKey = place.placeKey, let marker = mapMarkers[placeKey] else { return }
            updateExistingPlaceMarker(inMapView: mapView, mapMarker: marker, orbisPlace: place)
        }
        else {
            DispatchQueue.global(qos: .default).async {
                self.addStoreToMap(mapView: mapView, orbisPlace: place, isNewlyCreatedPlace: isNewlyCreatedPlace)
            }
        }
        removeActiveOverlayIfNeeded(forPlace: place, inMapView: mapView)
        mapView.selectedMarker = nil
        onMapSelectedMarkerRemoved?()
        //TODO: Polygon
        //addAllPolygonsBack()
    }
    
    //TODO: PolygonPLaceDetail
    private func removeActiveOverlayIfNeeded(forPlace place: OrbisPlace, inMapView map: GMSMapView) {
        if activeGlowOverlay?.mapPlaceId == place.placeKey {
            removeActiveGlowOverlay(mapView: map)
        }
    }
    
    private func updateExistingPlaceMarker(inMapView mapView: GMSMapView, mapMarker marker: OrbisMapOverlayMarker, orbisPlace: OrbisPlace) {
        //guard mapData.contains(where: {$0.placeKey == orbisPlace.placeKey}) else { return }
        guard let placeKey = orbisPlace.placeKey, let _ = mapData[placeKey] else { return }
        let placeholderImage = OrbisMapPlaceIconManager.shared.placeIcons[orbisPlace.placeType]!
        self.updateExistingPlaceMarkerWithImage(image: placeholderImage, inMapView: mapView, mapMarker: marker, orbisPlace: orbisPlace)
    }
    
    private func updateExistingPlaceMarkerWithImage(image: UIImage, inMapView mapView: GMSMapView, mapMarker marker: OrbisMapOverlayMarker, orbisPlace: OrbisPlace) {
        //guard let markerContainer = mapMarkerContainers.first(where: {($0.marker.mapPlaceId == marker.mapPlaceId)}) else {
        //    return
        //}
        guard let markerContainer = mapMarkerContainers[marker.mapPlaceId] else { return }
        
        let placeSize = orbisPlace.calculatedSize(with: formatter)
        let clDistance = CLLocationDistance(placeSize)
        let circleZIndex = Int32(1000 - placeSize)
        
        var color = UIColor(named: AppColors.appBlue.rawValue)
        if let colorHex = orbisPlace.placeDominantGroup?.strokeColorHexString {
            color = UIColor.hexStringToUIColor(hex: colorHex)
        }
        let oldRadius = marker.fixedRadius
        
        let hasChanged = (oldRadius != clDistance)
        if hasChanged {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                markerContainer.stopPulsate()
            }
        }
        
        marker.lastCheckinTimeStamp = orbisPlace.lastCheckinDate(with: formatter)
        let mapZoomRadius = mapView.getRadius()
        marker.mapPlaceBaseColor = color
        marker.mapPlaceId = orbisPlace.placeKey
        marker.position = CLLocationCoordinate2D(latitude: orbisPlace.coordinates?.latitude ?? 0, longitude: orbisPlace.coordinates?.longitude ?? 0)
        marker.zIndex = circleZIndex
        marker.icon = image
        if let imageName = orbisPlace.placeDominantGroup?.imageName, !imageName.isEmpty {
            if let img = self.getAlreadySetImage(forUrl: imageName) {
                marker.icon = img
                marker.imageUrlName = imageName
            }
        }
        
        if hasChanged {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                markerContainer.animateSizeChange(newSize: clDistance)
            }
        }
        
        let placeOpacity =  Float(getPlaceCircleOpacity(forCircle: marker, withSize: placeSize, mapRadius: mapZoomRadius))
        if let activeMarker = self.activeGlowOverlay {
            if activeMarker.mapPlaceId == orbisPlace.placeKey {
                marker.opacity = 1
                marker.fixedOpacity = 1
            }
            else {
                marker.opacity = 0.1
                marker.fixedOpacity = 0.1
            }
        }
        else {
            marker.opacity = placeOpacity
            marker.fixedOpacity = Float(placeOpacity)
        }
        
        updateOverlayOpacity(inMapView: mapView)
    }
    
    private func addStoreToMapWithImage(image: UIImage, mapView: GMSMapView, place orbisPlace: OrbisPlace, isNewlyCreatedPlace: Bool) {
        //guard !mapMarkers.contains(where: {$0.mapPlaceId == orbisPlace.placeKey}) else {
        //    if let marker = mapMarkers.first(where: {$0.mapPlaceId == orbisPlace.placeKey}) {
        //        updateExistingPlaceMarkerWithImage(image: image, inMapView: mapView, mapMarker: marker, orbisPlace: orbisPlace)
        //    }
        //    return
        //}
        let placeKey = orbisPlace.placeKey ?? "Unknown"
        if let marker = mapMarkers[placeKey] {
            //forLoopOperationQueue.addOperation { [weak self] in
                updateExistingPlaceMarkerWithImage(image: image, inMapView: mapView, mapMarker: marker, orbisPlace: orbisPlace)
            //}
            return
        }
        
        let placeSize = orbisPlace.calculatedSize(with: formatter)
        guard placeSize > 0 else {
            mapData[placeKey] = nil
            return
        }
        
        let fixedRadius = AppValues.mapFetchDistanceInKM * 1000
        var visibleRadius = min(fixedRadius, mapView.getRadius())
        if (AppValues.isCurrentDeviceIpad) {
            visibleRadius = visibleRadius * 0.5
        }
        let isVisibleSizeCriteriaMet = (mapView.getRadius() / placeSize) < AppValues.markersVisibilityFactor
        let mapCenter = mapView.camera.target
        let isWithinVisibleRange = orbisPlace.isWithinVisibleRange(mapView: mapView, ofDistance: visibleRadius, fromCoordinates: CLLocation(latitude: mapCenter.latitude, longitude: mapCenter.longitude))
        
        guard isVisibleSizeCriteriaMet && isWithinVisibleRange else {
            mapData[placeKey] = nil
            return
        }
        
        let clDistance = CLLocationDistance(placeSize)
        let coordinate = CLLocationCoordinate2D(latitude: orbisPlace.coordinates?.latitude ?? 0, longitude: orbisPlace.coordinates?.longitude ?? 0)
        let topLeftCoordinate = CLHelper.coordinate(from: coordinate, distance: -clDistance)
        let bottomRightCoordinate = CLHelper.coordinate(from: coordinate, distance: clDistance)
        let circleZIndex = Int32(1000 - placeSize)
        
        var color = UIColor(named: AppColors.appBlue.rawValue)
        if let colorHex = orbisPlace.placeDominantGroup?.strokeColorHexString {
            color = UIColor.hexStringToUIColor(hex: colorHex)
        }
        
        let customMarker = OrbisMapOverlayMarker(bounds: GMSCoordinateBounds(coordinate: topLeftCoordinate, coordinate: bottomRightCoordinate), icon: nil, radius: clDistance)
        customMarker.lastCheckinTimeStamp = orbisPlace.lastCheckinDate(with: formatter)
        customMarker.placeCoordinate = coordinate
        let mapZoomRadius = mapView.getRadius()
        customMarker.mapPlaceBaseColor = color
        customMarker.mapPlaceId = orbisPlace.placeKey
        customMarker.position = CLLocationCoordinate2D(latitude: orbisPlace.coordinates?.latitude ?? 0, longitude: orbisPlace.coordinates?.longitude ?? 0)
        
        let placeOpacity = Float(self.getPlaceCircleOpacity(forCircle: customMarker, withSize: placeSize, mapRadius: mapZoomRadius))
        
        if let activeMarker = self.activeGlowOverlay {
            if activeMarker.mapPlaceId == orbisPlace.placeKey {
                customMarker.opacity = 1
                customMarker.fixedOpacity = Float(1)
            }
            else {
                customMarker.opacity = 0.1
                customMarker.fixedOpacity = Float(0.1)
            }
        }
        else {
            customMarker.opacity = placeOpacity
            customMarker.fixedOpacity = Float(placeOpacity)
        }
        customMarker.isTappable = true
        customMarker.zIndex = circleZIndex
        //mapMarkers.append(customMarker)
        mapMarkers[customMarker.mapPlaceId] = customMarker
        
        let markerContainer = OrbisMarkerContainer(marker: customMarker,
                                                   inMap: mapView,
                                                   mapPosition: $mapPosition,
                                                   orbisPlace: orbisPlace,
                                                   selectedMarker: $selectedMarker,
                                                   isNewlyCreatedPlace: isNewlyCreatedPlace,
                                                   imageDelegate: self,
                                                   cleanupDelegate: self)
        //markerContainer.imageDelegate = self
        customMarker.icon = image
        if let imageName = orbisPlace.placeDominantGroup?.imageName, !imageName.isEmpty {
            if let img = self.getAlreadySetImage(forUrl: imageName) {
                customMarker.icon = img
                customMarker.imageUrlName = imageName
            }
//            else {
//                customMarker.imageUrlName = ""
//                markerContainer.updateImage(withUrl: imageName, placeholder: image)
//            }
        }
        // CH
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            customMarker.zIndex = circleZIndex
            //customMarker.map = mapView
            //isNewlyCreatedPlace ? markerContainer.showBubblyAnimationAndPulsate() : markerContainer.startPulsate()
//        }
        //mapMarkerContainers.append(markerContainer)
        mapMarkerContainers[markerContainer.mapPlaceId] = markerContainer
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.updateOverlayOpacity(inMapView: mapView)
            //self.drawPolygon(on: mapView, orbisPlace: orbisPlace.toPolygonPlaceDetails())
        }
    }
    
    private func addStoreToMap(mapView: GMSMapView, orbisPlace: OrbisPlace, isNewlyCreatedPlace: Bool) {
        guard !isCameraMoving else {
            //if !mapMovingBlockPlaces.contains(where: {$0.placeKey == orbisPlace.placeKey}) {
            //    mapMovingBlockPlaces.append(orbisPlace)
            //}
            let placeKey = orbisPlace.placeKey ?? "Unknown"
            if mapMovingBlockPlaces[placeKey] == nil {
                mapMovingBlockPlaces[placeKey] = orbisPlace
            }
            return
        }
        //guard mapData.contains(where: {$0.placeKey == orbisPlace.placeKey}) else { return }
        let placeKey = orbisPlace.placeKey ?? "Unknown"
        guard let _ = mapData[placeKey] else { return }
        //guard !mapMarkers.contains(where: {$0.mapPlaceId == orbisPlace.placeKey}) else {
        //    if let marker = mapMarkers.first(where: {$0.mapPlaceId == orbisPlace.placeKey}) {
        //        updateExistingPlaceMarker(inMapView: mapView, mapMarker: marker, orbisPlace: orbisPlace)
        //    }
        //    return
        //}
        guard mapMarkers[placeKey] == nil else {
            if let marker = mapMarkers[placeKey] {
                updateExistingPlaceMarker(inMapView: mapView, mapMarker: marker, orbisPlace: orbisPlace)
            }
            return
        }
        DispatchQueue.main.async {
            let placeholderImage = OrbisMapPlaceIconManager.shared.placeIcons[orbisPlace.placeType]!
            self.addStoreToMapWithImage(image: placeholderImage, mapView: mapView, place: orbisPlace, isNewlyCreatedPlace: isNewlyCreatedPlace)
        }
    }
    
    func updateVisibilityForSelectedMarker(marker: OrbisMapOverlayCircle) {
//        for placeMarker in mapMarkers {
//            if placeMarker.mapPlaceId == marker.mapPlaceId {
//                placeMarker.opacity = 1
//                placeMarker.fixedOpacity = 1
//            }
//            else {
//                placeMarker.opacity = 0.1
//                placeMarker.fixedOpacity = 0.1
//            }
//        }
        
        // Loop
//        for (_, placeMarker) in mapMarkers {
//            if placeMarker.mapPlaceId == marker.mapPlaceId {
//                placeMarker.opacity = 1
//                placeMarker.fixedOpacity = 1
//            } else {
//                placeMarker.opacity = 0.1
//                placeMarker.fixedOpacity = 0.1
//            }
//        }
//        for container in mapMarkerContainers {
//            container.stopPulsate()
//        }
        
        // Loop
//        for (_, mapMarkerContainer) in mapMarkerContainers {
//            mapMarkerContainer.stopPulsate()
//        }
    }
    
    func updateOverlayOpacity(inMapView mapView: GMSMapView) {
        print("+++ mapMarkers \(mapMarkers.count)")
        guard mapMarkers.count > 0 else { return }
        let mapZoomRadius = mapView.getRadius()
        //for placeMarker in mapMarkers {
        
        //
        
        forLoopOperationQueue.cancelAllOperations()
        
        // Loop
        for (mapPlaceId, placeMarker) in self.mapMarkers {
            //if let orbisPlace = mapData.first(where: {$0.placeKey == placeMarker.mapPlaceId}) {
                if let orbisPlace = self.mapData[mapPlaceId] {
                    let placeSize = orbisPlace.calculatedSize(with: self.formatter)
    //                let placeOpacity = getPlaceCircleOpacity(forCircle: placeMarker, withSize: placeSize, mapRadius: mapZoomRadius)
    //                if let activeMarker = self.activeGlowOverlay {
    //                    if activeMarker.mapPlaceId == orbisPlace.placeKey {
    //                        placeMarker.opacity = Float(1)
    //                        placeMarker.fixedOpacity = 1
    //                    }
    //                    else {
    //                        placeMarker.opacity = Float(0.1)
    //                        placeMarker.fixedOpacity = 0.1
    //                    }
    //                }
    //                else {
    //                    placeMarker.opacity = Float(placeOpacity)
    //                    placeMarker.fixedOpacity = Float(placeOpacity)
    //                }
                    
                    
                    //
//                forLoopOperationQueue.addOperation { [weak self] in
//                    guard let self = self else { return }
//
//                    var zoom: CLLocationDistance = .zero
//                    DispatchQueue.main.sync {
//                        zoom = mapView.getRadius()
//                    }
//
//                    let size = orbisPlace.size ?? 0.0
//                    print("+++ zoom: \(zoom)")
//                    print("+++ size: \(size)")
//                    let mapCenterLoc = CLLocation(latitude: self.mapCenterCoordinate?.latitude ?? 1, longitude: self.mapCenterCoordinate?.longitude ?? 1)
//                    let isSizeConditionMet = zoom / size <= 120
//                    let isWithinVisibleRange = orbisPlace.isWithinVisibleRange(ofDistance: zoom, fromCoordinates: mapCenterLoc)
//                    print("+++ condition attempt at: \(zoom / size)")
//                    if isSizeConditionMet && isWithinVisibleRange {
//                        print("+++ condition met")
//                        let imageName = orbisPlace.dominantGroup?.imageName ?? ""
//                        let markerContainer = self.mapMarkerContainers[mapPlaceId]
//                        markerContainer?.imageDelegate = self
//                        markerContainer?.(withUrl: imageName, placeholder: OrbisMapPlaceIconManager.shared.placeIcons[orbisPlace.placeType]!)
//
//                    } else {
//                        print("+++ condition failed")
//                        let image = OrbisMapPlaceIconManager.shared.placeIcons[orbisPlace.placeType]!
//                        let markerContainer = self.mapMarkerContainers[mapPlaceId]
//                        markerContainer?.imageDelegate = self
//                        markerContainer?.updateImage(withUrl: "", placeholder: image)
//
//                    }
//                }
                    //
                    
                    let placeOpacity = self.getPlaceCircleOpacity(forCircle: placeMarker, withSize: placeSize, mapRadius: mapZoomRadius)
                    if let activeMarker = self.activeGlowOverlay {
                        if activeMarker.mapPlaceId == orbisPlace.placeKey {
                            DispatchQueue.main.async {
                                placeMarker.opacity = Float(1)
                            }
                            placeMarker.fixedOpacity = 1
                        }
                        else {
                            DispatchQueue.main.async {
                                placeMarker.opacity = Float(0.1)
                            }
                            
                            placeMarker.fixedOpacity = 0.1
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            placeMarker.opacity = Float(placeOpacity)
                        }
                        
                        placeMarker.fixedOpacity = Float(placeOpacity)
                    }
                } else {
                    DispatchQueue.main.async {
                        //placeMarker.map = nil
                        self.mapMarkers[mapPlaceId]?.map = nil
                    }
                    //mapMarkers.removeAll(where: {$0.mapPlaceId == placeMarker.mapPlaceId})
                    self.mapMarkers[mapPlaceId] = nil
                }
        }
    }
    
    private func ifOverlayMarkerTouchesOther(marker: OrbisMapOverlayMarker) -> Bool {
        //let markerExcludingSelfMarker = mapMarkers.filter({$0.mapPlaceId != marker.mapPlaceId})
        var markerExcludingSelfMarker: [OrbisMapOverlayMarker] = []
        
        // Loop
        for (_, mapMarker) in mapMarkers {
            if mapMarker.mapPlaceId != marker.mapPlaceId {
                markerExcludingSelfMarker.append(mapMarker)
            }
        }
        let intersects = markerExcludingSelfMarker.contains(where: {$0.bounds!.intersects(marker.bounds!)})
        return intersects
    }
    
    private func circleOpacity(atZoomRadius radius: Double, touchesOtherCircle touches: Bool, circleSizeCase: OrbisPlaceCircleSizeCase) -> Double {
        guard touches else { return 1 }
        if radius >= OrbisMapZoomRadius.size500.rawValue {
            switch circleSizeCase {
            case .get500:
                return 1
            case .lt500get250:
                return 0.8
            case .lt250get150:
                return 0.6
            case .lt150get100:
                return 0.4
            case .lt100get50:
                return 0.2
            case .lt50get25:
                return 0.1
            case .lt25:
                return 0.1
            }
        }
        else if radius < OrbisMapZoomRadius.size500.rawValue && radius >= OrbisMapZoomRadius.size200.rawValue {
            switch circleSizeCase {
            case .get500:
                return 0.8
            case .lt500get250:
                return 1
            case .lt250get150:
                return 0.8
            case .lt150get100:
                return 0.6
            case .lt100get50:
                return 0.4
            case .lt50get25:
                return 0.2
            case .lt25:
                return 0.1
            }
        }
        else if radius < OrbisMapZoomRadius.size200.rawValue && radius >= OrbisMapZoomRadius.size100.rawValue {
            switch circleSizeCase {
            case .get500:
                return 0.6
            case .lt500get250:
                return 0.8
            case .lt250get150:
                return 1
            case .lt150get100:
                return 0.8
            case .lt100get50:
                return 0.6
            case .lt50get25:
                return 0.4
            case .lt25:
                return 0.2
            }
        }
        else if radius < OrbisMapZoomRadius.size100.rawValue && radius >= OrbisMapZoomRadius.size50.rawValue {
            switch circleSizeCase {
            case .get500:
                return 0.4
            case .lt500get250:
                return 0.6
            case .lt250get150:
                return 0.8
            case .lt150get100:
                return 1
            case .lt100get50:
                return 0.8
            case .lt50get25:
                return 0.6
            case .lt25:
                return 0.4
            }
        }
        else if radius < OrbisMapZoomRadius.size50.rawValue && radius >= OrbisMapZoomRadius.size20.rawValue {
            switch circleSizeCase {
            case .get500:
                return 0.2
            case .lt500get250:
                return 0.4
            case .lt250get150:
                return 0.6
            case .lt150get100:
                return 0.8
            case .lt100get50:
                return 1
            case .lt50get25:
                return 0.8
            case .lt25:
                return 0.6
            }
        }
        else if radius < OrbisMapZoomRadius.size20.rawValue {
            switch circleSizeCase {
            case .get500:
                return 0.1
            case .lt500get250:
                return 0.2
            case .lt250get150:
                return 0.4
            case .lt150get100:
                return 0.6
            case .lt100get50:
                return 0.8
            case .lt50get25:
                return 1
            case .lt25:
                return 0.8
            }
        }
        return 1
    }
    
    private func getPlaceCircleOpacity(forCircle circle: OrbisMapOverlayMarker, withSize size: Double, mapRadius radius: Double) -> Double {
        
        let touches = ifOverlayMarkerTouchesOther(marker: circle)
        if size >= OrbisPlaceSize.size500.rawValue {
            return circleOpacity(atZoomRadius: radius, touchesOtherCircle: touches, circleSizeCase: .get500)
        }
        else if size < OrbisPlaceSize.size500.rawValue && size >= OrbisPlaceSize.size250.rawValue {
            return circleOpacity(atZoomRadius: radius, touchesOtherCircle: touches, circleSizeCase: .lt500get250)
        }
        else if size < OrbisPlaceSize.size250.rawValue && size >= OrbisPlaceSize.size150.rawValue {
            return circleOpacity(atZoomRadius: radius, touchesOtherCircle: touches, circleSizeCase: .lt250get150)
        }
        else if size < OrbisPlaceSize.size150.rawValue && size >= OrbisPlaceSize.size100.rawValue {
            return circleOpacity(atZoomRadius: radius, touchesOtherCircle: touches, circleSizeCase: .lt150get100)
        }
        else if size < OrbisPlaceSize.size100.rawValue && size >= OrbisPlaceSize.size50.rawValue {
            return circleOpacity(atZoomRadius: radius, touchesOtherCircle: touches, circleSizeCase: .lt100get50)
        }
        else if size < OrbisPlaceSize.size50.rawValue && size >= OrbisPlaceSize.size25.rawValue {
            return circleOpacity(atZoomRadius: radius, touchesOtherCircle: touches, circleSizeCase: .lt50get25)
        }
        else if size < OrbisPlaceSize.size25.rawValue {
            return circleOpacity(atZoomRadius: radius, touchesOtherCircle: touches, circleSizeCase: .lt25)
        }
        return 1
    }
    
    func removeActiveGlowOverlay(mapView map: GMSMapView) {
        if activeGlowOverlay != nil {
//            for container in mapMarkerContainers {
//                container.startPulsate()
//            }
            
            // Loop
            //for (_, mapMarkerContainer) in mapMarkerContainers {
                //mapMarkerContainer.startPulsate()
            //}
        }
        activeGlowOverlay?.map = nil
        activeGlowOverlay = nil
        map.selectedMarker = nil
        onMapSelectedMarkerRemoved?()
    }
    
    func addActiveGlowOverlay(forOverlay overlay: OrbisMapOverlayMarker, inMap mapView: GMSMapView) -> OrbisMapOverlayCircle? {
        if let activeGlowOverlay = activeGlowOverlay, activeGlowOverlay.mapPlaceId == overlay.mapPlaceId {
            return activeGlowOverlay
        }
        removeActiveGlowOverlay(mapView: mapView)
        activeGlowOverlay = OrbisMapOverlayCircle(position: overlay.position, radius: overlay.radius * glowRadiusMultiplier)
        activeGlowOverlay?.mapPlaceId = overlay.mapPlaceId
        activeGlowOverlay?.fillColor = overlay.mapPlaceBaseColor.withAlphaComponent(0.25)
        activeGlowOverlay?.strokeColor = .clear
        activeGlowOverlay?.map = mapView
        activeGlowOverlay?.isTappable = false
        return activeGlowOverlay
    }
    
    func getStore(withId key: String) -> OrbisPlace {
        //return mapData.first(where: {$0.placeKey == key})!
        return mapData[key]!
    }
    
    // MARK:- Network Fetch
    
    var timer = Timer()
    
    func removeAllOutOfBoundsData() {
        timer.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false, block: { [weak self] timer in
            guard let self = self else { return }
            guard let mapCenterCoordinates = self.mapCenterCoordinate else { return }
            let mapCenterLoc = CLLocation(latitude: mapCenterCoordinates.latitude, longitude: mapCenterCoordinates.longitude)
            //self.mapData.removeAll(where: {!$0.isWithinVisibleRange(ofDistance: self.mapFetchDistanceInKM * 1000, fromCoordinates: mapCenterLoc)})
            for (key, mapDataItem) in self.mapData {
//                if !mapDataItem.isWithinVisibleRange(ofDistance: self.mapFetchDistanceInKM * 1000, fromCoordinates: mapCenterLoc) {
//                    self.mapData[key] = nil
//                }
                let fixedRadius = self.mapFetchDistanceInKM * 1000
                var visibleRadius = min(fixedRadius, self.mapView.getRadius())
//                visibleRadius = max(visibleRadius, AppValues.mapMinVisibleDistanceInKM * 1000)
                if !mapDataItem.isWithinVisibleRange(mapView: self.mapView, ofDistance: visibleRadius, fromCoordinates: mapCenterLoc) {
                    self.mapData[key] = nil
                }
            }
            self.removeAllUnnecessaryMarkers()
        })
    }
    
    private func removeAllUnnecessaryMarkers() {
//        for marker in mapMarkers {
//            if !mapData.contains(where: {$0.placeKey == marker.mapPlaceId}) {
//                DispatchQueue.main.async {
//                    marker.map = nil
//                }
//                self.mapMarkerContainers.removeAll(where: {$0.marker.mapPlaceId == marker.mapPlaceId})
//                self.mapMarkers.removeAll(where: {$0.mapPlaceId == marker.mapPlaceId})
//            }
//        }
        
        // Loop
        for (mapPlaceId, marker) in mapMarkers {
            if mapData[mapPlaceId] == nil {
                DispatchQueue.main.async {
                    marker.map = nil
                }
                
                self.mapMarkerContainers[mapPlaceId] = nil
                self.mapMarkers[mapPlaceId] = nil
            }
        }
    }
    
    func invalidateAllFetchPlacesNetworkRequests(completion: @escaping responseBlock) {
        self.placesManager.invalidateAllNetworkRequests(completion: completion)
    }
    
    func getPlacesFromServer(inMapView mapView: GMSMapView, for radius: Double, forceRefresh: Bool, completion: @escaping responseBlock) {
        //guard mapMarkers.count < 400 else { return }
        print("+++ getPlacesFromServer")
        DispatchQueue.global(qos: .utility).async {
            [weak self] in
            guard let self = self else { return }
            if forceRefresh {
                self.initializePagination()
                self.placesManager.invalidateAllNetworkRequests { [weak self] _,_ in
                    guard let self = self, let centerCoordinate = self.mapCenterCoordinate else { return }
                    print("+++ fetching dist: \(self.mapFetchDistanceInKM)")
                    self.placesManager.fetchPlaces(location: centerCoordinate, distance: self.mapFetchDistanceInKM, page: self.pageNumber, limit: self.offsetVal) { [weak self] placesData, err in
                        guard let self = self else { return }
                        self.onFirstPageLoadComplete?()
                        if let error = err {
                            completion(nil, error)
                        }
                        else {
                            if let items = placesData as? MapPlacesFetchResult {
                                if (items.location != self.mapCenterCoordinate) {
                                    completion(nil, nil)
                                    return
                                }
                                if items.result.count > 0 {
                                    items.result.forEach { item in
                                        //if self.mapData.contains(where: {$0.placeKey == item.placeKey}) {
                                        //guard let size = item.size, radius / size <= 120 else { return }

                                      //MARK: POLYGON work here you goes with
                                        //let polygon = item.toPolygonPlaceDetails()
                                        
                                       // self.addGroundOverlayBasedOnBounds(for: polygon)
                                        
                                        let placeKey = item.placeKey ?? "Unknown"
                                        if let oldPlace = self.mapData[placeKey] {
                                            //let oldPlace = self.mapData[index]
                                            if item.hasChanged(withRespectToPlace: oldPlace) {
                                                //self.mapData[index] = item
                                                self.mapData[placeKey] = item
                                                self.addStoreToMap(mapView: mapView, orbisPlace: item, isNewlyCreatedPlace: true)
                                            }
                                        } else {
                                            //self.mapData.append(item)
                                            let placeKey = item.placeKey ?? "Unknown"
                                            self.mapData[placeKey] = item
                                            self.addStoreToMap(mapView: mapView, orbisPlace: item, isNewlyCreatedPlace: true)
                                        }
                                    }
                                    if self.pageNumber == 0 {
                                        // update observers for firebase
                                        self.observeRegionDataChanges()
                                    }
                                    self.pageNumber = self.pageNumber + 1
                                    self.hasItemsLastPageReached = false
                                    self.getPlacesFromServer(inMapView: mapView, for: radius, forceRefresh: false, completion: completion)
                                }
                                else {
                                    self.hasItemsLastPageReached = true
                                    // update observers for firebase
                                    self.observeRegionDataChanges()
                                    completion(true, nil)
                                }
                                return
                            }
                            else {
                                completion(nil, nil)
                                return
                            }
                        }
                    }
                }
            }
            else {
                guard let centerCoordinate = self.mapCenterCoordinate else { return }
                self.placesManager.fetchPlaces(location: centerCoordinate, distance: self.mapFetchDistanceInKM, page: self.pageNumber, limit: self.offsetVal) { [weak self] placesData, err in
                    guard let self = self else { return }
                    if let error = err {
                        completion(nil, error)
                    }
                    else {
                        if let items = placesData as? MapPlacesFetchResult {
                            if (items.location != self.mapCenterCoordinate) {
                                completion(nil, nil)
                                return
                            }
                            if items.result.count > 0 {
                                items.result.forEach { item in
                                    //guard let size = item.size, radius / size <= 120 else { return }
                                    
                                    //if self.mapData.contains(where: {$0.placeKey == item.placeKey}) {
                                    let placeKey = item.placeKey ?? "Unknown"
                                    if let oldPlace = self.mapData[placeKey] {
                                        //let oldPlace = self.mapData[index]
                                        if item.hasChanged(withRespectToPlace: oldPlace) {
                                            //self.mapData[index] = item
                                            self.mapData[placeKey] = item
                                            
                                            self.addStoreToMap(mapView: mapView, orbisPlace: item, isNewlyCreatedPlace: true)
                                        }
                                    }
                                    else {
                                        //self.mapData.append(item)
                                        let placeKey = item.placeKey ?? "Unknown"
                                        self.mapData[placeKey] = item
                                        
                                        self.addStoreToMap(mapView: mapView, orbisPlace: item, isNewlyCreatedPlace: true)
                                    }
                                }
                                if self.pageNumber == 0 {
                                    // update observers for firebase
                                    self.observeRegionDataChanges()
                                }
                                self.pageNumber = self.pageNumber + 1
                                self.hasItemsLastPageReached = false
                                self.getPlacesFromServer(inMapView: mapView, for: radius, forceRefresh: false, completion: completion)
                            }
                            else {
                                self.hasItemsLastPageReached = true
                                // update observers for firebase
                                self.observeRegionDataChanges()
                                completion(true, nil)
                                return
                            }
                        }
                        else {
                            completion(nil, nil)
                            return
                        }
                    }
                }
            }
        }
    }
    
    private func observeRegionDataChanges() {
        let newBoundingHashes = getBoundingGeoHashes()
        var toDeleteHashes = [String]()
        for oldHash in self.boundingHashes {
            if !newBoundingHashes.contains(oldHash) {
                toDeleteHashes.append(oldHash)
            }
        }
        self.boundingHashes = newBoundingHashes
        let timeStamp = Date().timeIntervalSince1970 * 1000
        self.boundingHashes.forEach { [weak self] hash in
            guard let self = self else { return }
            guard !self.firebaseObserverHandleMappings.contains(where: {$0.key == hash}) else { return }
            let groupChangeHandle = self.firebaseManager.observeGroupOwnershipValueChange(value: hash, at: timeStamp)
            let groupOwnershipAddHandle = self.firebaseManager.observeGroupOwnershipChildAdd(value: hash, at: timeStamp)
            let placeSizeChangeHandle = self.firebaseManager.observePlaceSizesValueChange(value: hash, at: timeStamp)
            let placeSizeAddHandle = self.firebaseManager.observePlaceSizeChildAdd(value: hash, at: timeStamp)
            self.observerHandles.append(groupChangeHandle)
            self.observerHandles.append(groupOwnershipAddHandle)
            self.observerHandles.append(placeSizeChangeHandle)
            self.observerHandles.append(placeSizeAddHandle)
            let hashHandles = [groupChangeHandle, groupOwnershipAddHandle, placeSizeAddHandle, placeSizeChangeHandle]
            self.firebaseObserverHandleMappings[hash] = hashHandles
        }
        
        toDeleteHashes.forEach { hash in
            guard let existingHandles = self.firebaseObserverHandleMappings[hash] else { return }
            for handle in existingHandles {
                self.firebaseManager.removeObserver(handle: handle)
                self.observerHandles.removeAll(where: {$0 == handle})
            }
        }
        
    }
    
    private func getBoundingGeoHashes() -> [String] {
        guard let coordinate = self.mapCenterCoordinate else { return [] }
        let radiusLimit: Double = firebaseObservableDistanceInMeter
        var boundingHashes = [String]()
        let precision = Precision.custom(value: 4)
        do {
            let centerHash = try Geohash.encode(latitude: coordinate.latitude, longitude: coordinate.longitude, precision: precision)
            boundingHashes.append(centerHash)
            // East Neighbor
            var centerHashEastNeighbor = try Geohash.neighbor(of: centerHash, direction: .east)
            var centerEastNeighborLoc = try Geohash.decode(centerHashEastNeighbor)
            var locCenterEast = CLLocation(latitude: centerEastNeighborLoc.latitude, longitude: centerEastNeighborLoc.longitude)
            var hasEastHashReachedLimit = locCenterEast.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) > radiusLimit
            while !hasEastHashReachedLimit {
                boundingHashes.append(centerHashEastNeighbor)
                centerHashEastNeighbor = try Geohash.neighbor(of: centerHashEastNeighbor, direction: .east)
                centerEastNeighborLoc = try Geohash.decode(centerHashEastNeighbor)
                locCenterEast = CLLocation(latitude: centerEastNeighborLoc.latitude, longitude: centerEastNeighborLoc.longitude)
                hasEastHashReachedLimit = locCenterEast.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) > radiusLimit
            }
            // North Neighbor
            var centerHashNorthNeighbor = try Geohash.neighbor(of: centerHash, direction: .north)
            var centerNorthNeighborLoc = try Geohash.decode(centerHashNorthNeighbor)
            var locCenterNorth = CLLocation(latitude: centerNorthNeighborLoc.latitude, longitude: centerNorthNeighborLoc.longitude)
            var hasNorthHashReachedLimit = locCenterNorth.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) > radiusLimit
            while !hasNorthHashReachedLimit {
                boundingHashes.append(centerHashNorthNeighbor)
                centerHashNorthNeighbor = try Geohash.neighbor(of: centerHashNorthNeighbor, direction: .north)
                centerNorthNeighborLoc = try Geohash.decode(centerHashNorthNeighbor)
                locCenterNorth = CLLocation(latitude: centerNorthNeighborLoc.latitude, longitude: centerNorthNeighborLoc.longitude)
                hasNorthHashReachedLimit = locCenterNorth.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) > radiusLimit
            }
            // NorthEast Neighbor
            var centerHashNorthEastNeighbor = try Geohash.neighbor(of: centerHash, direction: .northEast)
            var centerNorthEastNeighborLoc = try Geohash.decode(centerHashNorthEastNeighbor)
            var locCenterNorthEast = CLLocation(latitude: centerNorthEastNeighborLoc.latitude, longitude: centerNorthEastNeighborLoc.longitude)
            var hasNorthEastHashReachedLimit = locCenterNorthEast.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) > radiusLimit
            while !hasNorthEastHashReachedLimit {
                boundingHashes.append(centerHashNorthEastNeighbor)
                centerHashNorthEastNeighbor = try Geohash.neighbor(of: centerHashNorthEastNeighbor, direction: .northEast)
                centerNorthEastNeighborLoc = try Geohash.decode(centerHashNorthEastNeighbor)
                locCenterNorthEast = CLLocation(latitude: centerNorthEastNeighborLoc.latitude, longitude: centerNorthEastNeighborLoc.longitude)
                hasNorthEastHashReachedLimit = locCenterNorthEast.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) > radiusLimit
            }
            // NorthWest Neighbor
            var centerHashNorthWestNeighbor = try Geohash.neighbor(of: centerHash, direction: .northWest)
            var centerNorthWestNeighborLoc = try Geohash.decode(centerHashNorthWestNeighbor)
            var locCenterNorthWest = CLLocation(latitude: centerNorthWestNeighborLoc.latitude, longitude: centerNorthWestNeighborLoc.longitude)
            var hasNorthWestHashReachedLimit = locCenterNorthWest.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) > radiusLimit
            while !hasNorthWestHashReachedLimit {
                boundingHashes.append(centerHashNorthWestNeighbor)
                centerHashNorthWestNeighbor = try Geohash.neighbor(of: centerHashNorthWestNeighbor, direction: .northWest)
                centerNorthWestNeighborLoc = try Geohash.decode(centerHashNorthWestNeighbor)
                locCenterNorthWest = CLLocation(latitude: centerNorthWestNeighborLoc.latitude, longitude: centerNorthWestNeighborLoc.longitude)
                hasNorthWestHashReachedLimit = locCenterNorthWest.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) > radiusLimit
            }
            // South Neighbor
            var centerHashSouthNeighbor = try Geohash.neighbor(of: centerHash, direction: .south)
            var centerSouthNeighborLoc = try Geohash.decode(centerHashSouthNeighbor)
            var locCenterSouth = CLLocation(latitude: centerSouthNeighborLoc.latitude, longitude: centerSouthNeighborLoc.longitude)
            var hasSouthHashReachedLimit = locCenterSouth.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) > radiusLimit
            while !hasSouthHashReachedLimit {
                boundingHashes.append(centerHashSouthNeighbor)
                centerHashSouthNeighbor = try Geohash.neighbor(of: centerHashSouthNeighbor, direction: .south)
                centerSouthNeighborLoc = try Geohash.decode(centerHashSouthNeighbor)
                locCenterSouth = CLLocation(latitude: centerSouthNeighborLoc.latitude, longitude: centerSouthNeighborLoc.longitude)
                hasSouthHashReachedLimit = locCenterSouth.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) > radiusLimit
            }
            // SouthEast Neighbor
            var centerHashSouthEastNeighbor = try Geohash.neighbor(of: centerHash, direction: .southEast)
            var centerSouthEastNeighborLoc = try Geohash.decode(centerHashSouthEastNeighbor)
            var locCenterSouthEast = CLLocation(latitude: centerSouthEastNeighborLoc.latitude, longitude: centerSouthEastNeighborLoc.longitude)
            var hasSouthEastHashReachedLimit = locCenterSouthEast.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) > radiusLimit
            while !hasSouthEastHashReachedLimit {
                boundingHashes.append(centerHashSouthEastNeighbor)
                centerHashSouthEastNeighbor = try Geohash.neighbor(of: centerHashSouthEastNeighbor, direction: .southEast)
                centerSouthEastNeighborLoc = try Geohash.decode(centerHashSouthEastNeighbor)
                locCenterSouthEast = CLLocation(latitude: centerSouthEastNeighborLoc.latitude, longitude: centerSouthEastNeighborLoc.longitude)
                hasSouthEastHashReachedLimit = locCenterSouthEast.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) > radiusLimit
            }
            // SouthWest Neighbor
            var centerHashSouthWestNeighbor = try Geohash.neighbor(of: centerHash, direction: .southWest)
            var centerSouthWestNeighborLoc = try Geohash.decode(centerHashSouthWestNeighbor)
            var locCenterSouthWest = CLLocation(latitude: centerSouthWestNeighborLoc.latitude, longitude: centerSouthWestNeighborLoc.longitude)
            var hasSouthWestHashReachedLimit = locCenterSouthWest.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) > radiusLimit
            while !hasSouthWestHashReachedLimit {
                boundingHashes.append(centerHashSouthWestNeighbor)
                centerHashSouthWestNeighbor = try Geohash.neighbor(of: centerHashSouthWestNeighbor, direction: .southWest)
                centerSouthWestNeighborLoc = try Geohash.decode(centerHashSouthWestNeighbor)
                locCenterSouthWest = CLLocation(latitude: centerSouthWestNeighborLoc.latitude, longitude: centerSouthWestNeighborLoc.longitude)
                hasSouthWestHashReachedLimit = locCenterSouthWest.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) > radiusLimit
            }
            // West Neighbor
            var centerHashWestNeighbor = try Geohash.neighbor(of: centerHash, direction: .west)
            var centerWestNeighborLoc = try Geohash.decode(centerHashWestNeighbor)
            var locCenterWest = CLLocation(latitude: centerWestNeighborLoc.latitude, longitude: centerWestNeighborLoc.longitude)
            var hasWestHashReachedLimit = locCenterWest.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) > radiusLimit
            while !hasWestHashReachedLimit {
                boundingHashes.append(centerHashWestNeighbor)
                centerHashWestNeighbor = try Geohash.neighbor(of: centerHashWestNeighbor, direction: .west)
                centerWestNeighborLoc = try Geohash.decode(centerHashWestNeighbor)
                locCenterWest = CLLocation(latitude: centerWestNeighborLoc.latitude, longitude: centerWestNeighborLoc.longitude)
                hasWestHashReachedLimit = locCenterWest.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) > radiusLimit
            }
        }
        catch {
            debugPrint("Error in map hash = \(error.localizedDescription)")
        }
        return boundingHashes.uniqued()
    }
    
    private func getAlreadySetImage(forUrl string: String) -> UIImage? {
//        let typeIcons = OrbisMapPlaceIconManager.shared.placeIcons.values
        if let image = mapImageInstances[string] {
            return image
        }
//        guard let _ = mapMarkers.first(where: {$0.icon != nil && $0.imageUrlName == string}) else { return nil }
//        if let marker = mapMarkers.first(where: {$0.imageUrlName == string && !typeIcons.contains($0.icon!)}) {
//            return marker.icon
//        }
        return nil
    }
}

extension MapViewModel: OrbisMapMarkerImageDelegate {
    func didCompleteImageDownload(forUrl urlString: String, image: UIImage, marker: OrbisMapOverlayMarker) {
        //guard mapMarkers.contains(where: {$0.mapPlaceId == marker.mapPlaceId}) else { return }
        guard let _ = mapMarkers[marker.mapPlaceId] else { return }
        debugPrint("Map Image Instances count = \(mapImageInstances.count)")
        if let setImage = self.getAlreadySetImage(forUrl: urlString) {
            DispatchQueue.main.async {
                marker.imageUrlName = urlString
                marker.icon = setImage
            }
        }
        else {
            self.mapImageInstances[urlString] = image
            DispatchQueue.main.async {
                marker.imageUrlName = urlString
                marker.icon = image
            }
        }
    }
}

extension MapViewModel: OrbisMapMarkerCleanupDelegate {
   
    func shouldRemoveMarker(withKey key: String) {
        print("+++ map marker should be removed")
        mapData[key] = nil
        mapMarkers[key] = nil
        mapMarkerContainers[key] = nil
    }
    
}


extension MapViewModel {
    
    func fetchUnreadMessagesCount(completion: @escaping responseBlock) {
        messagesManager.fetchUnreadMessagesCount(completion: completion)
    }
    
    func fetchUnreadNotificationCount(completion: @escaping responseBlock) {
        notificationManager.getUnreadNotificationsCount(completion: completion)
    }
}

extension MapViewModel {
    
    func fetchCenterCoordinatePlaceName(coordinate: CLLocationCoordinate2D) {
        placeNameFetchManager.invalidateAllNetworkRequests { [weak self] _, _ in
            guard let self = self else { return }
            self.placeNameFetchManager.fetchMapCenterAddress(location: coordinate) { [weak self] result, error in
                if let error = error {
                    debugPrint("Error in fetching coordinate place name: \(error.localizedDescription)")
                }
                if let model = result as? MapCenterAddressResponse {
                    self?.centerCoordinatePlaceModel = model
                }
            }
        }
    }
}

//MARK: Polygon section
extension MapViewModel {
    
    private func addGroundOverlayBasedOnBounds(for place: PolygonPlaceDetails) {
        
        print("polygonCreation \(String(describing: place.name)) palindromeKey: \(String(describing: place.palindromeKey))")
        
        print("places count \(String(describing: place.places?.count))")
        
        guard let mapView = mapView, let polygonCenter = place.polygonCenter else { return }
        
        
        let visibleRegion = mapView.projection.visibleRegion()
        
        // Start with a GMSCoordinateBounds using one corner of the visible region
        var bounds = GMSCoordinateBounds(coordinate: visibleRegion.nearLeft, coordinate: visibleRegion.nearRight)

        // Expand bounds to include the other corners
        bounds = bounds.includingCoordinate(visibleRegion.farLeft)
        bounds = bounds.includingCoordinate(visibleRegion.farRight)

        // Now `bounds` is equivalent to `latLngBounds` on Android
        
        print("bounds: \(bounds.debugDescription)" )
        
        
        let size = place.isCircle() ? place.size : CoordinatesUtil.calculatePolygonRadius(coord: place.polygonPoints!)
        var inBounds = false
        
        if !place.isCircle() {
            var i = 0
            while i < place.polygonPoints!.count {
                inBounds = bounds.contains(place.polygonPoints![i].toCLLocationCoordinate2D())
                if inBounds { break }
                i += 100
            }
        } else {
            if let coordinates = place.coordinates {
                inBounds = bounds.contains(coordinates.toCLLocationCoordinate2D())
            }
        }
        
        let isVisibleSizeCriteriaMet = (getMapVisibleRadius() / size!) < 80
        
        print("inBounds : \(inBounds)")
        
        if isVisibleSizeCriteriaMet {
            if inBounds {
                //if !willBePlaceOverlays.contains(where: { $0 == place }){
                    willBePlaceOverlays.append(place)
                    createGroundOverlayAndPolygon(for: place)
                    // Optionally, you can precompute place image drawables here if needed
               // }
                
            } else {
               // let timeSinceLastMovedCamera = Int(Date().timeIntervalSince1970) - lastOverlayUpdatedTime
                let timeSinceLastMovedCamera = Int(Date().timeIntervalSince1970) - Int(lastOverlayUpdatedTime)
                if timeSinceLastMovedCamera >= 2 {
                    removeGroundOverlayAndPolygon(for: place)
                }
            }
        } else {
            removeGroundOverlayAndPolygon(for: place)
        }
    }
    
    func getMapVisibleRadius() -> Double {
        if let mapView = mapView {
            let visibleRegion = mapView.projection.visibleRegion()
            let farLeft = visibleRegion.farLeft
            let nearRight = visibleRegion.nearRight
            
            let diagonalDistance = GMSGeometryDistance(CLLocationCoordinate2D(latitude: farLeft.latitude, longitude: farLeft.longitude),
                                                       CLLocationCoordinate2D(latitude: nearRight.latitude, longitude: nearRight.longitude))
            
            return diagonalDistance / 2.0
        }
        return 0.0
    }
    

    func createGroundOverlayAndPolygon(for placeDetails: PolygonPlaceDetails) {
        var mutablePlaceDetails = placeDetails
        mutablePlaceDetails.computeSize()
        let diameter = CGFloat(placeDetails.size! * 2.0)
        
        let centerLatLng = CLLocationCoordinate2D(latitude: placeDetails.polygonCenter?.latitude ?? 0.0,
                                                  longitude: placeDetails.polygonCenter?.longitude ?? 0.0)

        var newPolygon: GMSPolygon?
        var polygonAnimation: UIViewPropertyAnimator?
        
        if !placeDetails.isCircle() {
            print("Calculating Polygon for \(String(describing: placeDetails.name))")
            let polygonPoints = CoordinatesUtil.coordinatesToLatLng(placeDetails.polygonPoints!)
            var smoothedLatLng = CoordinatesUtil.chaikin(arr: polygonPoints, num: 2)
            smoothedLatLng = CoordinatesUtil.bspline(poly: &smoothedLatLng)

            let polygonPath = GMSMutablePath()
            smoothedLatLng.forEach { polygonPath.add($0) }
            
            newPolygon = GMSPolygon(path: polygonPath)
            newPolygon?.strokeWidth = 0
            newPolygon?.strokeColor = placeDetails.getPlaceColor()
            newPolygon?.zIndex = Int32(900 - placeDetails.size!)
            newPolygon?.fillColor = isGroundOverlayClicked2 ? placeDetails.getTransparentColor() : placeDetails.getNormalColor()
            newPolygon?.isTappable = !isGroundOverlayClicked2
            newPolygon?.map = mapView // Your GMSMapView instance
        }

//        let iconGenerator = IconGenerator()
//        let isCheckIn = placeDetails.places.contains(where: { $0.placeKey == lastPlaceCreatedKey })
//
//        func onResourceLoaded(_ image: UIImage) {
//            let overlay = GMSGroundOverlay(position: centerLatLng, icon: image, zoomLevel: 15) // Adjust size if needed
//            overlay.zIndex = Int32(1000 - placeDetails.size)
//            overlay.isTappable = !isGroundOverlayClicked2
//            overlay.map = mapView // Your GMSMapView instance
//
//            newPolygon?.map = overlay.map
//            if isCheckIn {
//                handleCheckInSituation(overlay)
//            }
//
//            let animation = createPulseAnimation(for: overlay, placeDetails: placeDetails)
//            placeDetails.animator = animation
//            animation?.startAnimation()
//
//            placeOverlays[overlay] = placeDetails
//        }
//
//        storageRef.downloadURL { url, error in
//            guard let imageUrl = url else {
//                onResourceLoadFailed()
//                return
//            }
//
//            let imageView = UIImageView()
//            imageView.sd_setImage(with: imageUrl) { image, error, cacheType, url in
//                guard let image = image else {
//                    onResourceLoadFailed()
//                    return
//                }
//                onResourceLoaded(image)
//            }
//        }
    }
    
    private func removeGroundOverlayAndPolygon(for place: PolygonPlaceDetails) {
//        for (overlayCircle, overlayPlace) in placeOverlays {
//            if overlayPlace.placeKey == place.placeKey {
//                // Remove associated polygon if it exists
//                if let polygonAssociated = associatedPolygons[overlayCircle] {
//                    polygonAssociated.map = nil // Remove polygon from map
//
//                }
//                overlayCircle.map = nil // Remove overlay from map
//                placeOverlays.removeValue(forKey: overlayCircle)
//                willBePlaceOverlays.removeAll { $0.placeKey == place.placeKey } // Remove all matching overlays
//                break
//            }
//        }
    }
    
/*
    func transformOverlayAndPolygonWithAnimation(fromPlace: PolygonPlaceDetails, toPlace: PolygonPlaceDetails) {
        fromPlace.cancelAnimation()
        fromPlace.computeSize()
        toPlace.computeSize()

        // Convert points from coordinates
        var fromPoints = CoordinatesUtil.coordinatesToLatLng(fromPlace.polygonPoints)
        var smoothedInitialPoints = CoordinatesUtil.chaikin(points: fromPoints, iterations: 2)
        smoothedInitialPoints = CoordinatesUtil.bspline(points: smoothedInitialPoints)
        
        var toPoints = CoordinatesUtil.coordinatesToLatLng(toPlace.polygonPoints)
        var smoothedEndingPoints = CoordinatesUtil.chaikin(points: toPoints, iterations: 2)
        smoothedEndingPoints = CoordinatesUtil.bspline(points: smoothedEndingPoints)

        smoothedInitialPoints = CoordinatesUtil.normalizePoints(smoothedInitialPoints, targetSize: smoothedEndingPoints.count)
        smoothedEndingPoints = CoordinatesUtil.normalizePoints(smoothedEndingPoints, targetSize: smoothedInitialPoints.count)
        
        smoothedInitialPoints = CoordinatesUtil.normalizeOrientation(smoothedInitialPoints)
        smoothedEndingPoints = CoordinatesUtil.normalizeOrientation(smoothedEndingPoints)

        let (initialRotated, endingRotated) = CoordinatesUtil.rotatePoints(initial: smoothedInitialPoints, target: smoothedEndingPoints)

        guard let groundOverlay = findOverlay(for: fromPlace) else { return }
        var polygon = associatedPolygons[groundOverlay]

        if polygon == nil {
            let path = GMSMutablePath()
            smoothedInitialPoints.forEach { point in
                path.add(CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
            }
            let polygonOptions = GMSPolygon()
            polygonOptions.path = path
            polygonOptions.strokeWidth = 0
            polygonOptions.strokeColor = fromPlace.getPlaceColor()
            polygonOptions.fillColor = fromPlace.getNormalColor()
            polygon = polygonOptions
            polygon?.map = mapView
        }

        // Animator for interpolating between polygons
        let animator = UIViewPropertyAnimator(duration: 1.5, curve: .linear) {
            for t in stride(from: 0.0, to: 1.0, by: 0.01) {
                let intermediatePoints = CoordinatesUtil.interpolatePoints(from: initialRotated, to: endingRotated, t: CGFloat(t))
                let path = GMSMutablePath()
                intermediatePoints.forEach { point in
                    path.add(CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
                }
                polygon?.path = path
            }
        }
        animator.startAnimation()

        // Additional transformation for the ground overlay
        if toPlace.isCircle() {
            polygon?.map = nil
        }

        associatedPolygons[groundOverlay] = polygon

        // Animation for center movement and pulsing effect
        if let centerMoveAnim = AnimationsUtil.createMovingCenterAnimation(groundOverlay: groundOverlay, toPlace: toPlace) {
            centerMoveAnim.start()
        }

        if let pulseAnim = AnimationsUtil.createPulseAnimation(groundOverlay: groundOverlay, toPlace: toPlace) {
            toPlace.animator = pulseAnim
            pulseAnim.start(afterDelay: 0.4)
        }

        placeOverlays[groundOverlay] = toPlace
        if let polygon = polygon {
            associatedOverlays[polygon] = groundOverlay
        }
    }
 */
    
    
    func getPlacesFromServer1(inMapView mapView: GMSMapView, for radius: Double, forceRefresh: Bool, completion: @escaping responseBlock) {
        
        //guard mapMarkers.count < 400 else { return }
        print("+++ getPlacesFromServer1")
        DispatchQueue.global(qos: .utility).async {
            [weak self] in
            guard let self = self else { return }
            if forceRefresh {
                self.initializePagination()
                self.placesManager.invalidateAllNetworkRequests { [weak self] _,_ in
                    guard let self = self, let centerCoordinate = self.mapCenterCoordinate else { return }
                    print("+++ fetching dist: \(self.mapFetchDistanceInKM)")
                    self.placesManager.fetchPlacesPolygon(location: centerCoordinate, distance: self.mapFetchDistanceInKM, page: self.pageNumber, limit: self.offsetVal) { [weak self] placesData, err in
                        guard let self = self else { return }
                        self.onFirstPageLoadComplete?()
                        if let error = err {
                            completion(nil, error)
                        }
                        else {
                            if let items = placesData as? MapPlacesFetchResultPolygon {
                                if (items.location != self.mapCenterCoordinate) {
                                    completion(nil, nil)
                                    return
                                }
                                if items.result.count > 0 {
                                    items.result.forEach { item in
                                        //if self.mapData.contains(where: {$0.placeKey == item.placeKey}) {
                                        //guard let size = item.size, radius / size <= 120 else { return }

                                        //MARK: polygon work goes here
                                        //self.addGroundOverlayBasedOnBounds(for: item)
                                        
                                        //TODO: need to adjust this later
                                        self.drawPolygon(on: mapView, orbisPlace: item)
                                        
                                        
                                        let placeKey = item.placeKey ?? "Unknown"
                                        if let oldPlace = self.mapData[placeKey] {
                                            
//                                            if item.hasChanged(withRespectToPlace: oldPlace) {
//                                                //self.mapData[index] = item
//                                                self.mapData[placeKey] = item
//                                                self.addStoreToMap(mapView: mapView, orbisPlace: item, isNewlyCreatedPlace: true)
//                                            }
                                        } else {
                                            
                                            let placeKey = item.placeKey ?? "Unknown"
                                            //self.mapData[placeKey] = item
                                           // self.addStoreToMap(mapView: mapView, orbisPlace: item, isNewlyCreatedPlace: true)
                                        }
                                    }
                                    if self.pageNumber == 0 {
                                        // update observers for firebase
                                        self.observeRegionDataChanges()
                                    }
                                    self.pageNumber = self.pageNumber + 1
                                    self.hasItemsLastPageReached = false
                                    self.getPlacesFromServer1(inMapView: mapView, for: radius, forceRefresh: false, completion: completion)
                                }
                                else {
                                    self.hasItemsLastPageReached = true
                                    // update observers for firebase
                                    self.observeRegionDataChanges()
                                    completion(true, nil)
                                }
                                return
                            }
                            else {
                                completion(nil, nil)
                                return
                            }
                        }
                    }
                }
            }
            else {
                guard let centerCoordinate = self.mapCenterCoordinate else { return }
                self.placesManager.fetchPlaces(location: centerCoordinate, distance: self.mapFetchDistanceInKM, page: self.pageNumber, limit: self.offsetVal) { [weak self] placesData, err in
                    guard let self = self else { return }
                    if let error = err {
                        completion(nil, error)
                    }
                    else {
                        if let items = placesData as? MapPlacesFetchResultPolygon {
                            if (items.location != self.mapCenterCoordinate) {
                                completion(nil, nil)
                                return
                            }
                            if items.result.count > 0 {
                                items.result.forEach { item in
                                    //guard let size = item.size, radius / size <= 120 else { return }
                                    
                                    //if self.mapData.contains(where: {$0.placeKey == item.placeKey}) {
                                    let placeKey = item.placeKey ?? "Unknown"
                                    if let oldPlace = self.mapData[placeKey] {
                                        
//                                        if item.hasChanged(withRespectToPlace: oldPlace) {
//
//                                            self.mapData[placeKey] = item
//                                            
//                                            self.addStoreToMap(mapView: mapView, orbisPlace: item, isNewlyCreatedPlace: true)
//                                        }
                                    }
                                    else {

//                                        let placeKey = item.placeKey ?? "Unknown"
//                                        self.mapData1[placeKey] = item
                                        
                                        //self.addStoreToMap(mapView: mapView, orbisPlace: item, isNewlyCreatedPlace: true)
                                    }
                                }
                                if self.pageNumber == 0 {
                                    // update observers for firebase
                                    self.observeRegionDataChanges()
                                }
                                self.pageNumber = self.pageNumber + 1
                                self.hasItemsLastPageReached = false
                                self.getPlacesFromServer1(inMapView: mapView, for: radius, forceRefresh: false, completion: completion)
                            }
                            else {
                                self.hasItemsLastPageReached = true
                                // update observers for firebase
                                self.observeRegionDataChanges()
                                completion(true, nil)
                                return
                            }
                        }
                        else {
                            completion(nil, nil)
                            return
                        }
                    }
                }
            }
        }
    }
    
    
    func coordinates(from polygonPoints: [Coordinates]) -> [CLLocationCoordinate2D] {
        return polygonPoints.map { coord in
            return CLLocationCoordinate2D(latitude: coord.latitude!, longitude: coord.longitude!)
        }
    }
    
    func drawPolygon(on mapView: GMSMapView, orbisPlace: PolygonPlaceDetails) {
        guard let polygonPoints = orbisPlace.polygonPoints else {
            print("Debug check here and return")
            return
        }
        //self.mapView2 = mapView
        
        let path = GMSMutablePath()
        let coordinates = coordinates(from: polygonPoints)
        for coordinate in coordinates {
            if orbisPlace.places!.count > 1 {
                path.add(coordinate)
            }
        }

        let polygon = GMSPolygon(path: path)
        //polygon.strokeColor = UIColor.hexStringToUIColor(hex: orbisPlace.dominantGroup!.strokeColorHex!)
        //polygon.strokeWidth = 2
        
        let placeColor = UIColor.hexStringToUIColor(hex: orbisPlace.dominantGroup!.strokeColorHex!)
        let alpha = placeColor.cgColor.alpha
        let normalColor = UIColor(
            red: placeColor.cgColor.components?[0] ?? 0,
            green: placeColor.cgColor.components?[1] ?? 0,
            blue: placeColor.cgColor.components?[2] ?? 0,
            alpha: alpha * 0.35
        )
        
       // polygon.fillColor = normalColor
        
        polygon.fillColor = normalColor.withAlphaComponent(0.5)
        
        polygon.map = mapView
        
//        if let placeKey = orbisPlace.placeKey {
//            polygons[placeKey] = polygon
//            //associatedPolygons[customMarker] = polygon
//        }
        
        if let placeKey = orbisPlace.placeKey {
            polygons[placeKey] = polygon
            visiblePolygonPlacesByKey[placeKey] = orbisPlace
            print("Debug - stored polygon: \(orbisPlace.name ?? "No Name")")
            print("Debug - polygons count after store: \(polygons.count)")
        }
        
        
        
        
        print("21212 here")
        isAnimatingPolygon = true
        animatePolygonScaling(polygon: polygon, coordinates: coordinates)

    }
    
    
    func nearbyTribeForMapCenter(
        _ coordinate: CLLocationCoordinate2D,
        bufferMeters: CLLocationDistance = 250
    ) -> PolygonPlaceDetails? {
        
        
        print("Debug - polygons count: \(polygons.count)")
        print("Debug - visiblePolygonPlacesByKey count: \(visiblePolygonPlacesByKey.count)")
        print("Debug - checking center: \(coordinate)")

        for (placeKey, polygon) in polygons {
            guard let path = polygon.path else { continue }

            if GMSGeometryContainsLocation(coordinate, path, true) {
                return visiblePolygonPlacesByKey[placeKey]
            }

            for index in 0..<path.count() {
                let start = path.coordinate(at: index)
                let end = path.coordinate(at: (index + 1) % path.count())

                let distance = GMSGeometryDistance(
                    coordinate,
                    nearestPointOnSegment(coordinate, start, end)
                )

                if distance <= bufferMeters {
                    return visiblePolygonPlacesByKey[placeKey]
                }
            }
        }

        return nil
    }
    
    private func nearestPointOnSegment(
        _ point: CLLocationCoordinate2D,
        _ start: CLLocationCoordinate2D,
        _ end: CLLocationCoordinate2D
    ) -> CLLocationCoordinate2D {

        let px = point.longitude
        let py = point.latitude
        let ax = start.longitude
        let ay = start.latitude
        let bx = end.longitude
        let by = end.latitude

        let dx = bx - ax
        let dy = by - ay

        if dx == 0 && dy == 0 {
            return start
        }

        let t = max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))

        return CLLocationCoordinate2D(
            latitude: ay + t * dy,
            longitude: ax + t * dx
        )
    }

    
    // Poligonun animasyonla genişlemesi (scale animasyonu)
    func animatePolygonScaling(polygon: GMSPolygon, coordinates: [CLLocationCoordinate2D]) {
        let initialScaleFactor: Double = 0.3 // Başlangıç ölçeği
        let finalScaleFactor: Double = 1.0 // Nihai ölçek
        let scaleSteps: Double = 0.05 // Her adımda büyüme miktarı
        
        var currentScale = initialScaleFactor
        let centroid = CoordinatesUtil.calculateCentroid(points: coordinates) // Poligonun merkezi
        let path = GMSMutablePath()
        
        // Timer ile adım adım genişleme
        scaleAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if currentScale <= finalScaleFactor {
                path.removeAllCoordinates() // Mevcut yolu temizle
                
                // Her noktayı, merkezden itibaren "scale" ederek yeniden hesaplıyoruz
                for coordinate in coordinates {
                    let scaledCoordinate = CoordinatesUtil.scaleCoordinate(from: centroid, to: coordinate, scale: currentScale) //self.scaleCoordinate(from: centroid, to: coordinate, scale: currentScale)
                    path.add(scaledCoordinate)
                }
                
                // Poligonun yeni halini ayarla
                polygon.path = path
                
                // Ölçeği artır
                currentScale += scaleSteps
            } else {
                // Animasyon tamamlandı, zamanlayıcıyı durdur
                timer.invalidate()
                self.scaleAnimationTimer = nil // Zamanlayıcıyı sıfırlıyoruz
                self.isAnimatingPolygon = false // Animasyon tamamlandı, bayrağı sıfırlıyoruz
            }
        }
    }
    
    
}
