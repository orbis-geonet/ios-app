//
//  PanGestureManager.swift
//  Orbis-iOS
//
//  Created by Kamran on 24/10/2024.
//


import UIKit
import GoogleMaps
/*
class PanGestureManager: NSObject, UIGestureRecognizerDelegate {
    private var sliderCenterConstraint: NSLayoutConstraint!
    private var mapView: GMSMapView
    private let initialZoom: Float
    private let minZoom: Float
    private let maxZoom: Float

    init(leftSlider: UIView, rightSlider: UIView, sliderCenterConstraint: NSLayoutConstraint, mapView: GMSMapView, initialZoom: Float = 12.0, minZoom: Float = 10.0, maxZoom: Float = 18.0) {
        self.sliderCenterConstraint = sliderCenterConstraint
            
        self.mapView = mapView
        self.initialZoom = initialZoom
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        super.init()
        addPanGesture(to: leftSlider)
        addPanGesture(to: rightSlider)
    }
    
    private func addPanGesture(to slider: UIView) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        slider.addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let view = sender.view else { return }
        
        
        switch sender.state {
        case .changed:
            // Calculate the change based on the user's pan gesture
            let translation = sender.translation(in: view)
            
            // Reverse the direction by multiplying by -1 to fix opposite direction issue
            sliderCenterConstraint.constant -= translation.y * -1
            
            // Reset the translation to avoid compounding
            sender.setTranslation(.zero, in: view)
            
            // Update the map zoom based on the slider movement
            updateMapZoomBasedOnSlider()
            
        case .ended:
            // Reset the slider to its initial position
            resetSliderToInitialPosition()
        default:
            break
        }
    }
    
    // Method to reset the slider to its initial position
    private func resetSliderToInitialPosition() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.sliderCenterConstraint.constant = 0
            // Call layoutIfNeeded to apply the changes immediately
            self.sliderCenterConstraint.firstItem?.superview?.layoutIfNeeded()
        }
    }
    
    // Method to update map zoom level based on the slider movement
    private func updateMapZoomBasedOnSlider() {
        // Calculate the new zoom level based on slider position and predefined limits
        let normalizedZoomChange = max(min(sliderCenterConstraint.constant / 100.0, 1.0), -1.0)  // Normalize to a range of [-1, 1]
        let zoomChange = Float(normalizedZoomChange) * (maxZoom - minZoom)
        let newZoom = max(min(initialZoom + zoomChange, maxZoom), minZoom)  // Keep zoom within bounds
        
        // Apply the new zoom to the mapView
        mapView.animate(toZoom: newZoom)
    }
    
    // MARK: - UIGestureRecognizerDelegate Methods
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // If the touch is on the UITableView or UISearchBar, ignore the gesture
        if touch.view is UITableView || touch.view is UISearchBar || touch.view is UITextField {
            return false
        }
        return true
    }
}
*/

class PanGestureManager: NSObject, UIGestureRecognizerDelegate {
    
    var isDraggingMapViewCallBack: ((Bool) -> Void)?
    var mapViewZoomCallBack: ((Float) -> Void)?
    private(set) var isDragging: Bool = false // Readable outside but settable only within this class

    private var sliderCenterConstraint: NSLayoutConstraint!
    private var currentZoom: Float
    private let minZoom: Float
    private let maxZoom: Float
    private let sliderRange: CGFloat // The range of movement for the sliders
    private var currentZoomOffset: CGFloat = 0.0 // Tracks the cumulative zoom offset

    func setCurrentZoom(zoom : Float)  {
        currentZoom = zoom
    }
    
    init(
        leftSlider: UIView,
        rightSlider: UIView,
        sliderCenterConstraint: NSLayoutConstraint,
        initialZoom: Float = 11.5,
        minZoom: Float = 2.8,
        maxZoom: Float = 21.0
    ) {
        self.sliderCenterConstraint = sliderCenterConstraint
        self.currentZoom = initialZoom
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.sliderRange = UIScreen.main.bounds.size.height
        super.init()
        addPanGesture(to: leftSlider)
        addPanGesture(to: rightSlider)
        
        resetSliderToInitialPosition()
    }
    
    func resetSliderToInitialPosition() {
        // Calculate the zoom range
        let zoomRange = maxZoom - minZoom
        
        // Map the current zoom level to the normalized range [-1.0, 1.0]
        let normalizedZoom = (currentZoom - minZoom) / zoomRange * 2.0 - 1.0
        
        // Correctly calculate the corresponding `currentZoomOffset` for the slider range
        currentZoomOffset = CGFloat(-normalizedZoom) * (sliderRange / 2.0)
        
        // Ensure the `currentZoomOffset` stays within the valid slider range
        currentZoomOffset = max(min(currentZoomOffset, sliderRange / 2.0), -sliderRange / 2.0)
        
        //print("Normalized Zoom: \(normalizedZoom), Current Zoom Offset: \(currentZoomOffset)")

        // Reset the slider visually to the center position
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) { [weak self] in
            self?.sliderCenterConstraint.constant = 0
            self?.sliderCenterConstraint.firstItem?.superview?.layoutIfNeeded()
        }
    }


    private func addPanGesture(to slider: UIView) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        slider.addGestureRecognizer(panGesture)
    }

    @objc private func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let view = sender.view else { return }

        switch sender.state {
        case .began:
            // Record the current zoom level when the gesture starts
            //currentZoom = mapManager.mapView?.camera.zoom ?? 12
            isDragging = true
            isDraggingMapViewCallBack?(true)
        case .changed:
            
            // Calculate vertical translation and update the slider constraint
            let translation = sender.translation(in: view).y
           
            // Update slider constraint, clamped to the defined slider range
            sliderCenterConstraint.constant = max(min(sliderCenterConstraint.constant + translation, sliderRange), -sliderRange)
            
            currentZoomOffset = max(min(currentZoomOffset + translation, sliderRange), -sliderRange)
            
            // Reset translation to avoid compounding
            sender.setTranslation(.zero, in: view)

            // Adjust map zoom based on the slider's position
            updateMapZoomBasedOnSlider()
            
        case .ended, .cancelled:
            // Reset the slider to its initial position after the gesture ends
            isDragging = false
            self.isDraggingMapViewCallBack?(false)
            self.resetSliderToInitialPosition()
            
        default:
            break
        }
    }
    
    private func updateMapZoomBasedOnSlider() {
        // Adjust the slider offset
        let adjustedZoomOffset = currentZoomOffset
        
        // Normalize the adjusted slider offset to a range between -1.0 and 1.0
        let normalizedOffset = Float(adjustedZoomOffset / (sliderRange / 2.0)) // Normalize based on slider range
        
        // Reverse the normalized offset to ensure correct zoom direction
        let reversedNormalizedOffset = -normalizedOffset

        // Map the reversed normalized offset to the zoom range [minZoom, maxZoom]
        let zoomRange = maxZoom - minZoom
        let newZoom = min(max(minZoom + (reversedNormalizedOffset + 1.0) / 2.0 * zoomRange, minZoom), maxZoom) // Clamp to zoom bounds

        //print("Reversed Offset: \(reversedNormalizedOffset), New Zoom: \(newZoom), Current Offset: \(currentZoomOffset)")

        // Avoid jitter by adding a small tolerance
        if abs(newZoom - currentZoom) > 0.01 {
            currentZoom = newZoom
            mapViewZoomCallBack?(newZoom)
        }
    }

    // MARK: - UIGestureRecognizerDelegate Methods
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Prevent gestures from conflicting with other UI elements
        if touch.view is UITableView || touch.view is UISearchBar || touch.view is UITextField {
            return false
        }
        return true
    }
}

