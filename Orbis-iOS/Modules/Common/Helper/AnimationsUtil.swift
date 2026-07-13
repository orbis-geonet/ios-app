//
//  AnimationsUtil.swift
//  Orbis-iOS
//
//  Created by Kamran on 03/11/2024.
//


import UIKit
import Foundation
import GoogleMaps
import CoreGraphics

class AnimationsUtil: NSObject {

    private static let MILLIS_IN_SECOND: TimeInterval = 1000
    private static let SECONDS_IN_MINUTE: TimeInterval = 60
    private static let MINUTES_IN_HOUR: TimeInterval = 60
    private static let HOURS_IN_DAY: TimeInterval = 24
    private static let DAYS_IN_YEAR: Double = 365.24
    var MILLISECONDS_IN_DAY =
            MILLIS_IN_SECOND * SECONDS_IN_MINUTE * MINUTES_IN_HOUR * HOURS_IN_DAY
    static var isAnimatingPolygon: Bool = false
    static var isAnimatingCirclePolygon: Bool = false
    static var scaleAnimationTimer: Timer?
    static var scaleCircleAnimationTimer: Timer?
    
    static let MILLISECONDS_IN_DAY: TimeInterval = MILLIS_IN_SECOND * SECONDS_IN_MINUTE * MINUTES_IN_HOUR * HOURS_IN_DAY
    static let MILLISECONDS_IN_HOUR: TimeInterval = 3600000.0

    static func getDataDiffFromNow(lastCheckInTimestamp: TimeInterval) -> TimeInterval {
        let nowDate = Date().timeIntervalSince1970 * 1000
        let elapsedTime = abs(lastCheckInTimestamp - nowDate)
        return elapsedTime
    }
    

    static func createPulseAnimation(for image: UIImage, duration: Double, scaleFrom: CGFloat, scaleTo: CGFloat) -> CAAnimationGroup {
        // Create a temporary view to host the image for animation purposes
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        
        // Create scale animation
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [scaleFrom, scaleTo, scaleFrom]
        scaleAnimation.keyTimes = [0, 0.5, 1]
        scaleAnimation.duration = duration
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // Create opacity animation
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = [1.0, 0.5, 1.0]
        opacityAnimation.keyTimes = [0, 0.5, 1]
        opacityAnimation.duration = duration
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // Combine animations into a group
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [scaleAnimation, opacityAnimation]
        animationGroup.duration = duration
        animationGroup.repeatCount = .greatestFiniteMagnitude
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        return animationGroup
    }
    

    static func createPulseAnimation(for groundOverlay: GMSGroundOverlay, placeDetails: PolygonPlaceDetails) -> CAAnimationGroup? {
        // Prepare last check-in date
        var lastCheckinDate = ViewUtils.convertTimeStampToDate(dateStr: placeDetails.lastCheckInTimestamp)
        if !placeDetails.isCircle() {
            let checkins = placeDetails.places!.compactMap { ViewUtils.convertTimeStampToDate(dateStr: $0.lastCheckInTimestamp) }
            lastCheckinDate = checkins.max()
        }

        let tz = TimeZone.current
        let cal = Calendar.current
        let offsetInMillis = tz.secondsFromGMT(for: cal.date(byAdding: .second, value: cal.component(.second, from: Date()), to: Date())!) * 1000

        let diff = (getDataDiffFromNow(lastCheckInTimestamp: lastCheckinDate?.timeIntervalSince1970 ?? 0 * 1000) - Double(offsetInMillis))
        if diff < Double(MILLISECONDS_IN_DAY) {
            // Create radius animation
            let radiusAnimation = CAKeyframeAnimation(keyPath: "bounds.size.width")
            radiusAnimation.values = [
                placeDetails.size! * 2.0,
                placeDetails.size! * 1.8,
                placeDetails.size! * 2.0
            ]
            radiusAnimation.keyTimes = [0, 0.5, 1]
            radiusAnimation.duration = (500.0 + (diff / Double(MILLISECONDS_IN_HOUR)) * 20.83) / 1000 // Convert to seconds
            radiusAnimation.repeatCount = .greatestFiniteMagnitude
            radiusAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            // Create transparency animation
            let transparencyAnimation = CABasicAnimation(keyPath: "opacity")
            transparencyAnimation.fromValue = 0.0
            transparencyAnimation.toValue = 1.0
            transparencyAnimation.duration = radiusAnimation.duration
            transparencyAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            // Group animations
            let animationGroup = CAAnimationGroup()
            animationGroup.animations = [radiusAnimation, transparencyAnimation]
            animationGroup.duration = radiusAnimation.duration
            animationGroup.repeatCount = .greatestFiniteMagnitude
            animationGroup.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            return animationGroup
        } else {
            return nil
        }
    }
    
    static func createPulseAnimationSlowDiminish(groundOverlay: GMSGroundOverlay, placeDetails: inout PolygonPlaceDetails) -> UIViewPropertyAnimator {
        // Create a local copy of `placeDetails` to avoid capturing `inout` parameter directly
        var localPlaceDetails = placeDetails

        // Prepare the animation
        let duration: TimeInterval = 2.0
        let animator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) {
            // Animation changes
            let radiusX2: CGFloat = CGFloat(localPlaceDetails.size! * 2.0)
            groundOverlay.bounds = GMSCoordinateBounds(
                coordinate: groundOverlay.position,
                coordinate: CLLocationCoordinate2D(
                    latitude: groundOverlay.position.latitude + Double(radiusX2 / 111000),
                    longitude: groundOverlay.position.longitude + Double(radiusX2 / (111000 * cos(groundOverlay.position.latitude * .pi / 180)))
                )
            )
        }

        animator.addCompletion { position in
            if position == .end {
                print("animationEnded: ended")
                let newPosition = groundOverlay.position
                let radiusX2 = CGFloat(localPlaceDetails.size! * 2.0)
                groundOverlay.bounds = GMSCoordinateBounds(
                    coordinate: newPosition,
                    coordinate: CLLocationCoordinate2D(
                        latitude: newPosition.latitude + Double(radiusX2 / 111000),
                        longitude: newPosition.longitude + Double(radiusX2 / (111000 * cos(newPosition.latitude * .pi / 180)))
                    )
                )
                var newLocalPlaceDetails = localPlaceDetails // Create a copy to pass to the recursive call
                let newAnimator = self.createPulseAnimationSlowDiminish(groundOverlay: groundOverlay, placeDetails: &newLocalPlaceDetails)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.startPulseAnimation(placeDetails: &newLocalPlaceDetails, valueAnimator: newAnimator)
                }
            }
        }

        animator.startAnimation()
        placeDetails = localPlaceDetails // Assign the local copy back to the original `inout` parameter
        return animator
    }
    
    func startPulseAnimation(placeDetails: inout PolygonPlaceDetails, delay: TimeInterval = 0.0) {
        var lastCheckinDate = ViewUtils.convertTimeStampToDate(dateStr: placeDetails.lastCheckInTimestamp)
        
        if !placeDetails.isCircle() {
            let checkins = placeDetails.places!.compactMap { ViewUtils.convertTimeStampToDate(dateStr: $0.lastCheckInTimestamp) }
            lastCheckinDate = checkins.max() ?? lastCheckinDate
        }
        let duration = 2.0
        
        let timeZone = TimeZone.current
        let calendar = Calendar.current
        let offsetInMillis = timeZone.secondsFromGMT(for: calendar.date(from: calendar.dateComponents(in: timeZone, from: Date()))!) * 1000
        
        if let lastCheckinTime = lastCheckinDate?.timeIntervalSince1970 {
            let diff = AnimationsUtil.getDataDiffFromNow(lastCheckInTimestamp: lastCheckinTime) - Double(offsetInMillis)
            
            if diff < MILLISECONDS_IN_DAY {
                let pulseLongTime = MILLISECONDS_IN_DAY - diff
                let repeatCount = Int(pulseLongTime / 2.0)
                
                let pulseAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) {
                    // Animation logic for pulse effect
                }
                
//              pulseAnimator.addCompletion { position in
//                    if position == .end, repeatCount > 0 {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [&placeDetails] in
//                            self.startPulseAnimation(placeDetails: &placeDetails, delay: delay)
//                        }
//                    }
//                }
                
                pulseAnimator.startAnimation(afterDelay: delay)
                placeDetails.animator = pulseAnimator
            }
        }
    }


    func createCheckInAnimation(for groundOverlay: GMSGroundOverlay?, placeDetails: PolygonPlaceDetails) -> CAAnimationGroup? {
        let tz = TimeZone.current
        let cal = Calendar.current
        let offsetInMillis = tz.secondsFromGMT(for: cal.date(byAdding: .second, value: cal.component(.second, from: Date()), to: Date())!) * 1000

        var lastCheckinDate = ViewUtils.convertTimeStampToDate(dateStr: placeDetails.lastCheckInTimestamp)
        let diff = (AnimationsUtil.getDataDiffFromNow(lastCheckInTimestamp: lastCheckinDate?.timeIntervalSince1970 ?? 0 * 1000) - Double(offsetInMillis)) / Double(AnimationsUtil.MILLISECONDS_IN_HOUR)

        // Create radius animation
        let initialRadius = placeDetails.size! * 2 * 1.15
        let finalRadius = placeDetails.size! * 2
        let radiusAnimation = CAKeyframeAnimation(keyPath: "bounds.size.width")
        radiusAnimation.values = [initialRadius, finalRadius, initialRadius]
        radiusAnimation.keyTimes = [0, 0.5, 1]
        radiusAnimation.duration = max(500.0 + (diff * 20.83), 0.0) / 1000 // Convert to seconds
        radiusAnimation.repeatCount = .greatestFiniteMagnitude
        radiusAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        // Group animations
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [radiusAnimation]
        animationGroup.duration = radiusAnimation.duration
        animationGroup.repeatCount = .greatestFiniteMagnitude
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let animationDelegate = AnimationDelegate(onStart: {
            print("Check-in animation started")
        }, onEnd: {
            print("Check-in animation ended")
        }, onRepeat: {
            print("Check-in animation repeated")
        })

        animationGroup.delegate = animationDelegate

        // Update animation logic (e.g., radius setting)
        animationDelegate.updateCallback = { fraction in
            let currentRadius = initialRadius + (finalRadius - initialRadius) * Double(fraction)
            // Note: Directly changing GMSGroundOverlay dimensions may require alternative handling
            // Use an external overlay view or logic as necessary
        }

        return animationGroup
    }
    
    func startCheckInAnimation(for groundOverlay: GMSGroundOverlay?, animator: CAAnimationGroup) {
        // Make the ground overlay visible if needed
        // groundOverlay?.isTappable = true // Optionally set to true if interaction is needed

        // GMSGroundOverlay does not have a layer property, so use an alternative method to handle animations.
        let animationView = UIView(frame: CGRect.zero)
        animationView.layer.add(animator, forKey: "checkInAnimation")

        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            animator.delegate?.animationDidStop!(animator, finished: true)
            groundOverlay?.map = nil // Remove the overlay from the map
        }
    }
    
    static func startPulseAnimation(placeDetails: inout PolygonPlaceDetails, valueAnimator: UIViewPropertyAnimator, delay: TimeInterval = 0.0) {
        var lastCheckinDate = ViewUtils.convertTimeStampToDate(dateStr: placeDetails.lastCheckInTimestamp)
        if !placeDetails.isCircle() {
            let checkins = placeDetails.places!.compactMap { ViewUtils.convertTimeStampToDate(dateStr: $0.lastCheckInTimestamp) }
            lastCheckinDate = checkins.max() ?? lastCheckinDate
        }

        let timeZone = TimeZone.current
        let calendar = Calendar.current
        let offsetInMillis = TimeInterval(timeZone.secondsFromGMT(for: Date()))

        guard let lastCheckinDateInMillis = lastCheckinDate?.timeIntervalSince1970 else { return }
        let diff = AnimationsUtil.getDataDiffFromNow(lastCheckInTimestamp: lastCheckinDateInMillis) - offsetInMillis
        if diff < Double(AnimationsUtil.MILLISECONDS_IN_DAY) {
            let pulseLongTime = Double(AnimationsUtil.MILLISECONDS_IN_DAY) - diff
            valueAnimator.pauseAnimation()
            valueAnimator.startAnimation(afterDelay: delay)
        }
    }
    
    static func createPulseAnimationCeaseExist(for groundOverlay: GMSGroundOverlay, on mapView: GMSMapView) -> CAAnimationGroup {
        // Get the corners of the bounds as geographical coordinates
        guard let bounds = groundOverlay.bounds else {
            print("Error: groundOverlay has no bounds")
            return CAAnimationGroup()
        }

        let northEastPoint = mapView.projection.point(for: bounds.northEast)
        let southWestPoint = mapView.projection.point(for: bounds.southWest)

        // Calculate the width as the distance between these two points
        let initialRadius = hypot(northEastPoint.x - southWestPoint.x, northEastPoint.y - southWestPoint.y)

        // Create the radius animation to shrink to zero
        let radiusAnimation = CABasicAnimation(keyPath: "transform.scale")
        radiusAnimation.fromValue = initialRadius / initialRadius // Starting scale of 1.0
        radiusAnimation.toValue = 0.0 // Ending scale
        radiusAnimation.duration = 2.0
        radiusAnimation.fillMode = .forwards
        radiusAnimation.isRemovedOnCompletion = false

        // Create the transparency animation (optional, used if transparency effect is needed)
        let transparencyAnimation = CABasicAnimation(keyPath: "opacity")
        transparencyAnimation.fromValue = 1.0
        transparencyAnimation.toValue = 0.0
        transparencyAnimation.duration = 2.0

        // Combine animations into a group
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [radiusAnimation, transparencyAnimation]
        animationGroup.duration = 2.0
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        animationGroup.delegate = AnimationDelegate(onStart: {
            // Code to execute when the animation starts
            print("Animation started")
            // You can add any additional logic here, such as updating the UI or logging
        }, onEnd: {
            // Code to execute when the animation ends
            print("Animation ended")
            // Perform cleanup actions or update the overlay
            groundOverlay.opacity = 0.0 // Hide the overlay or set another relevant property
        }, onRepeat: {
            // Code to execute when the animation repeats
            print("Animation repeated")
            // Add any logic if the animation needs to repeat actions
        })

        return animationGroup
    }

    static func createPolygonAppearingAnimation(for polygon: GMSPolygon, centroid: CLLocationCoordinate2D, polygonPoints: [CLLocationCoordinate2D]) -> CAAnimation {
        let animation = CABasicAnimation(keyPath: "fraction")
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.duration = 1.0
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let animationDelegate = AnimationDelegate(onStart: {
            // Code to execute when the animation starts
            print("Polygon appearing animation started")
        }, onEnd: {
            // Code to execute when the animation ends
            print("Polygon appearing animation ended")
        }, onRepeat: {
            // Code to execute when the animation repeats
            print("Polygon appearing animation repeated")
        })

        animation.delegate = animationDelegate

        let displayLink = CADisplayLink(target: animationDelegate, selector: #selector(animationDelegate.updateAnimation))
        displayLink.add(to: .current, forMode: .default)

        animationDelegate.updateCallback = { fraction in
            let interpolatedPoints = polygonPoints.map { point in
                CLLocationCoordinate2D(
                    latitude: centroid.latitude + (point.latitude - centroid.latitude) * Double(fraction),
                    longitude: centroid.longitude + (point.longitude - centroid.longitude) * Double(fraction)
                )
            }
            let path = GMSMutablePath()
            interpolatedPoints.forEach { path.add($0) }
            polygon.path = path
        }

        return animation
    }

    static func createMovingCenterAnimation(for groundOverlay: GMSGroundOverlay, toPlace: PolygonPlaceDetails) -> CAAnimationGroup {
        let startingPosition = groundOverlay.position
        let endingPosition = toPlace.polygonCenter
        let initialRadius = groundOverlay.icon?.size.width ?? 0.0 / 2.0 // Updated to use icon size if applicable //groundOverlay.bounds.size.width / 2.0

        // Create latitude animation
        let latAnimation = CABasicAnimation(keyPath: "position.latitude")
        latAnimation.fromValue = startingPosition.latitude
        latAnimation.toValue = endingPosition?.latitude
        latAnimation.duration = 2.0

        // Create longitude animation
        let lngAnimation = CABasicAnimation(keyPath: "position.longitude")
        lngAnimation.fromValue = startingPosition.longitude
        lngAnimation.toValue = endingPosition?.longitude
        lngAnimation.duration = 2.0

        // Create radius animation
        let radiusAnimation = CABasicAnimation(keyPath: "bounds.size.width")
        radiusAnimation.fromValue = initialRadius
        radiusAnimation.toValue = toPlace.size! * 2.0
        radiusAnimation.duration = 2.0

        // Group animations together
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [latAnimation, lngAnimation, radiusAnimation]
        animationGroup.duration = 2.0
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        // Add completion and update handling
        let animationDelegate = AnimationDelegate(onStart: {
            print("Moving center animation started")
        }, onEnd: {
            print("Moving center animation ended")
        }, onRepeat: {
            print("Moving center animation repeated")
        })

        animationGroup.delegate = animationDelegate

        animationDelegate.updateCallback = { fraction in
            let animatedLat = startingPosition.latitude + ((endingPosition?.latitude!)! - startingPosition.latitude) * Double(fraction)
            let animatedLng = startingPosition.longitude + ((endingPosition?.longitude!)! - startingPosition.longitude) * Double(fraction)
            let animatedLatLng = CLLocationCoordinate2D(latitude: animatedLat, longitude: animatedLng)
            let animatedRadius = initialRadius + (toPlace.size! * 2.0 - initialRadius) * Double(fraction)
            groundOverlay.position = animatedLatLng
            groundOverlay.bounds = GMSCoordinateBounds(coordinate: animatedLatLng, coordinate: animatedLatLng).includingCoordinate(animatedLatLng)
            // Set radius or bounds if needed based on implementation
        }

        return animationGroup
    }

    static func createPopupAnimation(for groundOverlay: GMSGroundOverlay, placeDetails: PolygonPlaceDetails) -> CAAnimationGroup {
        let initialRadius: CGFloat = 0.0
        let finalRadius: CGFloat = placeDetails.size! * 2.0

        // Create radius animation
        let radiusAnimation = CABasicAnimation(keyPath: "bounds.size.width")
        radiusAnimation.fromValue = initialRadius
        radiusAnimation.toValue = finalRadius
        radiusAnimation.duration = 2.0
        radiusAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        // Group animations together
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [radiusAnimation]
        animationGroup.duration = 2.0
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        // Add completion and update handling
        let animationDelegate = AnimationDelegate(onStart: {
            print("Popup animation started")
        }, onEnd: {
            print("Popup animation ended")
        }, onRepeat: {
            print("Popup animation repeated")
        })

        animationGroup.delegate = animationDelegate

        animationDelegate.updateCallback = { fraction in
            let animatedRadius = initialRadius + (finalRadius - initialRadius) * Double(fraction)
            let overlayBounds = GMSCoordinateBounds(
                coordinate: CLLocationCoordinate2D(latitude: groundOverlay.position.latitude - animatedRadius / 2,
                                                    longitude: groundOverlay.position.longitude - animatedRadius / 2),
                coordinate: CLLocationCoordinate2D(latitude: groundOverlay.position.latitude + animatedRadius / 2,
                                                    longitude: groundOverlay.position.longitude + animatedRadius / 2)
            )
            groundOverlay.bounds = overlayBounds
        }


        return animationGroup
    }

    func createPulseAnimation(for groundOverlay: GMSGroundOverlay, placeDetails: PolygonPlaceDetails) -> CAAnimationGroup? {
        // Prep the last check-in date
        var lastCheckinDate = ViewUtils.convertTimeStampToDate(dateStr: placeDetails.lastCheckInTimestamp)
        if !placeDetails.isCircle() {
            let checkins = placeDetails.places!.compactMap { ViewUtils.convertTimeStampToDate(dateStr: $0.lastCheckInTimestamp) }
            lastCheckinDate = checkins.max()
        }

        guard let lastCheckinDate = lastCheckinDate else { return nil }

        let tz = TimeZone.current
        let cal = Calendar.current
        let offsetInMillis = tz.secondsFromGMT(for: cal.date(byAdding: .second, value: cal.component(.second, from: Date()), to: Date())!) * 1000

        let diff = (AnimationsUtil.getDataDiffFromNow(lastCheckInTimestamp: lastCheckinDate.timeIntervalSince1970 * 1000) - Double(offsetInMillis))
        if diff < Double(AnimationsUtil.MILLISECONDS_IN_DAY) {
            let initialRadius = placeDetails.size! * 2.0
            let reducedRadius = placeDetails.size! * 1.8

            // Create radius animation
            let radiusAnimation = CAKeyframeAnimation(keyPath: "bounds.size.width")
            radiusAnimation.values = [initialRadius, reducedRadius, initialRadius]
            radiusAnimation.keyTimes = [0, 0.5, 1]
            radiusAnimation.duration = 2.0

            // Create transparency animation
            let transparencyAnimation = CABasicAnimation(keyPath: "opacity")
            transparencyAnimation.fromValue = 0.0
            transparencyAnimation.toValue = 1.0
            transparencyAnimation.duration = 2.0

            // Adjust pulse rate based on time difference
            let diffInHours = (diff / Double(AnimationsUtil.MILLISECONDS_IN_HOUR)).rounded()
            let pulseRate = max(500.0 + (diffInHours * 20.83), 0.0)
            print("differenceOfTime", placeDetails.placeKey, diffInHours, pulseRate)
            
            // Group animations together
            let animationGroup = CAAnimationGroup()
            animationGroup.animations = [radiusAnimation, transparencyAnimation]
            animationGroup.duration = pulseRate / 1000 // Convert milliseconds to seconds
            animationGroup.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            // Add completion and update handling
            let animationDelegate = AnimationDelegate(onStart: {
                print("Pulse animation started")
            }, onEnd: {
                print("Pulse animation ended")
            }, onRepeat: {
                print("Pulse animation repeated")
            })

            animationGroup.delegate = animationDelegate

            animationDelegate.updateCallback = { fraction in
                let currentRadius = initialRadius + (reducedRadius - initialRadius) * Double(fraction)
                let overlayBounds = GMSCoordinateBounds(
                    coordinate: CLLocationCoordinate2D(latitude: groundOverlay.position.latitude - currentRadius / 2,
                                                        longitude: groundOverlay.position.longitude - currentRadius / 2),
                    coordinate: CLLocationCoordinate2D(latitude: groundOverlay.position.latitude + currentRadius / 2,
                                                        longitude: groundOverlay.position.longitude + currentRadius / 2)
                )
                groundOverlay.bounds = overlayBounds
            }

            return animationGroup
        } else {
            return nil
        }
    }

    
    static func createBounceAnimation(for marker: UIView, placeDetails: PolygonPlaceDetails) -> CAKeyframeAnimation? {
        
        print("placeDetails.placeKeh === \(placeDetails.placeKey)")

        
        guard let lastCheckinDate = ViewUtils.convertTimeStampToDate(dateStr: placeDetails.lastCheckInTimestamp) else {
            print("invalid timestamp")
            return nil
        }
        
        let timeZone = TimeZone.current
        let offsetInMillis = timeZone.secondsFromGMT() * 1000
        
        let now = Date().timeIntervalSince1970 * 1000 // Current time in milliseconds
        let lastCheckinTime = lastCheckinDate.timeIntervalSince1970 * 1000 // Last check-in time in milliseconds
        let diff = now - lastCheckinTime - Double(offsetInMillis)
        
        if diff < MILLISECONDS_IN_DAY {
            let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
            bounceAnimation.values = [1.0, 1.08, 1.0]
            bounceAnimation.keyTimes = [0, 0.5, 1]
            bounceAnimation.duration = 1.45
            bounceAnimation.repeatCount = .infinity
            bounceAnimation.isRemovedOnCompletion = false
            
            return bounceAnimation
        } else {
            return nil
        }
    }

    static func startBounceAnimation(for  marker: UIView, placeDetails: PolygonPlaceDetails, delay: TimeInterval = 0) {
        // Safely unwrap and convert the timestamp
        
        
        print("placeDetails.placeKeh === \(placeDetails.placeKey)")
        
        guard let lastCheckinDate = ViewUtils.convertTimeStampToDate(dateStr: placeDetails.lastCheckInTimestamp) else {
            print("invalid timestamp")
            return
        }
        
        guard let bounceAnimation = createBounceAnimation(for: marker, placeDetails: placeDetails) else { return }
        
        let timeZone = TimeZone.current
        let offsetInMillis = timeZone.secondsFromGMT() * 1000
        
        let now = Date().timeIntervalSince1970 * 1000 // Current time in milliseconds
        let lastCheckinTime = lastCheckinDate.timeIntervalSince1970 * 1000 // Last check-in time in milliseconds
        let diff = now - lastCheckinTime - Double(offsetInMillis)
        
        if diff < MILLISECONDS_IN_DAY {
            let remainingTime = MILLISECONDS_IN_DAY - diff
            
            // Add animation to the marker layer
            marker.layer.add(bounceAnimation, forKey: "bounce")
            
            // Stop animation after the calculated remaining time
            DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime / 1000) {
                marker.layer.removeAnimation(forKey: "bounce")
            }
        }
    }


    static func interpolateKeyframeValue(progress: Double, keyTimes: [NSNumber], values: [CGFloat]) -> CGFloat {
        for i in 1..<keyTimes.count {
            if progress < keyTimes[i].doubleValue {
                let t0 = keyTimes[i - 1].doubleValue
                let t1 = keyTimes[i].doubleValue
                let v0 = values[i - 1]
                let v1 = values[i]
                let localProgress = (progress - t0) / (t1 - t0)
                return v0 + CGFloat(localProgress) * (v1 - v0)
            }
        }
        return values.last ?? 1.0
    }
    
    static func resizeImage(_ image: UIImage, scale: CGFloat) -> UIImage? {
           let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
           UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
           image.draw(in: CGRect(origin: .zero, size: newSize))
           let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
           UIGraphicsEndImageContext()
           return resizedImage
       }
     
    
    // Poligonun animasyonla genişlemesi (scale animasyonu)
    /*
    static func animatePolygonScaling(polygon: GMSPolygon, coordinates: [CLLocationCoordinate2D]) {
        let initialScaleFactor: Double = 0.3 // Başlangıç ölçeği
        let finalScaleFactor: Double = 1.0 // Nihai ölçek
        let scaleSteps: Double = 0.05 // Her adımda büyüme miktarı
        
        var currentScale = initialScaleFactor
        let centroid = CoordinatesUtil.calculateCentroid(points: coordinates) // Poligonun merkezi
        let path = GMSMutablePath()
        
        // Timer ile adım adım genişleme
        AnimationsUtil.scaleAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak polygon] timer in
            
            guard let polygon = polygon else {
                // If the polygon has been deallocated, invalidate the timer and return
                timer.invalidate()
                AnimationsUtil.scaleAnimationTimer = nil
                AnimationsUtil.isAnimatingPolygon = false
                return
            }
            
            if currentScale <= finalScaleFactor {
                path.removeAllCoordinates() // Mevcut yolu temizle
                
                // Her noktayı, merkezden itibaren "scale" ederek yeniden hesaplıyoruz
                for coordinate in coordinates {
                    let scaledCoordinate = CoordinatesUtil.scaleCoordinate(from: centroid, to: coordinate, scale: currentScale) //self.scaleCoordinate(from: centroid, to: coordinate, scale: currentScale)
                    path.add(scaledCoordinate)
                }
                
                // Poligonun yeni halini ayarla
                polygon.path = path
                
                // Ölçeği artır
                currentScale += scaleSteps
            } else {
                // Animasyon tamamlandı, zamanlayıcıyı durdur
                timer.invalidate()
                AnimationsUtil.scaleAnimationTimer = nil // Zamanlayıcıyı sıfırlıyoruz
                AnimationsUtil.isAnimatingPolygon = false // Animasyon tamamlandı, bayrağı sıfırlıyoruz
            }
        }
    }
     */
    
    //animate and assign polygon with animation to avoid flickering
    static func animatePolygonScaling(polygon: GMSPolygon, coordinates: [CLLocationCoordinate2D], mapView: GMSMapView) {
        let initialScaleFactor: Double = 0.3 // Initial scale
        let finalScaleFactor: Double = 1.0 // Final scale
        let scaleSteps: Double = 0.05 // Step size for scaling
        
        var currentScale = initialScaleFactor
        let centroid = CoordinatesUtil.calculateCentroid(points: coordinates) // Centroid of the polygon
        let path = GMSMutablePath()
        var isMapAssigned = false // Track if the polygon is added to the map
        
        // Timer for step-by-step scaling
        AnimationsUtil.scaleAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak polygon] timer in
            
            guard let polygon = polygon else {
                // If the polygon has been deallocated, invalidate the timer and return
                timer.invalidate()
                AnimationsUtil.scaleAnimationTimer = nil
                AnimationsUtil.isAnimatingPolygon = false
                return
            }
            
            if currentScale <= finalScaleFactor {
                path.removeAllCoordinates() // Clear existing path
                
                // Recalculate each point scaled from the centroid
                for coordinate in coordinates {
                    let scaledCoordinate = CoordinatesUtil.scaleCoordinate(from: centroid, to: coordinate, scale: currentScale)
                    path.add(scaledCoordinate)
                }
                
                // Set the new path for the polygon
                polygon.path = path
                
                // Add the polygon to the map only once when it is ready to start scaling
                if !isMapAssigned {
                    polygon.map = mapView
                    isMapAssigned = true
                }
                
                // Increment the scale
                currentScale += scaleSteps
            } else {
                // Animation complete, stop the timer
                timer.invalidate()
                AnimationsUtil.scaleAnimationTimer = nil
                AnimationsUtil.isAnimatingPolygon = false
            }
        }
    }

    
    static func animatePolygonScaling(polygon: GMSPolygon, coordinates: [CLLocationCoordinate2D], initialScale: Double, finalScale: Double, duration: TimeInterval = 1.0) {
        let scaleSteps = (finalScale - initialScale) / 30.0 // Number of steps for smooth animation
        var currentScale = initialScale
        let centroid = CoordinatesUtil.calculateCentroid(points: coordinates)
        let path = GMSMutablePath()

        AnimationsUtil.scaleAnimationTimer = Timer.scheduledTimer(withTimeInterval: duration / 30.0, repeats: true) { [weak polygon] timer in
            guard let polygon = polygon else {
                timer.invalidate()
                AnimationsUtil.scaleAnimationTimer = nil
                AnimationsUtil.isAnimatingPolygon = false
                return
            }

            if currentScale <= finalScale {
                path.removeAllCoordinates()

                for coordinate in coordinates {
                    let scaledCoordinate = CoordinatesUtil.scaleCoordinate(from: centroid, to: coordinate, scale: currentScale)
                    path.add(scaledCoordinate)
                }

                polygon.path = path
                currentScale += scaleSteps
            } else {
                timer.invalidate()
                AnimationsUtil.scaleAnimationTimer = nil
                AnimationsUtil.isAnimatingPolygon = false
            }
        }
    }

    

    static func animateOverlayScaling(overlay: GMSGroundOverlay, initialScaleFactor: Double = 0.3, finalScaleFactor: Double = 1.0, scaleSteps: Double = 0.05) {
        
        // Calculate the center and initial dimensions of the overlay
        guard let bounds = overlay.bounds else { return }
        let center = CLLocationCoordinate2D(
            latitude: (bounds.southWest.latitude + bounds.northEast.latitude) / 2,
            longitude: (bounds.southWest.longitude + bounds.northEast.longitude) / 2
        )
        
        // Calculate the initial width and height based on the original bounds
        let initialWidth = GMSGeometryDistance(bounds.southWest, CLLocationCoordinate2D(latitude: bounds.southWest.latitude, longitude: bounds.northEast.longitude))
        let initialHeight = GMSGeometryDistance(bounds.southWest, CLLocationCoordinate2D(latitude: bounds.northEast.latitude, longitude: bounds.southWest.longitude))
        
        var currentScale = initialScaleFactor
        
        // Invalidate any existing timer to avoid overlap
        AnimationsUtil.scaleCircleAnimationTimer?.invalidate()
        
        // Start the timer to scale up the overlay step by step
         Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak overlay] timer in
             
             guard let overlay = overlay else {
                 // If the overlay has been deallocated, invalidate the timer
                 timer.invalidate()
                 return
             }
             
            if currentScale <= finalScaleFactor {
                // Calculate the scaled width and height
                let scaledWidth = initialWidth * currentScale
                let scaledHeight = initialHeight * currentScale
                
                // Calculate new bounds using the scaled dimensions
                let newBounds = GMSCoordinateBounds(
                    coordinate: CLLocationCoordinate2D(latitude: center.latitude - scaledHeight / 2, longitude: center.longitude - scaledWidth / 2),
                    coordinate: CLLocationCoordinate2D(latitude: center.latitude + scaledHeight / 2, longitude: center.longitude + scaledWidth / 2)
                )
                
                // Update the overlay's bounds with the new scaled bounds
                overlay.bounds = newBounds
                
                // Increase the scale for the next step
                currentScale += scaleSteps
            } else {
                // Stop the timer when the animation is complete
                timer.invalidate()
                //AnimationsUtil.scaleCircleAnimationTimer = nil // Reset the timer in AnimationsUtil
            }
        }
    }
    
    static func synchronizePolygonAndOverlayAnimations(
        polygon: GMSPolygon,
        coordinates: [CLLocationCoordinate2D],
        overlay: GMSGroundOverlay,
        targetBounds: GMSCoordinateBounds,
        duration: TimeInterval = 1.0,
        steps: Int = 30
    ) {
        let initialScaleFactor: Double = 0.01
        let finalScaleFactor: Double = 1.0
        let scaleIncrement: Double = (finalScaleFactor - initialScaleFactor) / Double(steps)
        let targetWidth = targetBounds.northEast.longitude - targetBounds.southWest.longitude
        let targetHeight = targetBounds.northEast.latitude - targetBounds.southWest.latitude
        let widthIncrement = targetWidth / Double(steps)
        let heightIncrement = targetHeight / Double(steps)

        var currentStep = 0
        let centroid = CoordinatesUtil.calculateCentroid(points: coordinates)
        let path = GMSMutablePath()

        Timer.scheduledTimer(withTimeInterval: duration / Double(steps), repeats: true) { [weak polygon, weak overlay] timer in
            guard let polygon = polygon, let overlay = overlay else {
                timer.invalidate()
                return
            }

            // Update polygon path
            path.removeAllCoordinates()
            let currentScale = initialScaleFactor + scaleIncrement * Double(currentStep)
            for coordinate in coordinates {
                let scaledCoordinate = CoordinatesUtil.scaleCoordinate(from: centroid, to: coordinate, scale: currentScale)
                path.add(scaledCoordinate)
            }
            polygon.path = path

            // Update overlay bounds
            let newWidth = widthIncrement * Double(currentStep)
            let newHeight = heightIncrement * Double(currentStep)
            let newBounds = GMSCoordinateBounds(
                coordinate: CLLocationCoordinate2D(
                    latitude: overlay.position.latitude - newHeight / 2,
                    longitude: overlay.position.longitude - newWidth / 2
                ),
                coordinate: CLLocationCoordinate2D(
                    latitude: overlay.position.latitude + newHeight / 2,
                    longitude: overlay.position.longitude + newWidth / 2
                )
            )
            overlay.bounds = newBounds

            currentStep += 1
            if currentStep >= steps {
                timer.invalidate()
            }
        }
    }

    
    
    static func createPulseAnimation(groundOverlay: GMSGroundOverlay, placeDetails: PolygonPlaceDetails) -> UIViewPropertyAnimator? {
            
           var lastCheckinDate = ViewUtils.convertTimeStampToDate(dateStr: placeDetails.lastCheckInTimestamp)
            
            if !placeDetails.isCircle() {
                let checkins = placeDetails.places!.compactMap { ViewUtils.convertTimeStampToDate(dateStr: $0.lastCheckInTimestamp) }
                lastCheckinDate = checkins.max()
            }
           
           guard let lastCheckinDate = lastCheckinDate else {
                   return nil
               }
            
           // Calculate the time difference from now in seconds
               let now = Date()
               let elapsedTime = now.timeIntervalSince(lastCheckinDate)
               let secondsInDay: TimeInterval = 24 * 60 * 60
           
           
           if elapsedTime < secondsInDay {
               
               // Calculate remaining time until 24 hours from the last check-in
                    let remainingTimeForPulse = secondsInDay - elapsedTime
                   // MapOverlayUtility.applySmoothPulseAnimation(to: groundOverlay, scale: 0.001, duration: 2.5)
               MapOverlayUtility.applySmoothPulseAnimation(to: groundOverlay, remainingTime: remainingTimeForPulse)
                    return nil
            }
            
            return nil
        }
    
   static func coordinates(from polygonPoints: [Coordinates]) -> [CLLocationCoordinate2D] {
       return polygonPoints.map { coord in
           return CLLocationCoordinate2D(latitude: coord.latitude!, longitude: coord.longitude!)
       }
   }
    
    static func createPulseAnimation1(for groundOverlay: GMSGroundOverlay, placeDetails: PolygonPlaceDetails) -> CAAnimationGroup? {
         // Prepare the last check-in date
        var lastCheckinDate = ViewUtils.convertTimeStampToDate(dateStr: placeDetails.lastCheckInTimestamp)
         if !placeDetails.isCircle() {
             let checkins = placeDetails.places!.compactMap { ViewUtils.convertTimeStampToDate(dateStr: $0.lastCheckInTimestamp) }
             lastCheckinDate = checkins.max()
         }

         let timeZone = TimeZone.current
         let offsetInMillis = timeZone.secondsFromGMT() * 1000

         guard let lastDate = lastCheckinDate?.timeIntervalSince1970 else { return nil }
        let diff = (getDataDiffFromNow(lastCheckInTimestamp: lastDate) * 1000) - Double(offsetInMillis)

         // Create the animation only if the time difference is within a day
        if diff < Double(MILLISECONDS_IN_DAY) {
            
            let radiusStart = placeDetails.size! * 2.0
                let radiusMid = placeDetails.size! * 1.8
            let radiusEnd = placeDetails.size! * 2.0

                let radiusAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
                radiusAnimation.values = [radiusStart / radiusEnd, 1.0, radiusStart / radiusEnd]
                radiusAnimation.keyTimes = [0, 0.5, 1]
                radiusAnimation.duration = calculatePulseRate(diff: diff)

                let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
                opacityAnimation.values = [0, 1, 0]
                opacityAnimation.keyTimes = [0, 0.5, 1]
                opacityAnimation.duration = calculatePulseRate(diff: diff)

                let pulseAnimationGroup = CAAnimationGroup()
                pulseAnimationGroup.animations = [radiusAnimation, opacityAnimation]
                pulseAnimationGroup.duration = radiusAnimation.duration
                pulseAnimationGroup.repeatCount = .infinity
                pulseAnimationGroup.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

                return pulseAnimationGroup
            }
            return nil
     }

     // Helper function to calculate the pulse rate based on the time difference
    static func calculatePulseRate(diff: Double) -> CFTimeInterval {
         let pulseRate = 500 + (diff / Double(MILLISECONDS_IN_HOUR)) * 20.83
         return CFTimeInterval(pulseRate / 1000)
     }
    
    static func startPulseAnimation(for groundOverlay: GMSGroundOverlay, initialIcon: UIImage) {
        // Define pulse parameters
        let pulseDuration: TimeInterval = 1.0
        let maxScale: CGFloat = 1.2
        let minScale: CGFloat = 1.0
        var isExpanding = true

        // Start a timer to adjust the overlay size
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            let currentScale = isExpanding ? maxScale : minScale
            let scaledIcon = resizeImage(initialIcon, to: CGSize(width: initialIcon.size.width * currentScale, height: initialIcon.size.height * currentScale))

            groundOverlay.icon = scaledIcon

            // Toggle between expanding and contracting
            isExpanding.toggle()

            // Stop the timer if the overlay is removed
            if groundOverlay.map == nil {
                timer.invalidate()
            }
        }
    }
    
    // Helper function to resize an image
    static func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    static func addGroundOverlayToMap(mapView: GMSMapView, centerLatLng:CLLocationCoordinate2D, image: UIImage, zoomLevel:CGFloat, isTappable:Bool, zIndex:Int32) -> GMSGroundOverlay {
                
        let latitudeToMeters = 111132.92  // Meters per degree latitude
        let longitudeToMeters = 111412.84 * cos(centerLatLng.latitude * .pi / 180.0)

        let halfDiameterLatitudeDegrees = (zoomLevel / 2) / latitudeToMeters
        let halfDiameterLongitudeDegrees = (zoomLevel / 2) / longitudeToMeters

        let overlayBounds = GMSCoordinateBounds(
            coordinate: CLLocationCoordinate2D(latitude: centerLatLng.latitude - halfDiameterLatitudeDegrees, longitude: centerLatLng.longitude - halfDiameterLongitudeDegrees),
            coordinate: CLLocationCoordinate2D(latitude: centerLatLng.latitude + halfDiameterLatitudeDegrees, longitude: centerLatLng.longitude + halfDiameterLongitudeDegrees)
        )

        
        let groundOverlay = GMSGroundOverlay(bounds: overlayBounds, icon: image)

        groundOverlay.zIndex = zIndex
        groundOverlay.isTappable = isTappable

        groundOverlay.map = isTappable ? mapView : nil

        return groundOverlay
    }
    
   static func adjustOverlaySize(for mapView: GMSMapView, groundOverlay: GMSGroundOverlay?) {
        // Define base size (e.g., desired diameter at a specific zoom)
        let baseDiameter: CLLocationDistance = 500.0  // This is an example base diameter in meters
       let baseZoomLevel: Float = 15.0               // The zoom level at which the base diameter is ideal

        // Calculate scale factor
        let scaleFactor = pow(2, baseZoomLevel - mapView.camera.zoom)
        let adjustedDiameter = baseDiameter * Double(scaleFactor)
        
        // Adjust overlay's bounds based on adjusted diameter
        let overlayCenter = mapView.camera.target
        let overlayBounds = GMSCoordinateBounds(coordinate: overlayCenter,
                                                coordinate: coordinateWithRadius(center: overlayCenter, radius: adjustedDiameter / 2))

        // Apply new bounds to overlay
        if let overlay = groundOverlay {
            overlay.bounds = overlayBounds
        }
    }
    
   static func coordinateWithRadius(center: CLLocationCoordinate2D, radius: CLLocationDistance) -> CLLocationCoordinate2D {
        // Using a rough conversion to get coordinate offset by radius in meters
        let earthRadius = 6378137.0  // Earth’s radius in meters

        let latDelta = radius / earthRadius * (180.0 / .pi)
        let lngDelta = radius / (earthRadius * cos(center.latitude * .pi / 180.0)) * (180.0 / .pi)

        return CLLocationCoordinate2D(latitude: center.latitude + latDelta, longitude: center.longitude + lngDelta)
    }


    //Mark : - Store Animation
    static func startOverlayAnimation(for overlay: GMSGroundOverlay, targetBounds: GMSCoordinateBounds, duration: TimeInterval = 1.0, steps: Int = 30) {
        
        // Define very small initial bounds around the overlay's position
        let initialCoordinate = overlay.position
        let smallBounds = GMSCoordinateBounds(
            coordinate: CLLocationCoordinate2D(latitude: initialCoordinate.latitude - 0.00001, longitude: initialCoordinate.longitude - 0.00001),
            coordinate: CLLocationCoordinate2D(latitude: initialCoordinate.latitude + 0.00001, longitude: initialCoordinate.longitude + 0.00001)
        )
        
        // Set initial small bounds
        overlay.bounds = smallBounds
        
        // Calculate target dimensions
        let targetWidth = targetBounds.northEast.longitude - targetBounds.southWest.longitude
        let targetHeight = targetBounds.northEast.latitude - targetBounds.southWest.latitude
        
        // Calculate increments for animation
        let widthIncrement = targetWidth / Double(steps)
        let heightIncrement = targetHeight / Double(steps)
        
        var currentStep = 0
        
        // Timer to animate in increments
        Timer.scheduledTimer(withTimeInterval: duration / Double(steps), repeats: true) { [weak overlay] timer in
            
            guard let overlay = overlay else {
                // If the overlay has been deallocated, invalidate the timer
                timer.invalidate()
                return
            }
            
            currentStep += 1
            let newWidth = widthIncrement * Double(currentStep)
            let newHeight = heightIncrement * Double(currentStep)
            
            // Update bounds for each step based on overlay position
            let newBounds = GMSCoordinateBounds(
                coordinate: CLLocationCoordinate2D(
                    latitude: overlay.position.latitude - newHeight / 2,
                    longitude: overlay.position.longitude - newWidth / 2),
                coordinate: CLLocationCoordinate2D(
                    latitude: overlay.position.latitude + newHeight / 2,
                    longitude: overlay.position.longitude + newWidth / 2)
            )
            
            overlay.bounds = newBounds
            
            // Stop animation at the last step
            if currentStep >= steps {
                timer.invalidate()
            }
        }
    }
}


//MARK: Animatin Delegate
// Helper class for handling animation delegation
class AnimationDelegate: NSObject, CAAnimationDelegate {
    private let onStart: () -> Void
    private let onEnd: () -> Void
    private let onRepeat: () -> Void
    var updateCallback: ((Float) -> Void)?
    
    private var startTime: CFTimeInterval?
    private var duration: CFTimeInterval = 1.0 // Default duration, should be set appropriately
    
    init(onStart: @escaping () -> Void, onEnd: @escaping () -> Void, onRepeat: @escaping () -> Void) {
        self.onStart = onStart
        self.onEnd = onEnd
        self.onRepeat = onRepeat
    }
    
    func animationDidStart(_ anim: CAAnimation) {
        onStart()
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            onEnd()
        }
    }
    
    func animationDidRepeat(_ anim: CAAnimation) {
        onRepeat()
    }
    
    @objc func updateAnimation(displayLink: CADisplayLink) {
        guard let startTime = startTime else { return }
        let currentTime = CACurrentMediaTime()
        let elapsedTime = currentTime - startTime
        let fraction = min(max(Float(elapsedTime / duration), 0.0), 1.0) // Clamp between 0 and 1
        updateCallback?(fraction)
    }
    
}
