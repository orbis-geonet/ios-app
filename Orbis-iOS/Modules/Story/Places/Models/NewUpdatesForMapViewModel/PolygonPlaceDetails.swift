//
//  PolygonPlaceDetails.swift
//  Orbis-iOS
//
//  Created by Kamran on 29/10/2024.
//


import Foundation
import UIKit
import CoreLocation
import GoogleMaps

struct PolygonPlaceDetails:Equatable, Hashable, Codable {
    var coordinates: Coordinates?
    var name: String?
    var placeKey: String?
    var palindromeKey: String?
    var type: String?
    var source: String?
    var address: String?
    var description: String?
    var imageName: String?
    var lastCheckInTimestamp: String?
    var lastSizeChangeTimestamp: String?
    var dominantGroupKey: String?
    var size: Double?
    var previousSize: Double?
    var dominantGroup: GroupDetails?
    var competingGroups: [GroupDetails]?
    var following: Bool?
    var website: String?
    var phone: String?
    var averageRate: Double?
    var totalRate: Double?
    var countRates: Int?
    var userRate: Double?
    var canEdit: Bool?
    var workingHours: [WorkingHoursModel]?
    var places: [PolygonPlaceDetails]?
    var polygonPoints: [Coordinates]?
    var polygonCenter: Coordinates?
    var touch: Bool = false
    var sizeCalculated: Bool = false
    var isFocusSelected: Bool = false
    var animator: UIViewPropertyAnimator? = nil  // Swift alternative to ValueAnimator
    
    // Coding keys for encoding and decoding
        enum CodingKeys: String, CodingKey {
            case coordinates, name, placeKey, palindromeKey, type, source, address, description, imageName
            case lastCheckInTimestamp, dominantGroupKey, size, previousSize, dominantGroup, competingGroups
            case following, website, phone, averageRate, totalRate, countRates, userRate, canEdit, workingHours
            case places, polygonPoints, polygonCenter
        }
    
    static func ==(lhs: PolygonPlaceDetails, rhs: PolygonPlaceDetails) -> Bool {
           return lhs.palindromeKey == rhs.palindromeKey &&
                  lhs.polygonCenter == rhs.polygonCenter &&
                  lhs.coordinates == rhs.coordinates &&
                  lhs.size == rhs.size
           // Add more conditions if other properties should be considered
       }
    
    var placeType: OrbisPlaceType {
        return OrbisPlaceType(rawValue: type ?? "") ?? .location
    }

    // Computed property for place color
    func getPlaceColor() -> UIColor {
        return UIColor(hexString: dominantGroup?.strokeColorHex ?? "#FFFFFF")
    }

    // Normal color with 35% transparency
    func getNormalColor() -> UIColor {
        return getPlaceColor().withAlphaComponent(0.35)
    }

    // Transparent color with 5% transparency
    func getTransparentColor() -> UIColor {
        return getPlaceColor().withAlphaComponent(0.05)
    }

    // Check if it represents a circle (single place inside)
    func isCircle() -> Bool {
        return places?.count == 1
    }

    // Function to compute the size
    mutating func computeSize() {
        guard !sizeCalculated else { return }
        
        if isCircle() {
            size = CoordinatesUtil.calculateCircleRadius(polygonPoints: polygonPoints!.toCLLocationCoordinate2DArray())
        } else if let polygonCenter = polygonCenter {
            let centerLocation = CLLocationCoordinate2D(latitude: polygonCenter.latitude!, longitude: polygonCenter.longitude!)
            let polygonLocations = CoordinatesUtil.coordinatesToLatLng(polygonPoints!)
            //size = CoordinatesUtil.calculateShortestDistance(from: polygonLocations, to: centerLocation)
            size = CoordinatesUtil.calculateShortestDistance(polygonPoints: polygonLocations, center: centerLocation)
        }
        sizeCalculated = true
    }

    // Function to cancel animation
    func cancelAnimation() {
        animator?.stopAnimation(true)
    }
    
    mutating func setFollowing(value: Bool) {
        self.following = value
    }
    
    
}

// Helper model structs
struct Coordinates: Codable, Equatable, Hashable {
    let latitude: Double?
    let longitude: Double?
    
    func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude!, longitude: self.longitude!)
       }
}

struct WorkingHoursModel: Codable, Hashable {
    let day: String
    let time: String
    
    init(day: String = "", time: String = "") {
        self.day = day
        self.time = time
    }
}

extension WorkingHoursModel {
    func toOrbisPlaceWorkingHours() -> OrbisPlaceWorkingHours {
        return OrbisPlaceWorkingHours(day: self.day, time: self.time)
    }
}

// Utility functions for color conversion and size calculation
extension UIColor {
    convenience init(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex.hasPrefix("#") {
            hex.remove(at: hex.startIndex)
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)
        
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    convenience init(hexString: String, alpha:CGFloat?) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex.hasPrefix("#") {
            hex.remove(at: hex.startIndex)
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)
        
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha:alpha ?? 1.0)
    }
}

typealias PolygonPlacesDetails = [PolygonPlaceDetails]

extension PolygonPlacesDetails {
    
    func removingInvalidMapPlaces(with formatter: ISO8601DateFormatter) -> PolygonPlacesDetails {
        return self.filter({$0.calculatedSize(with: formatter) > 0})
    }

}

extension PolygonPlaceDetails {
    
    
    func calculatedSize(with formatter: ISO8601DateFormatter) -> Double {
        
        let lastSizeChangeTimestamp = ""
        
        guard let lastCheckinTime = Date.fromString(string: lastSizeChangeTimestamp ?? "", with: formatter), let lastSize = self.previousSize else {
            return self.previousSize ?? 0
        }
        let elapsedTime = abs(lastCheckinTime.timeIntervalSince1970 - Date().timeIntervalSince1970) * 1000 //milliseconds
        var placeSize: Double = lastSize
        if (elapsedTime < AppValues.DateTime.millisecondsInDay && placeSize >= 500) {
          placeSize = (placeSize - 500) * ((AppValues.DateTime.millisecondsInDay - elapsedTime) / AppValues.DateTime.millisecondsInDay) + 500
        } else if (placeSize >= 500) {
          placeSize = 500 * (AppValues.DateTime.millisecondsinYear - elapsedTime) / AppValues.DateTime.millisecondsinYear
        } else {
          placeSize = placeSize * (AppValues.DateTime.millisecondsinYear - elapsedTime) / AppValues.DateTime.millisecondsinYear
        }
        if (placeSize < 0) { placeSize = 0.0 }
        return placeSize
    }
     
    
    func hasChanged(withRespectToPlace place: PolygonPlaceDetails) -> Bool {
        guard place.placeKey == placeKey else { return false }
        let hasCoordinatesChanged = (coordinates?.latitude != place.coordinates?.latitude) || (coordinates?.longitude != place.coordinates?.longitude)
        let hasLastSizeChanged = previousSize != place.previousSize

        let hasLastTimeStampChanged = (self.lastCheckInTimestamp != place.lastCheckInTimestamp) || ( self.lastSizeChangeTimestamp != place.lastSizeChangeTimestamp)
        
        let dominantGroup = self.dominantGroup
        let hasDominantGroupChanged = dominantGroup?.groupKey != place.dominantGroup?.groupKey
        let hasDominantGroupPicChanged = dominantGroup?.imageName != place.dominantGroup?.imageName
        let hasDominantGroupNameChanged = dominantGroup?.name != place.dominantGroup?.name
        let hasDominantGroupColorChanged = (dominantGroup?.colorIndex != place.dominantGroup?.colorIndex) || (dominantGroup?.strokeColorHex != place.dominantGroup?.strokeColorHex)
        
        let placeParamChanged = hasCoordinatesChanged || hasLastSizeChanged || hasLastTimeStampChanged
        let groupParamChanged = hasDominantGroupChanged || hasDominantGroupPicChanged || hasDominantGroupNameChanged || hasDominantGroupColorChanged
        return placeParamChanged || groupParamChanged
    }
    
    func isWithinVisibleRange(mapView: GMSMapView, ofDistance radius: Double, fromCoordinates coordinates: CLLocation) -> Bool {
        guard let lat = self.coordinates?.latitude, let long = self.coordinates?.longitude else { return false}
        let placeLoc = CLLocation(latitude: lat, longitude: long)
        return isWithinVisibleRegion(mapView: mapView) && (placeLoc.distance(from: coordinates) <= radius)
    }
    
    private func isWithinVisibleRegion(mapView: GMSMapView) -> Bool {
        guard let lat = self.coordinates?.latitude, let long = self.coordinates?.longitude else { return false}
        let region = mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(region: region)
        let placeLoc = CLLocation(latitude: lat, longitude: long)
        return bounds.contains(placeLoc.coordinate)
    }
    
    func lastCheckinDate(with formatter: ISO8601DateFormatter) -> Date {
        Date.fromString(string: lastCheckInTimestamp ?? "", with: formatter) ?? Date().addingTimeInterval(-100_000)
    }
    
}

//MARK: toOrbisPlace
extension PolygonPlaceDetails {
    func toOrbisPlace() -> OrbisPlace {
        
        var customCoordinate : OrbisLocationModel?
        if let coordinates = coordinates {
            let orbisLocationModel = OrbisLocationModel()
            orbisLocationModel.latitude = coordinates.latitude
            orbisLocationModel.longitude = coordinates.longitude
            customCoordinate = orbisLocationModel
        } else {
            customCoordinate = nil
        }
        
        return OrbisPlace(
            coordinates: customCoordinate,
            name: self.name,
            placeKey: self.placeKey,
            imageName: self.imageName,
            type: self.type,
            userCreatedKey: nil, // Not available in PolygonPlaceDetails
            source: self.source,
            address: self.address,
            description: self.description,
            categoryKey: nil, // Not available in PolygonPlaceDetails
            cityKey: nil, // Not available in PolygonPlaceDetails
            countryKey: nil, // Not available in PolygonPlaceDetails
            phone: self.phone,
            website: self.website,
            averageRate: self.averageRate,
            totalRate: self.totalRate,
            countRates: self.countRates,
            userRate: self.userRate,
            lastCheckInTimestamp: self.lastCheckInTimestamp,
            lastSizeChangeTimestamp: self.lastSizeChangeTimestamp,
            dominantGroupKey: self.dominantGroupKey,
            creationServerTimestamp: nil, // Not available in PolygonPlaceDetails
            timestamp: nil, // Not available in PolygonPlaceDetails
            groupCreatedKey: nil, // Not available in PolygonPlaceDetails
            dominantGroup: self.dominantGroup?.toGroup(),
            competingGroups: self.competingGroups?.map { $0.toGroup() },
            googlePlaceId: nil, // Not available in PolygonPlaceDetails
            size: self.size,
            lastSize: self.previousSize,
            following: self.following,
            workingHours: self.workingHours?.map { $0.toOrbisPlaceWorkingHours() },
            canEdit: self.canEdit,
            places: self.places,
            checkInPolygonCoordinateKey: nil, // Not available in PolygonPlaceDetails
            previousSize: self.previousSize,
            palindromeKey: self.palindromeKey,
            polygonPoints: self.polygonPoints,
            polygonCenter: self.polygonCenter,
            touch: self.touch,
            sizeCalculated: self.sizeCalculated,
            isFocusSelected: self.isFocusSelected,
            animator: self.animator
        )
    }
}

extension PolygonPlaceDetails {
    func toPlaceDetails() -> PlaceDetails {
        return PlaceDetails(
            coordinates: self.coordinates,
            name: self.name,
            placeKey: self.placeKey,
            checkInPolygonCoordinateKey: nil, // Not available in PolygonPlaceDetails
            type: self.type,
            source: self.source,
            address: self.address,
            description: self.description,
            imageName: self.imageName,
            lastCheckInTimestamp: self.lastCheckInTimestamp,
            dominantGroupKey: self.dominantGroupKey,
            size: self.size,
            previousSize: self.previousSize,
            dominantGroup: self.dominantGroup,
            competingGroups: self.competingGroups,
            following: self.following,
            website: self.website,
            phone: self.phone,
            averageRate: self.averageRate,
            totalRate: self.totalRate,
            countRates: self.countRates,
            userRate: self.userRate,
            canEdit: self.canEdit,
            workingHours: self.workingHours,
            touch: self.touch,
            animator: self.animator
        )
    }
}

