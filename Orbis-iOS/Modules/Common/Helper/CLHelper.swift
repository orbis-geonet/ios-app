//
//  CLHelper.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/03/2021.
//

import Foundation
import CoreLocation
import MapKit

class CLHelper {
    // Create new coordinate with equal latitude and longitude distances (distance can be both positive and negative).
    static func coordinate(from coordinate: CLLocationCoordinate2D, distance: CLLocationDistance) -> CLLocationCoordinate2D {
        return self.coordinate(from: coordinate, latitudeDistance: distance, longitudeDistance: distance)
    }

    // Create new coordinate with latitude and longitude distances (distances can be both positive and negative).
    static func coordinate(from coordinate: CLLocationCoordinate2D, latitudeDistance: CLLocationDistance, longitudeDistance: CLLocationDistance) -> CLLocationCoordinate2D {
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: latitudeDistance, longitudinalMeters: longitudeDistance)

        let newLatitude = coordinate.latitude + region.span.latitudeDelta
        let newLongitude = coordinate.longitude + region.span.longitudeDelta

        return CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)
    }
    //MARK: IconGerator Alternative
    /*
    static func createCustomIconView(for placeDetails: PolygonPlaceDetails, with image: UIImage?) -> UIImage {
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFill

        var placeholderImage: UIImage?
        
        if  image == nil{
            placeholderImage = OrbisMapPlaceIconManager.shared.placeIcons[placeDetails.placeType]
        }
    
        imageView.image = image ?? placeholderImage
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = imageView.bounds.width / 2 //Make it circular
        imageView.layer.borderWidth =  5         //7 previous
        imageView.layer.borderColor = placeDetails.getPlaceColor().cgColor

        let renderer = UIGraphicsImageRenderer(size: imageView.bounds.size)
        return renderer.image { _ in
            imageView.drawHierarchy(in: imageView.bounds, afterScreenUpdates: true)
        }
    }
    */
    
    //MARK: This is optimised code and can work in backgroud thread too
    static func createCustomIconView(for placeDetails: PolygonPlaceDetails, with image: UIImage?) -> UIImage {
        
        // Define the image size
        let imageSize = CGSize(width: 80, height: 80)
        //let cornerRadius = imageSize.width / 2
        let borderWidth: CGFloat = 4

        // Placeholder image if the provided image is nil
        let placeholderImage = image ?? OrbisMapPlaceIconManager.shared.placeIcons[placeDetails.placeType]

        // Create a CoreGraphics context
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return UIImage()
        }

        // Draw the circular path
        let rect = CGRect(origin: .zero, size: imageSize)
        context.addEllipse(in: rect)
        context.clip()

        // Draw the image inside the circular path
        placeholderImage?.draw(in: rect)

        // Draw the border
        context.setStrokeColor(placeDetails.getPlaceColor().cgColor)
        context.setLineWidth(borderWidth)
        context.strokeEllipse(in: rect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2))

        // Get the final image
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return finalImage ?? UIImage()
    }

    
    static func convertToRGB(_ image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: image.size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
   static func performFirstTimeAction(key: String = "isFirstLaunchKey", action: () -> Void) {
        let defaults = UserDefaults.standard
        let isFirstLaunch = defaults.bool(forKey: key) // Check if the key already exists
        
        if !isFirstLaunch { // If the app is launching for the first time
            action() // Execute the action block
            defaults.set(true, forKey: key) // Mark as not the first launch anymore
            defaults.synchronize() // Save changes immediately
        }
    }
    
    static func resetFirstTimeAction(key: String = "isFirstLaunchKey") {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: key) // Remove the key from UserDefaults
        defaults.synchronize() // Ensure the changes are saved immediately
    }


}



extension CLLocationCoordinate2D:  Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
}

extension Double {
    func toRadians() -> Double {
        return self * .pi / 180
    }
}

// Helper to convert [Coordinates] to [CLLocationCoordinate2D]
extension Array where Element == Coordinates {
    func toCLLocationCoordinate2DArray() -> [CLLocationCoordinate2D] {
        return self.map { CLLocationCoordinate2D(latitude: $0.latitude!, longitude: $0.longitude!) }
    }
}
//MARK: conversion helper from and to OrbisFeedPostResponses to FeedEntities and Vice Verca
extension CLHelper {
    func toOrbisFeedPostResponses(from entity: FeedEntity) -> OrbisFeedPostResponses? {
        guard let jsonData = entity.content.data(using: .utf8) else { return nil }
        do {
            return try JSONDecoder().decode(OrbisFeedPostResponses.self, from: jsonData)
        } catch {
            print("Error decoding FeedEntity content: \(error)")
            return nil
        }
    }
    
    //MARK: convert to FeedEntity
    func toFeedEntity(from response: OrbisFeedPostResponse, nextPage: String, city: String, fromNearby: Bool) -> FeedEntity {
        let entity = FeedEntity()
        entity.nextPage = nextPage
        entity.city = city
        entity.fromNearby = fromNearby

        // Convert the list of responses to JSON
        if let jsonData = try? JSONEncoder().encode(response) {
            entity.content = String(data: jsonData, encoding: .utf8) ?? ""
        }

        return entity
    }
    
    func toFeedEntities(from responses: OrbisFeedPostResponses, city: String, fromNearby: Bool) -> [FeedEntity] {
        return responses.enumerated().map { (index, response) in
            let entity = FeedEntity()
            entity.nextPage = "page\(index)" // Create unique `nextPage` for each response
            entity.city = city
            entity.fromNearby = fromNearby
            
            // Convert the single response to JSON
            if let jsonData = try? JSONEncoder().encode([response]) { // Wrap in array for compatibility
                entity.content = String(data: jsonData, encoding: .utf8) ?? ""
            }
            
            return entity
        }
    }
}
