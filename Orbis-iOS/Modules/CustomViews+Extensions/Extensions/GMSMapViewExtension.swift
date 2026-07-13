//
//  GMSMapViewExtension.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 10/05/2021.
//

import Foundation
import GoogleMaps

extension GMSMapView {
    func getCenterCoordinate() -> CLLocationCoordinate2D {
        let centerPoint = self.center
        let centerCoordinate = self.projection.coordinate(for: centerPoint)
        return centerCoordinate
    }

    func getTopCenterCoordinate() -> CLLocationCoordinate2D {
        // to get coordinate from CGPoint of your map
        let topCenterCoor = self.convert(CGPoint(x: self.frame.size.width, y: 0), from: self)
        let point = self.projection.coordinate(for: topCenterCoor)
        return point
    }

    func getRadiusOld() -> CLLocationDistance {
        let centerCoordinate = getCenterCoordinate()
        let centerLocation = CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
        let topCenterCoordinate = self.getTopCenterCoordinate()
        let topCenterLocation = CLLocation(latitude: topCenterCoordinate.latitude, longitude: topCenterCoordinate.longitude)
        let radius = CLLocationDistance(centerLocation.distance(from: topCenterLocation))
        return round(radius)
    }
    
    func getRadius() -> CLLocationDistance {
        // Find the coordinates
        let visibleRegion = self.projection.visibleRegion()
        
        let farLeftLocation = CLLocation(latitude: visibleRegion.farLeft.latitude, longitude: visibleRegion.farLeft.longitude)
        let farRightLocation = CLLocation(latitude: visibleRegion.farRight.latitude, longitude: visibleRegion.farRight.longitude)
        let nearLeftLocation = CLLocation(latitude: visibleRegion.nearLeft.latitude, longitude: visibleRegion.nearLeft.longitude)
        let nearRightLocation = CLLocation(latitude: visibleRegion.nearRight.latitude, longitude: visibleRegion.nearRight.longitude)
        let centerPosition = self.camera.target
        let centerLocation = CLLocation(latitude: centerPosition.latitude, longitude: centerPosition.longitude)
        
        let radius1 = CLLocationDistance(centerLocation.distance(from: farLeftLocation))
        let radius2 = CLLocationDistance(centerLocation.distance(from: farRightLocation))
        let radius3 = CLLocationDistance(centerLocation.distance(from: nearLeftLocation))
        let radius4 = CLLocationDistance(centerLocation.distance(from: nearRightLocation))
        
        let radius = min(radius1, radius2, radius3, radius4)
        return round(radius)
    }
}
