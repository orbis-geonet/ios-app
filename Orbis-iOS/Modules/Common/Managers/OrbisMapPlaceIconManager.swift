//
//  OrbisMapPlaceIconManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 03/06/2021.
//

import Foundation
import UIKit

class OrbisMapPlaceIconManager {
    static let shared = OrbisMapPlaceIconManager()

    private let orbisPlaceTypes: [OrbisPlaceType] = [.bar, .beach, .building, .castle, .fastFood, .house, .house2, .location, .music, .park, .restaurant, .school, .shopping, .sportsCenter, .twoBuildings]
    var placeIcons: [OrbisPlaceType: UIImage] = [:]
    
    init() {
        orbisPlaceTypes.forEach { type in
            placeIcons[type] = type.correspondingCircularImage()
        }
    }
}
