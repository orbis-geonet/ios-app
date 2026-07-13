//
//  OrbisMapMarker.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/03/2021.
//

import Foundation
import GoogleMaps
import SDWebImage
import UIKit
import Combine
import CoreLocation

protocol OrbisMapMarkerImageDelegate: AnyObject {
    func didCompleteImageDownload(forUrl urlString: String, image: UIImage, marker: OrbisMapOverlayMarker)
}

protocol OrbisMapMarkerCleanupDelegate: AnyObject {
    func shouldRemoveMarker(withKey: String)
}

class OrbisMapOverlayMarker: GMSGroundOverlay {
    var mapPlaceBaseColor: UIColor!
    var mapPlaceId: String!
    var placeCoordinate: CLLocationCoordinate2D!
    var lastCheckinTimeStamp: Date! {
        didSet {
            onLastCheckinUpdate?(lastCheckinTimeStamp)
        }
    }
    var radius: CLLocationDistance!
    var fixedRadius: CLLocationDistance! {
        didSet {
            pulseMaxSize = (maxSizeReference / referenceRadius) * fixedRadius
            increment = (maxSizeReference * 0.15 / referenceRadius) * fixedRadius
        }
    }
    var onLastCheckinUpdate: ((Date) -> Void)?
    
    private var pulseMaxSize: CLLocationDistance = 100
    var increment: CLLocationDistance = 10
    private let maxSizeReference: CLLocationDistance = 100
    private let referenceRadius: CLLocationDistance = 500
    var fixedOpacity: Float = 1
    var isProgressing = true
    var imageUrlName: String = ""
    
    init(bounds: GMSCoordinateBounds, icon: UIImage?, radius: CLLocationDistance) {
        super.init()
        self.bounds = bounds
        self.icon = icon
        self.radius = radius
        self.fixedRadius = radius
        pulseMaxSize = (maxSizeReference / referenceRadius) * radius
        increment = (maxSizeReference * 0.1 / referenceRadius) * radius
    }
    
    func animatePulse() -> CLLocationDistance {
        let upperBound = fixedRadius + pulseMaxSize
        let lowerBound = fixedRadius!
        if isProgressing {
            if self.radius + increment > upperBound {
                self.radius = upperBound
                isProgressing = false
            }
            else {
                self.radius += increment
            }
        }
        else {
            if self.radius - increment < lowerBound {
                self.radius = lowerBound
                isProgressing = true
            }
            else {
                self.radius -= increment
            }
        }
        let topLeftCoordinate = CLHelper.coordinate(from: placeCoordinate!, distance: -radius!)
        let bottomRightCoordinate = CLHelper.coordinate(from: placeCoordinate!, distance: radius!)
        self.bounds = GMSCoordinateBounds(coordinate: topLeftCoordinate, coordinate: bottomRightCoordinate)
        return self.radius
    }
    
}

class OrbisMapOverlayCircle: GMSCircle {
    var mapPlaceBaseColor: UIColor!
    var mapPlaceId: String!
    var fixedRadius: CLLocationDistance!
    var fixedOpacity: CGFloat = 1
    var isProgressing = true
    
    init(position: CLLocationCoordinate2D, radius: CLLocationDistance) {
        super.init()
        self.position = position
        self.radius = radius
        self.fixedRadius = radius
    }
    
    func animatePulse(withNewRadius radius: CLLocationDistance) {
        let borderWithRatio = Double(30.0 / 500.0) * radius
        self.radius = radius + borderWithRatio
    }
}

class OrbisMapMarker: GMSMarker {
    var mapPlaceId: String!
}

class OrbisMarkerContainer {
    var marker: OrbisMapOverlayMarker!
    
    //
    private let formatter = ISOCommonFormatter.shared
    private var bag: Set<AnyCancellable> = []
    //
    
    var lastCheckinDate: Date!
    var pulseTimer = Timer()
    private let minOneCyclePulseTime: Double = 0.02
    var sizeChangeTime: Double = 0.02
    var isNewlyCreatedPlace: Bool = false
    var isBubblyAnimating: Bool = false
    var isSizeChangeAnimation = false
    
    var mapPlaceBaseColor: UIColor {
        return marker.mapPlaceBaseColor
    }
    var mapPlaceId: String {
        return marker.mapPlaceId
    }
    //lazy var imageView: UIImageView = UIImageView()
    weak var imageDelegate: OrbisMapMarkerImageDelegate?
    weak var cleanupDelegate: OrbisMapMarkerCleanupDelegate?
    
    private var shouldPulsate: Bool {
        return elapsedTime <= AppValues.DateTime.twentyFourHoursInSeconds
    }
    
    private var elapsedTime: Double {
        return Date().timeIntervalSince1970 - lastCheckinDate.timeIntervalSince1970
    }
    
    var pulseDuration: Double {
        if isSizeChangeAnimation || isBubblyAnimating {
            return sizeChangeTime
        }
        if elapsedTime <= 0 {
            return minOneCyclePulseTime
        }
        var duration = (((elapsedTime / AppValues.DateTime.twentyFourHoursInSeconds) * 0.8) + minOneCyclePulseTime)
        if duration > (9 * minOneCyclePulseTime) {
            duration = 9 * minOneCyclePulseTime
        }
        return duration
    }
    
    init(marker: OrbisMapOverlayMarker, inMap map: GMSMapView, mapPosition: Published<GMSCameraPosition?>.Publisher? = nil, orbisPlace: OrbisPlace? = nil, selectedMarker: Published<OrbisMapOverlayMarker?>.Publisher? = nil, isNewlyCreatedPlace: Bool, imageDelegate: OrbisMapMarkerImageDelegate? = nil, cleanupDelegate: OrbisMapMarkerCleanupDelegate? = nil) {
        marker.onLastCheckinUpdate = {
            [weak self] date in
            self?.lastCheckinDate = date
        }
        if isNewlyCreatedPlace {
            marker.radius = 0
            let topLeftCoordinate = CLHelper.coordinate(from: marker.placeCoordinate!, distance: -0)
            let bottomRightCoordinate = CLHelper.coordinate(from: marker.placeCoordinate!, distance: 0)
            marker.bounds = GMSCoordinateBounds(coordinate: topLeftCoordinate, coordinate: bottomRightCoordinate)
        }
        self.lastCheckinDate = marker.lastCheckinTimeStamp
        self.marker = marker
        self.imageDelegate = imageDelegate
        self.cleanupDelegate = cleanupDelegate
        
        //
        if let orbisPlace = orbisPlace {
            updateImage(withUrl: orbisPlace.dominantGroup?.imageName ?? "",
                        placeholder: OrbisMapPlaceIconManager.shared.placeIcons[orbisPlace.placeType]!)
        }
        
        mapPosition?
            .sink { [weak self] newPosition in
                guard let self = self, let position = newPosition, let orbisPlace = orbisPlace else { return }
                let size = orbisPlace.calculatedSize(with: self.formatter)
                guard size > 0 else { return }
                let fixedRadius = AppValues.mapFetchDistanceInKM * 1000
                var visibleRadius = min(fixedRadius, map.getRadius())
//                visibleRadius = max(visibleRadius, AppValues.mapMinVisibleDistanceInKM * 1000)
                let removeRadius = AppValues.removeRadiusInMeters
                let mapCenter = position.target
                let mapCenterLoc = CLLocation(latitude: mapCenter.latitude, longitude: mapCenter.longitude)
                if (AppValues.isCurrentDeviceIpad) {
                    visibleRadius = visibleRadius * 0.5
                }
                
                let isVisibleSizeCriteriaMet = (map.getRadius() / size) < AppValues.markersVisibilityFactor
                let isWithinVisibleRange = orbisPlace.isWithinVisibleRange(mapView: map, ofDistance: visibleRadius, fromCoordinates: mapCenterLoc)
                let shouldRemoveContainer = !orbisPlace.isWithinVisibleRange(mapView: map, ofDistance: visibleRadius * 1, fromCoordinates: mapCenterLoc)
                
                print("+++ visible size (\(size)) criteria at radius \(map.getRadius()): \(visibleRadius / size)")
                
                if isVisibleSizeCriteriaMet && isWithinVisibleRange {
                    print("+++ should be visible")
                    if marker.map == nil {
                        DispatchQueue.main.async {
                            marker.map = map
                            isNewlyCreatedPlace ? self.showBubblyAnimationAndPulsate() : self.startPulsate()
                        }
                    }
                    self.updateImage(withUrl: orbisPlace.dominantGroup?.imageName ?? "",
                                     placeholder: OrbisMapPlaceIconManager.shared.placeIcons[orbisPlace.placeType]!)
                    
                } else {
                    print("+++ shouldn't be visible")
                    if marker.map != nil {
                        DispatchQueue.main.async {
                            marker.map = nil
                        }
                        self.cleanupDelegate?.shouldRemoveMarker(withKey: marker.mapPlaceId)
                    }
                }
                
                if shouldRemoveContainer {
                    DispatchQueue.main.async {
                        self.marker.map = nil
                    }
                    self.cleanupDelegate?.shouldRemoveMarker(withKey: marker.mapPlaceId)
                }
            }
            .store(in: &bag)
        
        selectedMarker?
            .sink { selectedMarker in
                guard let selectedMarker = selectedMarker else {
//                    marker.opacity = 1
//                    marker.fixedOpacity = 1
                    return
                }
                
                if selectedMarker.mapPlaceId == marker.mapPlaceId {
                    marker.opacity = 1
                    marker.fixedOpacity = 1
                } else {
                    marker.opacity = 0.1
                    marker.fixedOpacity = 0.1
                }
            }
            .store(in: &bag)
        //
    }
    
    deinit { print("+++ marker removed") }
    
    func showBubblyAnimationAndPulsate() {
        isBubblyAnimating = true
        sizeChangeTime = (abs(0 - marker.fixedRadius) / marker.fixedRadius) * 0.015
        marker.isProgressing = true
        self.startPulsate()
    }
    
    func animateSizeChange(newSize clDistance: CLLocationDistance) {
        self.stopPulsate()
        isSizeChangeAnimation = true
        sizeChangeTime = (abs(clDistance - marker.fixedRadius) / marker.fixedRadius) * 0.02
        marker.isProgressing = marker.radius < clDistance
        marker.fixedRadius = clDistance
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] timer in
            self?.startPulsate()
            timer.invalidate()
        }
    }
    
    func startPulsate() {
        pulseTimer.invalidate()
        guard shouldPulsate || isBubblyAnimating || isSizeChangeAnimation else {
            self.stopPulsate()
            return
        }
        DispatchQueue.main.async {
            [weak self] in
            guard let self = self else { return }
            self.pulseTimer = Timer.scheduledTimer(withTimeInterval: self.pulseDuration, repeats: false, block: { [weak self] timer in
                guard let self = self else { return }
                let newRadius = self.marker.animatePulse()
                if (newRadius >= self.marker.fixedRadius) && self.isBubblyAnimating == true {
                    self.isBubblyAnimating = false
                }
                if (newRadius <= self.marker.fixedRadius) && self.isSizeChangeAnimation == true {
                    self.isSizeChangeAnimation = false
                }
                self.startPulsate()
            })
        }
    }
    
    func stopPulsate() {
        pulseTimer.invalidate()
        self.marker.radius = self.marker.fixedRadius
        self.marker.opacity = self.marker.fixedOpacity
        _ = self.marker.animatePulse()
    }
    
    func updateImage(withUrl urlString: String, placeholder: UIImage) {
        if let image = SDImageCache.shared.imageFromCache(forKey: urlString.mapUrlPostfix + "_\(self.mapPlaceBaseColor.toHexString())") {
            self.imageDelegate?.didCompleteImageDownload(forUrl: urlString, image: image, marker: self.marker)
            return
        }
        
        if urlString.isNotUrlLink {
            let ref = urlString.getFirebaseReference(storage: .groupPictures, imageSizeResolution: .twoHundred)
            
            ref.getData(maxSize: Int64(AppValues.tenMBinBytes)) { [weak self] result in
                switch result {
                case .success(let data):
                    let image = UIImage(data: data)
                    if let image = image {
                        self?.handleImageDownloadSuccess(withImage: image, andURL: urlString)
                    } else {
                        self?.handleImageDownloadFailure(withPlaceholder: placeholder)
                    }
                case .failure(_):
                    self?.handleImageDownloadFailure(withPlaceholder: placeholder)
                }
            }
            
//            imageView.sd_setImage(with: ref, maxImageSize: UInt64(AppValues.tenMBinBytes), placeholderImage: placeholder, options: [.avoidAutoSetImage, .retryFailed]) {
//                [weak self] image,err,_,_ in
//                guard let self = self else { return }
//
//                if let image = image {
//                    self.handleImageDownloadSuccess(withImage: image, andURL: urlString)
//                } else {
//                    self.handleImageDownloadFailure(withPlaceholder: placeholder)
//                }
//            }
        } else {
            SDImageLoadersManager.shared.requestImage(with: URL(string: urlString),
                                                      options: [.avoidAutoSetImage, .retryFailed],
                                                      context: [:], progress: nil)
            { [weak self] image, _, error, _ in
                if let image = image {
                    self?.handleImageDownloadSuccess(withImage: image, andURL: urlString)
                } else {
                    self?.handleImageDownloadFailure(withPlaceholder: placeholder)
                }
            }
//            imageView.sd_setImage(with: URL(string: urlString), placeholderImage: placeholder, options: [.avoidAutoSetImage, .retryFailed]) {
//                [weak self] image,_,_,_ in
//                guard let self = self else { return }
//
//                if let image = image {
//                    self.handleImageDownloadSuccess(withImage: image, andURL: urlString)
//                } else {
//                    self.handleImageDownloadFailure(withPlaceholder: placeholder)
//                }
//            }
        }
    }
    
    func setPalceDetailProfilePicture(withUrl urlString: String, placeholder: UIImage) {
        if urlString.isNotUrlLink {
            let ref = urlString.getFirebaseReference(storage: .placePictures, imageSizeResolution: .fourHundred)
            
            ref.getData(maxSize: Int64(AppValues.tenMBinBytes)) { [weak self] result in
                switch result {
                case .success(let data):
                    let image = UIImage(data: data)
                    if let image = image {
                        self?.self.handlePlaceDetailProfileImageSuccess(withImage: image)
                    } else {
                        self?.handleImageDownloadFailure(withPlaceholder: placeholder)
                    }
                case .failure(_):
                    self?.handleImageDownloadFailure(withPlaceholder: placeholder)
                }
            }
//            imageView.sd_setImage(with: ref, maxImageSize: UInt64(AppValues.tenMBinBytes), placeholderImage: placeholder, options: [.avoidAutoSetImage, .retryFailed]) {
//                [weak self] image,err,_,_ in
//                guard let self = self else { return }
//
//                if let image = image {
//                    self.handlePlaceDetailProfileImageSuccess(withImage: image)
//                } else {
//                    self.handleImageDownloadFailure(withPlaceholder: placeholder)
//                }
//            }
        } else {
            SDImageLoadersManager.shared.requestImage(with: URL(string: urlString),
                                                      options: [.avoidAutoSetImage, .retryFailed],
                                                      context: [:], progress: nil)
            { [weak self] image, _, error, _ in
                if let image = image {
                    self?.handlePlaceDetailProfileImageSuccess(withImage: image)
                } else {
                    self?.handleImageDownloadFailure(withPlaceholder: placeholder)
                }
            }
//            imageView.sd_setImage(with: URL(string: urlString), placeholderImage: placeholder, options: [.avoidAutoSetImage, .retryFailed]) {
//                [weak self] image,_,_,_ in
//                guard let self = self else { return }
//
//                if let image = image {
//                    self.handlePlaceDetailProfileImageSuccess(withImage: image)
//                } else {
//                    self.handleImageDownloadFailure(withPlaceholder: placeholder)
//                }
//            }
        }
    }
    
    private func handleImageDownloadSuccess(withImage image: UIImage, andURL urlString: String) {
        //
//        let imageSignature = ImageSignatureVerifier.getSignature(of: image)
//        if let image = SDImageCache.shared.imageFromCache(forKey: imageSignature) {
//            print("+++ Cache fired")
//            imageDelegate?.didCompleteImageDownload(forUrl: urlString, image: image, marker: marker)
//        }
        //
        print("+++ img dwnld sccs")
        var img = image
        if img.size.width > AppValues.maxMapImageWidthHeight {
            img = img.resizeImage(targetSize: CGSize(width: AppValues.maxMapImageWidthHeight, height: AppValues.maxMapImageWidthHeight))
        }
        let image = img.makeRoundImg(with: mapPlaceBaseColor, borderWidth: 10.toCGFloat)!
        
        DispatchQueue.main.async { [weak self] in
            self?.marker.icon = image
        }
        
        SDImageCache.shared.store(image, forKey: urlString.mapUrlPostfix + "_\(mapPlaceBaseColor.toHexString())", completion: nil)
        imageDelegate?.didCompleteImageDownload(forUrl: urlString, image: image, marker: marker)
    }
    
    private func handleImageDownloadFailure(withPlaceholder placeholder: UIImage) {
        print("+++ dnld failed")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.marker.icon = placeholder
        }
    }
    
    private func handlePlaceDetailProfileImageSuccess(withImage image: UIImage) {
        var img = image
        if img.size.width > AppValues.maxMapImageWidthHeight {
            img = img.resizeImage(targetSize: CGSize(width: AppValues.maxMapImageWidthHeight, height: AppValues.maxMapImageWidthHeight))
        }
        let image = img.makeRoundImg(with: mapPlaceBaseColor, borderWidth: 10.toCGFloat)!
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.marker.icon = image
        }
    }
}

extension GMSCircle {
    func bounds () -> GMSCoordinateBounds {
        func locationMinMax(_ positive : Bool) -> CLLocationCoordinate2D {
            let sign: Double = positive ? 1 : -1
            let dx = sign * self.radius  / 6378000 * (180 / .pi)
            let lat = position.latitude + dx
            let lon = position.longitude + dx / cos(position.latitude * .pi / 180)
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        
        return GMSCoordinateBounds(coordinate: locationMinMax(true),
                                   coordinate: locationMinMax(false))
    }
}
