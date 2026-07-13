//
//  FirebaseRTDBModels.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 09/05/2021.
//

import Foundation
import CoreLocation

class GroupOwnershipFirebaseModel: Codable {
    var groupKey: String?
    var name: String?
    var imageName: String?
    var placeCoordinates: OrbisLocationModel?
    var colorIndex: Int?
    var solidColorHex: String?
    var strokeColorHex: String?
    var timestamp: Double?
    var validCheckins: Int?
    var placeKey: String?
    
    var toOrbisGroup: Group {
        let group = Group(name: name ?? "", propicLink: imageName ?? "", baseColor: .clear, indicatorIconName: "", description: "", places: validCheckins ?? 0, members: 0)
        group.groupKey = self.groupKey
        group.imageName = self.imageName
        group.name = self.name
        group.location = self.placeCoordinates
        group.colorIndex = self.colorIndex
        group.solidColorHex = self.solidColorHex
        group.strokeColorHex = self.strokeColorHex
        group.timestamp = String(self.timestamp ?? 0)
        group.validCheckins = self.validCheckins
        group.placesCount = self.validCheckins
        return group
    }
    
    func liesInsideObservableRegion(forMapCenterCoordinate coordinate: CLLocationCoordinate2D, visibleRadius radius: Double) -> Bool {
        guard let location = self.placeCoordinates, let lat = location.latitude, let long = location.longitude else {
            return false
        }
        let placeLoc = CLLocation(latitude: lat, longitude: long)
        let centerLoc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return placeLoc.distance(from: centerLoc) <= radius
    }
    
    func hasChanged(withRespectToPlace place: OrbisPlace) -> Bool {
        guard place.placeKey == placeKey else { return false }
        let dominantGroup = toOrbisGroup
        let hasDominantGroupChanged = dominantGroup.groupKey != place.dominantGroup?.groupKey
        let hasDominantGroupPicChanged = dominantGroup.imageName != place.dominantGroup?.imageName
        let hasDominantGroupNameChanged = dominantGroup.name != place.dominantGroup?.name
        let hasDominantGroupColorChanged = (dominantGroup.colorIndex != place.dominantGroup?.colorIndex) || (dominantGroup.strokeColorHex != place.dominantGroup?.strokeColorHex)
        return hasDominantGroupChanged || hasDominantGroupPicChanged || hasDominantGroupNameChanged || hasDominantGroupColorChanged
    }
}

class PlaceSizesFirebaseModel: Codable {
    var coordinates: OrbisLocationModel?
    var placeKey: String?
    var lastSizeChangeTimestamp: Double?
    var lastCheckInTimestamp: Double?
    var lastSize: Double?
    
    func liesInsideObservableRegion(forMapCenterCoordinate coordinate: CLLocationCoordinate2D, visibleRadius radius: Double) -> Bool {
        guard let location = self.coordinates, let lat = location.latitude, let long = location.longitude else {
            return false
        }
        let placeLoc = CLLocation(latitude: lat, longitude: long)
        let centerLoc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return placeLoc.distance(from: centerLoc) <= radius
    }
    
    func hasChanged(withRespectToPlace place: OrbisPlace) -> Bool {
        guard place.placeKey == placeKey else { return false }
        let hasCoordinatesChanged = (coordinates?.latitude != place.coordinates?.latitude) || (coordinates?.longitude != place.coordinates?.longitude)
        let hasLastSizeChanged = lastSize != place.lastSize
        let hasLastTimeStampChanged = (Date(timeIntervalSince1970: (lastCheckInTimestamp ?? 0)/1000).iso8601withFractionalSeconds != place.lastCheckInTimestamp) || (Date(timeIntervalSince1970: (lastSizeChangeTimestamp ?? 0)/1000).iso8601withFractionalSeconds != place.lastSizeChangeTimestamp)
        return hasCoordinatesChanged || hasLastSizeChanged || hasLastTimeStampChanged
    }
}

class ImageThumbnailMetaRTDB: Codable {
    var generated: Bool?
}
