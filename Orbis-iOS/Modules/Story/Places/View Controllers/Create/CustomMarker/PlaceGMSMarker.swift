//
//  PlaceGMSMarker.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 04/04/2021.
//

import GoogleMaps

class PlaceGMSMarker: GMSMarker {
    var place: OrbisPlace!
    init(place: OrbisPlace) {
        self.place = place
    }
}
