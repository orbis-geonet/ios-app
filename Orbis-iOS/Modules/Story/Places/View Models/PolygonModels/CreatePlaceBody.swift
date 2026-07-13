//
//  Coordinates.swift
//  Orbis-iOS
//
//  Created by Kamran on 30/10/2024.
//


import Foundation
import CoreLocation

// Structure for CreatePlaceBody to match the Kotlin data class.
struct CreatePlaceBody: Codable {
    var coordinates: Coordinates?
    var userCoordinates: Coordinates?
    var groupCreatedKey: String = ""
    var name: String = ""
    var type: String = ""
    var address: String = ""
}
