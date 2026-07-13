//
//  PlaceHeaderCellViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 03/04/2021.
//

import Foundation
import UIKit
import GoogleMaps

class PlaceHeaderCellViewModel {
    let place: OrbisPlace!
    var description: String!
    var mapMarkers: [OrbisMapOverlayMarker] = []
    var mapMarkerContainers = [OrbisMarkerContainer]()
    
    private let formatter = ISOCommonFormatter.shared
    
    private let markerBorderInMeter: CLLocationDistance = 30
    
    struct MarkerRadiusInMeter {
        static let big = 200
        static let small = 200
    }

    init(place: OrbisPlace, description: String) {
        self.place = place
        self.description = description
        resetMapData()
    }
    
    var name: String {
        return place.name ?? ""
    }
    
    var hasUserRated: Bool {
        return (place.userRate != nil)
    }
    
    var userRating: String {
        if let userRating = place.userRate {
            return userRating.roundedStringWithoutZeroFraction(toPlaces: 1)
        }
        return ""
    }
    
    var starRating: Double {
        return place.averageRate ?? 0
    }
    
    var avgRating: String {
        if let avgRating = place.averageRate {
            return avgRating.roundedStringWithoutZeroFraction(toPlaces: 1)
        }
        return ""
    }
    
    var totalRatingCount: String {
        if let totalRating = place.countRates {
            return "(\(Double(totalRating).formattedForLargeNumber(toDecimal: 1)))"
        }
        return ""
    }
    
    var isFollowing: Bool {
        return place.isFollowing
    }
    
    var placeIcon: UIImage? {
        return place.placeType.correspondingImage()
    }
    
    var baseColor: UIColor {
        if let strokeColor = place.placeDominantGroup?.strokeColorHexString {
            return UIColor.hexStringToUIColor(hex: strokeColor)
        }
        return place.placeDominantGroup?.baseColor ?? .clear
    }
    
    
    func resetMapData() {
        mapMarkers = []
        mapMarkerContainers = []
    }
    
    func addPlaceToMap(mapView: GMSMapView, orbisPlace: OrbisPlace) {
        let placeSize = orbisPlace.calculatedSize(with: formatter)
        let clDistance = CLLocationDistance(200)
        let coordinate = CLLocationCoordinate2D(latitude: orbisPlace.coordinates?.latitude ?? 0, longitude: orbisPlace.coordinates?.longitude ?? 0)
        let topLeftCoordinate = CLHelper.coordinate(from: coordinate, distance: -clDistance)
        let bottomRightCoordinate = CLHelper.coordinate(from: coordinate, distance: clDistance)
        let circleZIndex = Int32(1000 - placeSize)
        
        var color = UIColor(named: AppColors.appBlue.rawValue)
        if let colorHex = orbisPlace.placeDominantGroup?.strokeColorHexString {
            color = UIColor.hexStringToUIColor(hex: colorHex)
        }
        
        let customMarker = OrbisMapOverlayMarker(bounds: GMSCoordinateBounds(coordinate: topLeftCoordinate, coordinate: bottomRightCoordinate), icon: nil, radius: clDistance)
        customMarker.placeCoordinate = coordinate
        customMarker.mapPlaceBaseColor = color
        customMarker.mapPlaceId = orbisPlace.placeKey
        customMarker.position = CLLocationCoordinate2D(latitude: orbisPlace.coordinates?.latitude ?? 0, longitude: orbisPlace.coordinates?.longitude ?? 0)
        
        customMarker.opacity = 1
        customMarker.fixedOpacity = 1
        customMarker.isTappable = true
        mapMarkers.append(customMarker)
        let markerView = PlaceMarkerView(image: orbisPlace.placeType.correspondingImage()!, bgColor: .white, size: CGSize(width: 100, height: 100), widthMultiplier: 0.6, isWidthFixed: true)
        let placeholderImage = UIImage(view: markerView).makeRoundImg(with: color!, borderWidth: 5.toCGFloat)
        customMarker.icon = placeholderImage
        
        let markerContainer = OrbisMarkerContainer(marker: customMarker,
                                                   inMap: mapView,
                                                   isNewlyCreatedPlace: false)
        
        DispatchQueue.main.async {
            customMarker.zIndex = circleZIndex
            customMarker.map = mapView
        }
        if let placeImageName = orbisPlace.imageName {
            markerContainer.setPalceDetailProfilePicture(withUrl: placeImageName, placeholder: placeholderImage!)
        }
        mapMarkerContainers.append(markerContainer)
    }
    
    func getMarkerOverlay(at coordinate: CLLocationCoordinate2D) -> OrbisMapOverlayMarker? {
        return mapMarkers.first(where: {($0.position.latitude == coordinate.latitude) && ($0.position.longitude == coordinate.longitude)})
    }
//
//    func getSelectedMarker(at coordinate: CLLocationCoordinate2D) -> GMSMarker? {
//        return mapHiddenMarkers.first(where: {($0.position.latitude == coordinate.latitude) && ($0.position.longitude == coordinate.longitude)})
//    }
}
