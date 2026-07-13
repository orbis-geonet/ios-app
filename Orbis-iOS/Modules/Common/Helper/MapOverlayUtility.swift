//
//  MapOverlayUtility.swift
//  Orbis-iOS
//
//  Created by Kamran on 30/11/2024.
//
/*
import GoogleMaps
import UIKit

class MapOverlayUtility {

    static func applySmoothPulseAnimation(to overlay: GMSGroundOverlay, scale: Double = 0.0003, duration: TimeInterval = 1.2, remainingTime : TimeInterval!) {
        // Store initial bounds of the overlay
        let initialBounds = overlay.bounds
        
        guard let initialSouthWest = initialBounds?.southWest, let initialNorthEast = initialBounds?.northEast else {
            return
        }
        

        
        // Create a reference to the pulse timer so it can be stopped later
        
        
        // Use Timer to create a smooth pulse effect by updating the bounds
       let pulseTimer = Timer.scheduledTimer(withTimeInterval: 0.0, repeats: true) { [weak overlay] timer in
           
           guard let overlay = overlay else {
               timer.invalidate()
               return
           }
           
            let elapsedTime = Date().timeIntervalSince1970
            let scaleDelta = scale * (sin(elapsedTime * .pi * 2 / duration) + 1) / 2

            let newSouthWest = CLLocationCoordinate2D(
                latitude: initialSouthWest.latitude - scaleDelta,
                longitude: initialSouthWest.longitude - scaleDelta
            )
            let newNorthEast = CLLocationCoordinate2D(
                latitude: initialNorthEast.latitude + scaleDelta,
                longitude: initialNorthEast.longitude + scaleDelta
            )

            let newBounds = GMSCoordinateBounds(coordinate: newSouthWest, coordinate: newNorthEast)
            overlay.bounds = newBounds
        }
        
        // Schedule a timer to stop the pulse animation after `remainingTime`
            Timer.scheduledTimer(withTimeInterval: remainingTime, repeats: false) { [weak pulseTimer] _ in
                pulseTimer?.invalidate() // Stop the pulse timer after the remaining time has elapsed
            }
    }
}
 */

import GoogleMaps
import QuartzCore

class MapOverlayUtility {
    
    static func applySmoothPulseAnimation(
        to overlay: GMSGroundOverlay,
        scale: Double = 0.0005, // Increased for a faster pulse
        duration: TimeInterval = 0.7, // Reduced duration for faster cycle
        remainingTime: TimeInterval!
    ) {
        // Store initial bounds of the overlay
        let initialBounds = overlay.bounds
        
        guard let initialSouthWest = initialBounds?.southWest, let initialNorthEast = initialBounds?.northEast else {
            return
        }
        /*
        if !MapOverlayUtility.isDeviceCapableOfRunningiOS17() {
            if !MapOverlayUtility.isRunningiOS17OrHigher() {
                MapOverlayUtility.applySmoothPulseAnimationForLowDevice(to: overlay, remainingTime: remainingTime)
                return
            }
        }else{
            print("not called")
        }
         */
        
        let startTime = Date()
        var elapsedTime: TimeInterval = 0
        
        // Create a CADisplayLink for smooth frame updates
        let displayLink = CADisplayLink(target: AnimationHandler(
            animationBlock: { [weak overlay] frameTime in
                guard let overlay = overlay else { return true }
                
                elapsedTime = Date().timeIntervalSince(startTime)
                if elapsedTime >= remainingTime {
                    return true // Stop the animation
                }
                
                // Faster easing function for a sharp pulse
                let normalizedTime = (elapsedTime.truncatingRemainder(dividingBy: duration)) / duration
                let pulseFactor = pow(sin(normalizedTime * .pi), 2) // Sharper easing
                
                let scaleDelta = scale * pulseFactor
                
                let newSouthWest = CLLocationCoordinate2D(
                    latitude: initialSouthWest.latitude - scaleDelta,
                    longitude: initialSouthWest.longitude - scaleDelta
                )
                let newNorthEast = CLLocationCoordinate2D(
                    latitude: initialNorthEast.latitude + scaleDelta,
                    longitude: initialNorthEast.longitude + scaleDelta
                )
                
                let newBounds = GMSCoordinateBounds(coordinate: newSouthWest, coordinate: newNorthEast)
                overlay.bounds = newBounds
                
                return false // Continue the animation
            }
        ), selector: #selector(AnimationHandler.handleFrame))
        
       
        displayLink.add(to: .main, forMode: .common)
        
        // Stop the display link after the remaining time has elapsed
        DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
            displayLink.invalidate()
        }
    }

    
    // Helper class to encapsulate the CADisplayLink animation logic
    private class AnimationHandler {
        private let animationBlock: (TimeInterval) -> Bool
        
        init(animationBlock: @escaping (TimeInterval) -> Bool) {
            self.animationBlock = animationBlock
        }
        
        @objc func handleFrame(displayLink: CADisplayLink) {
            let frameTime = displayLink.targetTimestamp
            if animationBlock(frameTime) {
                displayLink.invalidate()
            }
        }
    }
}

extension MapOverlayUtility {
    
    private static func getDeviceModelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    private static func isDeviceCapableOfRunningiOS17() -> Bool {
        let modelName = getDeviceModelName()
        
        // List of model identifiers for devices that can run iOS 17
//        let iOS17CapableDevices = [
//            "iPhone10", // iPhone 8, 8 Plus, X
//            "iPhone11", // iPhone XR, XS, XS Max
//            "iPhone12", // iPhone 11, 11 Pro, 11 Pro Max
//            "iPhone13", // iPhone 12, 12 Pro, 12 Mini, 12 Pro Max
//            "iPhone14", // iPhone 13, 13 Pro, 13 Mini, 13 Pro Max
//            "iPhone15", // iPhone 14, 14 Pro, 14 Plus, 14 Pro Max
//            "iPhone16", // iPhone 15, 15 Pro, 15 Pro Max
//            "iPad8",    // iPad Pro 4th Gen
//            "iPad9",    // iPad Pro 5th Gen
//            "iPad10",   // iPad 10th Gen
//            "iPad11",   // iPad Air 4th Gen
//            "iPad12",   // iPad Air 5th Gen
//            "iPad13",   // iPad Mini 6th Gen
//            "iPad14"    // iPad Pro 6th Gen
//        ]
        
        let iOS17CapableDevices = [
            "iPhone11", // iPhone XR, XS, XS Max
            "iPhone12", // iPhone 11, 11 Pro, 11 Pro Max
            "iPhone13", // iPhone 12, 12 Pro, 12 Mini, 12 Pro Max
            "iPhone14", // iPhone 13, 13 Pro, 13 Mini, 13 Pro Max
            "iPhone15", // iPhone 14, 14 Pro, 14 Plus, 14 Pro Max
            "iPhone16", // iPhone 15, 15 Pro, 15 Pro Max
            "iPad8",    // iPad Pro 4th Gen
            "iPad9",    // iPad Pro 5th Gen
            "iPad10",   // iPad 10th Gen
            "iPad11",   // iPad Air 4th Gen
            "iPad12",   // iPad Air 5th Gen
            "iPad13",   // iPad Mini 6th Gen
            "iPad14"    // iPad Pro 6th Gen
        ]
        
        // Check if the current device model is in the list
        return iOS17CapableDevices.contains { modelName.hasPrefix($0) }
    }
    
   private static func isRunningiOS17OrHigher() -> Bool {
        // Access the operating system version
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        
        // Check if the major version is 17 or higher
        return osVersion.majorVersion >= 17
    }
    
    static func applySmoothPulseAnimationForLowDevice(to overlay: GMSGroundOverlay, scale: Double = 0.0003, duration: TimeInterval = 1.2, remainingTime : TimeInterval!) {
        // Store initial bounds of the overlay
        let initialBounds = overlay.bounds
        
        guard let initialSouthWest = initialBounds?.southWest, let initialNorthEast = initialBounds?.northEast else {
            return
        }
        
        // Create a reference to the pulse timer so it can be stopped later
        
        // Use Timer to create a smooth pulse effect by updating the bounds
       let pulseTimer = Timer.scheduledTimer(withTimeInterval: 0.0, repeats: true) { [weak overlay] timer in
           
           guard let overlay = overlay else {
               timer.invalidate()
               return
           }
           
            let elapsedTime = Date().timeIntervalSince1970
            let scaleDelta = scale * (sin(elapsedTime * .pi * 2 / duration) + 1) / 2

            let newSouthWest = CLLocationCoordinate2D(
                latitude: initialSouthWest.latitude - scaleDelta,
                longitude: initialSouthWest.longitude - scaleDelta
            )
            let newNorthEast = CLLocationCoordinate2D(
                latitude: initialNorthEast.latitude + scaleDelta,
                longitude: initialNorthEast.longitude + scaleDelta
            )

            let newBounds = GMSCoordinateBounds(coordinate: newSouthWest, coordinate: newNorthEast)
            overlay.bounds = newBounds
        }
        
        // Schedule a timer to stop the pulse animation after `remainingTime`
            Timer.scheduledTimer(withTimeInterval: remainingTime, repeats: false) { [weak pulseTimer] _ in
                pulseTimer?.invalidate() // Stop the pulse timer after the remaining time has elapsed
            }
    }
}





