//
//  PlaceUpdateBody.swift
//  Orbis-iOS
//
//  Created by Kamran on 02/11/2024.
//


import Foundation

struct PlaceUpdateBody: Codable {
    var coordinates: Coordinates?
    var name: String?
    var type: String?
    var source: String?
    var address: String?
    var description: String?
    var categoryKey: String?
    var cityKey: String?
    var countryKey: String?
    var phone: String?
    var dominantGroupKey: String?
    var googlePlaceId: String?
    var deleted: String?
    var imageName: String?
    var website: String = ""
    var workingHours: [WorkingHoursModel]?

    init(coordinates: Coordinates? = nil,
         name: String? = nil,
         type: String? = nil,
         source: String? = nil,
         address: String? = nil,
         description: String? = nil,
         categoryKey: String? = nil,
         cityKey: String? = nil,
         countryKey: String? = nil,
         phone: String? = nil,
         dominantGroupKey: String? = nil,
         googlePlaceId: String? = nil,
         deleted: String? = nil,
         imageName: String? = nil,
         website: String = "",
         workingHours: [WorkingHoursModel]? = nil) {
        self.coordinates = coordinates
        self.name = name
        self.type = type
        self.source = source
        self.address = address
        self.description = description
        self.categoryKey = categoryKey
        self.cityKey = cityKey
        self.countryKey = countryKey
        self.phone = phone
        self.dominantGroupKey = dominantGroupKey
        self.googlePlaceId = googlePlaceId
        self.deleted = deleted
        self.imageName = imageName
        self.website = website
        self.workingHours = workingHours
    }
}
