//
//  ImagePicker+Extension.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 30/03/2021.
//

import Foundation
import UIKit
import Photos

extension YPImagePicker {
    
    public static func getAppImageViewConfig(allowMultiSelect: Bool = false, allowsCrop: Bool = true, onStartScreen: YPPickerScreen = .library) -> YPImagePickerConfiguration {
        var config = YPImagePickerConfiguration()
        config.isScrollToChangeModesEnabled = true
        config.onlySquareImagesFromCamera = false
        config.showsPhotoFilters = false
        config.shouldSaveNewPicturesToAlbum = false
        config.startOnScreen = onStartScreen
        config.screens = [.library, .photo]
        config.showsCrop = allowsCrop ? .circle : .none
        config.cropOverlayColor = .white
        config.targetImageSize = .cappedTo(size: 1024)
        config.overlayView = UIView()
        config.hidesStatusBar = true
        config.hidesBottomBar = false
        config.preferredStatusBarStyle = UIStatusBarStyle.default
        config.bottomMenuItemSelectedTextColour = .black
        config.bottomMenuItemUnSelectedTextColour = .darkGray
        
        config.library.mediaType = .photo
        config.library.options = nil
        config.library.onlySquare = false
        config.library.minWidthForItem = nil
        config.library.mediaType = YPlibraryMediaType.photo
        config.library.maxNumberOfItems = allowMultiSelect ? 20 : 1
        config.library.minNumberOfItems = 1
        config.library.numberOfItemsInRow = 4
        config.library.spacingBetweenItems = 1.0
        config.library.skipSelectionsGallery = true
        
        return config
    }
    
    public static func getAppVideoPickerConfig(allowMultiSelect: Bool = false, onStartScreen: YPPickerScreen = .library) -> YPImagePickerConfiguration {
        var config = YPImagePickerConfiguration()
        config.isScrollToChangeModesEnabled = true
        config.onlySquareImagesFromCamera = false
        config.showsPhotoFilters = false
        config.showsVideoTrimmer = false
        config.shouldSaveNewPicturesToAlbum = false
        config.startOnScreen = onStartScreen
        config.screens = [.library, .video]
        config.cropOverlayColor = .white
        config.targetImageSize = .cappedTo(size: 1024)
        config.overlayView = UIView()
        config.hidesStatusBar = true
        config.hidesBottomBar = false
        config.preferredStatusBarStyle = UIStatusBarStyle.default
        config.bottomMenuItemSelectedTextColour = .black
        config.bottomMenuItemUnSelectedTextColour = .darkGray
        config.video.recordingTimeLimit = Double.greatestFiniteMagnitude
        config.video.libraryTimeLimit = Double.greatestFiniteMagnitude
        config.library.mediaType = .video
        config.library.options = nil
        config.library.onlySquare = false
        config.library.minWidthForItem = nil
        config.library.maxNumberOfItems = allowMultiSelect ? 20 : 1
        config.library.minNumberOfItems = 1
        config.library.numberOfItemsInRow = 4
        config.library.spacingBetweenItems = 1.0
        config.library.skipSelectionsGallery = true
        return config
    }
    
    public static func getAppPhotoVideoPickerConfig(allowMultiSelect: Bool = false, onStartScreen: YPPickerScreen = .library) -> YPImagePickerConfiguration {
        var config = YPImagePickerConfiguration()
        config.isScrollToChangeModesEnabled = true
        config.onlySquareImagesFromCamera = false
        config.showsPhotoFilters = false
        config.showsVideoTrimmer = false
        config.showsCrop = .none
        config.shouldSaveNewPicturesToAlbum = false
        config.startOnScreen = onStartScreen
        config.screens = [.library, .video, .photo]
        config.cropOverlayColor = .white
        config.targetImageSize = .cappedTo(size: 1024)
        config.overlayView = UIView()
        config.hidesStatusBar = true
        config.hidesBottomBar = false
        config.preferredStatusBarStyle = UIStatusBarStyle.default
        config.bottomMenuItemSelectedTextColour = .black
        config.bottomMenuItemUnSelectedTextColour = .darkGray
        config.video.recordingTimeLimit = Double.greatestFiniteMagnitude
        config.video.libraryTimeLimit = Double.greatestFiniteMagnitude
        config.library.mediaType = .photoAndVideo
        config.library.options = nil
        config.library.onlySquare = false
        config.library.minWidthForItem = nil
        config.library.maxNumberOfItems = allowMultiSelect ? 20 : 1
        config.library.minNumberOfItems = 1
        config.library.numberOfItemsInRow = 4
        config.library.spacingBetweenItems = 1.0
        config.library.skipSelectionsGallery = true
        return config
    }
    
}

extension PHAsset {
    var originalFilename: String? {
        return PHAssetResource.assetResources(for: self).first?.originalFilename
    }
    
    func getURL(completionHandler : @escaping ((_ responseURL : URL?) -> Void)){
        if self.mediaType == .image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                return true
            }
            self.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) -> Void in
                completionHandler(contentEditingInput!.fullSizeImageURL as URL?)
            })
        } else if self.mediaType == .video {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .original
            PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                if let urlAsset = asset as? AVURLAsset {
                    let localVideoUrl: URL = urlAsset.url as URL
                    completionHandler(localVideoUrl)
                } else {
                    completionHandler(nil)
                }
            })
        }
    }
}
