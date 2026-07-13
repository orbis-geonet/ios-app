//
//  AppConstants.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 30/03/2021.
//

import Foundation
import UIKit

struct AppNotificationKeys {
    static let privateNewsNotificationSeen = "kPrivateNewsNotificationSeen"
    static let privatePendingNotificationSeen = "kPrivatePendingNotificationSeen"
    static let googleSignInResult = "kGoogleSignInCompleted"
    static let userDidLogin = "userDidLogin"
    static let userDidUpdate = "userDidUpdateValues"
    static let userLanguageDidUpdate = "kUserLanguageDidUpdate"
    struct PostCreate {
        static let pendingPostCreateSuccess = "kPendingPostCreateSuccess"
        static let pendingPostCreateFailure = "kPendingPostCreateFailure"
        static let postCreateCompleted = "kPostCreateCompletedNotification"
    }
    struct UserProfilePhotoUpload {
        static let pendingProfileMediaUploadSuccess = "kPendingProfileMediaUploadSuccess"
        static let pendingProfileMediaUploadFailure = "kPendingProfileMediaUploadFailure"
    }
    struct Message {
        static let pendingMessageMediaUploadFailure = "kPendingMessageMediaUploadFailure"
        static let pendingMessageMediaUploadSuccess = "kPendingMessageMediaUploadSuccess"
    }
    struct Comment {
        static let pendingCommentPostFailure = "kPendingCommentPostFailure"
        static let pendingCommentPostSuccess = "kPendingCommentPostSuccess"
        static let commentCountUpdated = "kCommentCountUpdated"
        static let commentAddedToPost = "kCommentAddedToPost"
        static let commentDeletedFromPost = "kCommentDeletedFromPost"
    }
    struct Post {
        static let postUpdated = "kPostUpdated"
    }
    static let userDidConnectInstagram = "userDidConnectInstagram"
}

enum StripeAccountStatusValue: String {
    case created = "CREATED"
    case validationFailed = "VALIDATION_FAILED"
    case readyToUse = "READY_TO_USE"
    case unknown
}

enum AppUserDefaultKeys: String {
    case sessionUser = "loggedInUser"
    case fcmToken = "loggedInUserFCMToken"
    case onboardingShown = "kOnboardingSceneShown"
    case loginBoardingShown = "kLoginOnboardingSceneShown"
    case groupMainAdminSubscriptionPopupShown = "kGroupMainAdminSubscriptionPopupShown"
    case normalUserSubscriptionPopupShown = "kNormalUserSubscriptionPopupShown"
    case branchLinkPartnerKey = "kBranchLinkPartnerKey"
}

enum ProjectStorageDirectories: String {
    case profilePictures
    case groupPictures
    case placePictures
    case eventImages = "events/images"
    case postImages = "posts/images"
    case postAudio = "posts/audios"
    case postVideo = "posts/videos"
    case userProfilePhotos = "user/pictures"
    case userProfileVideos = "user/videos"
    case conversationImages = "chat/images"
    case conversationVideos = "chat/videos"
    case subscriptionImages = "groups/subscription/images"
    case none
}

enum OrbisPlaceType: String {
    case shopping = "SHOPPING"
    case park = "PARK"
    case restaurant = "RESTAURANT"
    case school = "SCHOOL"
    case location = "LOCATION"
    case twoBuildings = "TWO_BUILDINGS"
    case sportsCenter = "SPORTS_CENTER"
    case castle = "CASTLE"
    case house2 = "HOUSE_2"
    case music = "MUSIC"
    case fastFood = "FAST_FOOD"
    case house = "HOUSE"
    case building = "BUILDING"
    case beach = "BEACH"
    case bar = "BAR"
    
    func correspondingImage() -> UIImage? {
        switch self {
        case .beach:
            return UIImage(named: "beach-ic")
        case .building:
            return UIImage(named: "tall-building-ic")
        case .castle:
            return UIImage(named: "disney-land-ic")
        case .fastFood:
            return UIImage(named: "cafe-ic")
        case .house:
            return UIImage(named: "housing-single-ic")
        case .house2:
            return UIImage(named: "housing-ic")
        case .location:
            return UIImage(named: "checkmark-place-ic")
        case .music:
            return UIImage(named: "music-center-ic")
        case .park:
            return UIImage(named: "eco-tree-ic")
        case .restaurant:
            return UIImage(named: "grocery-store-ic")
        case .school:
            return UIImage(named: "court-ic")
        case .shopping:
            return UIImage(named: "shopping-store-ic")
        case .sportsCenter:
            return UIImage(named: "gym-center-ic")
        case .twoBuildings:
            return UIImage(named: "tall-building-attached-ic")
        case .bar:
            return UIImage(named: "bar-ic")
        }
    }
    
    func correspondingCircularImage(sizeRatio: CGFloat = 1, frameSize: CGFloat = 100.toCGFloat.relativeToIphone8Width()) -> UIImage {
        switch self {
        case .location:
            let markerView = PlaceMarkerView(image: self.correspondingImage()!, bgColor: .clear, size: CGSize(width: frameSize, height: frameSize), widthMultiplier: 0.4 * sizeRatio, isWidthFixed: true)
            return UIImage(view: markerView)
        default:
            let markerView = PlaceMarkerView(image: self.correspondingImage()!, bgColor: .clear, size: CGSize(width: frameSize, height: frameSize), widthMultiplier: 0.6 * sizeRatio, isWidthFixed: true)
            return UIImage(view: markerView)
        }
    }
}

struct AppValues {
    struct DateTime {
        static let millisecondsInDay: Double = 24 * 60 * 60 * 1000
        static let millisecondsinYear: Double = 24 * 60 * 60 * 1000 * 365
        static let twentyFourHoursInSeconds: Double = 86400
    }
    static let tenMBinBytes = 10 * 1024 * 1024
    static let thousandHundrenMbInBytes = 1000 * 1024 * 1024
    static let maxMapImageWidthHeight: CGFloat = isCurrentDeviceOld ? 200 : 400
    static let maxAudioRecordTime: Double = 15 * 60
    static let iosSource = "orbis_ios"
    static let imageSize200 = "_200x200"
    static let imageSize400 = "_400x400"
    static let imageSize680 = "_680x680"
    static let postTextMaxLines = 5
    
    private static let currentDevice = UIDevice().type
    private static let olderDevices: [UIDevice.Model] = [.iPhone6S, .iPhone6SPlus, .iPhone7, .iPhone7Plus]
    
    static let isCurrentDeviceOld = AppValues.olderDevices.contains(where: { currentDevice == $0 })
    static let isCurrentDeviceIpad = UIDevice.current.type.rawValue.lowercased().contains("ipad")

    /// Perf S1: run the map polygon geometry off the main thread. DEFAULT ON (circle create path
    /// completed — sweep now re-creates circles after pan-away, matching S0).
    /// UserDefaults absorbs launch args, so `-perf.offMainGeometry NO` in a scheme forces the
    /// synchronous-on-main S0 path without a rebuild.
    static var offMainGeometryEnabled: Bool {
        if UserDefaults.standard.object(forKey: "perf.offMainGeometry") == nil { return true }
        return UserDefaults.standard.bool(forKey: "perf.offMainGeometry")
    }
    
    struct Subscription {
        static let installmentMinPeriod = 2
        static let installmentMaxPeriod = 100
        
        static let minQuantity = 1
        static let maxQuantity = 100
        
        static let maxImageSize = 4 * 1024 * 1024
    }
    
    static var markersVisibilityFactor: CGFloat {
        if AppValues.isCurrentDeviceIpad {
            return 80
        }
        if AppValues.isCurrentDeviceOld {
            return 60
        } else {
            return 80 // 120
        }
    }
    
    static var mapFetchDistanceInKM: Double {
        if AppValues.isCurrentDeviceOld {
            return 10
        } else {
            return 50
        }
    }
    
    static var mapMinVisibleDistanceInKM: Double {
        if AppValues.isCurrentDeviceOld {
            return 5
        } else {
            return 10
        }
    }
    
    static var removeRadiusInMeters: Double {
        if AppValues.isCurrentDeviceOld {
            return 3_000
        } else {
            return 10_000
        }
    }
    
    struct StripeAccountCreationDefaults {
        static let defaultCountry = "BR"
        static let defaultCurrency = "BRL"
        static let defaultBusinessType = "INDIVIDUAL"
    }
}
