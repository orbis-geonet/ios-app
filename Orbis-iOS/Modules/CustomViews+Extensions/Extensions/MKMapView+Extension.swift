//
//  MKMapView+Extension.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 24/08/2021.
//

import Foundation
import MapKit

extension MKMapItem {
  convenience init(coordinate: CLLocationCoordinate2D, name: String) {
    self.init(placemark: .init(coordinate: coordinate))
    self.name = name
  }
}
