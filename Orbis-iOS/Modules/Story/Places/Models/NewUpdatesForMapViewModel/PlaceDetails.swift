//
//  PlaceDetails.swift
//  Orbis-iOS
//
//  Created by Kamran on 30/10/2024.
//


import Foundation
import UIKit
import CoreLocation

// Structs to hold data for PlaceDetails, WorkingHoursModel, and RatePlaceModel
struct PlaceDetails: Codable {
    var coordinates: Coordinates?
    var name: String?
    var placeKey: String?
    var checkInPolygonCoordinateKey: String?
    var type: String?
    var source: String?
    var address: String?
    var description: String?
    var imageName: String?
    var lastCheckInTimestamp: String?
    var dominantGroupKey: String?
    var size: Double?
    var previousSize: Double? // Make this optional
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
    
    // Non-codable properties
    var touch: Bool = false
    var animator: UIViewPropertyAnimator? = nil
    
    // Coding keys to exclude animator and other properties if needed
        enum CodingKeys: String, CodingKey {
            case coordinates, name, placeKey, checkInPolygonCoordinateKey, type, source, address
            case description, imageName, lastCheckInTimestamp, dominantGroupKey, size, previousSize
            case dominantGroup, competingGroups, following, website, phone, averageRate, totalRate
            case countRates, userRate, canEdit, workingHours
        }
    
    // Convert PlaceDetails to PolygonPlaceDetails
    func toPolygonPlaceDetails() -> PolygonPlaceDetails {
        //let polygonPoints = CoordinatesUtil.getCircleOuterPoints(coordinates: coordinates ?? Coordinates(), radius: size)
        
        let polygonPoints = CoordinatesUtil.getCircleOuterPoints(center: coordinates!, radius: size!)
        
        let place = PolygonPlaceDetails(
            coordinates: coordinates,
            name: name,
            placeKey: placeKey,
            type: type,
            source: source,
            address: address,
            description: description,
            imageName: imageName,
            lastCheckInTimestamp: lastCheckInTimestamp,
            dominantGroupKey: dominantGroupKey,
            size: size,
            previousSize: previousSize,
            dominantGroup: dominantGroup,
            competingGroups: competingGroups,
            following: following,
            website: website,
            phone: phone,
            averageRate: averageRate,
            totalRate: totalRate,
            countRates: countRates,
            userRate: userRate,
            canEdit: canEdit,
            workingHours: workingHours,
            places: [PolygonPlaceDetails(coordinates: coordinates, name: name,placeKey: placeKey,type: type,description: description, imageName: imageName, size:size, dominantGroup: dominantGroup, averageRate:averageRate, totalRate:totalRate, countRates:countRates, isFocusSelected: true)],
            polygonPoints: polygonPoints, polygonCenter: coordinates,
            touch: touch,
            isFocusSelected: true
        )
        return place
       
    }
}

extension PlaceDetails {
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
            userCreatedKey: nil,
            source: self.source,
            address: self.address,
            description: self.description,
            categoryKey: nil,
            cityKey: nil,
            countryKey: nil,
            phone: self.phone,
            website: self.website,
            averageRate: self.averageRate,
            totalRate: self.totalRate,
            countRates: self.countRates,
            userRate: self.userRate,
            lastCheckInTimestamp: self.lastCheckInTimestamp,
            lastSizeChangeTimestamp: nil,
            dominantGroupKey: self.dominantGroupKey,
            creationServerTimestamp: nil,
            timestamp: nil,
            groupCreatedKey: nil,
            dominantGroup: self.dominantGroup?.toGroup(),
            competingGroups: self.competingGroups?.compactMap { $0.toGroup() },
            googlePlaceId: nil,
            size: self.size,
            lastSize: self.previousSize,
            following: self.following,
            workingHours: self.workingHours?.compactMap { $0.toOrbisPlaceWorkingHours() },
            canEdit: self.canEdit,
            places: nil
        )
    }
}


struct RatePlaceModel: Codable {
    var placeKey: String = ""
    var averageRate: Float = 0.0
    var totalRate: Float = 0.0
    var countRates: Int = 0
}

