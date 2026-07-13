//
//  Constants.swift
//  Orbis-iOS
//
//  Created by Kamran on 02/11/2024.
//


import UIKit
import CoreLocation
import SafariServices

struct Constants {
    static let GROUP_PHOTO_STORAGE = "groupPictures/"
    static let POST_PHOTO_STORAGE = "posts/images/"
    static let SUBSCRIPTION_PHOTO_STORAGE = "groups/subscription/images/"
    static let POST_VIDEO_STORAGE = "posts/videos/"
    static let POST_AUDIO_STORAGE = "posts/audios/"
    static let EVENT_STORAGE = "events/images/"
    static let PLACE_PICTURES = "placePictures/"
    static let PROFILE_PICTURES = "profilePictures/"
    static let USER_PICTURES = "user/pictures/"
    static let CHAT_IMAGE = "chat/images/"
    static let CHAT_VIDEO = "chat/videos/"
    static var IS_CHECKIN = false
    static var location: CLLocation?
    static var currentCountryName: String = "Brazil"
    static var IS_PRIVATE = false
    static var userImage: String = ""
    static var userProfile: UserInfo?
    static var placeTopTitle = "Feed"
    static var appConfig: AppConfig?
    static var storyAdInterval = 0
    static let INTERSTITIAL_AD_ID = ""//"ca-app-pub-6738139926979321/9431305642"
    static let NATIVE_AD_ID = ""//"ca-app-pub-6738139926979321/3111686251"
    static var partnerKey: String?
    static var lastCheckInPolygonCoordinateKey: String?
    static var lastCheckinPlace: PlaceDetails?
    static var isSelfCheckIn = false
    static var groupCity : String? = nil
    static var feedCity : String? = nil
    static var newRankGroupSession:Bool = true
    static var newKMNewsFeedSession: Bool = true
    static var newMyFeedSession: Bool = true


    static func toExternalURL(context: UIViewController, url: String?) {
        guard let url = url, !url.isEmpty else { return }

        var webpageURL = URL(string: url)
        if !url.hasPrefix("http://") && !url.hasPrefix("https://") {
            webpageURL = URL(string: "http://\(url)")
        }

        if let webpageURL = webpageURL {
            let safariVC = SFSafariViewController(url: webpageURL)
            context.present(safariVC, animated: true)
        }
    }

    static func sendPhoneNumberToDialer(phoneNumber: String) {
        if let dialURL = URL(string: "tel://\(phoneNumber)"), UIApplication.shared.canOpenURL(dialURL) {
            UIApplication.shared.open(dialURL, options: [:], completionHandler: nil)
        }
    }

    static func openGoogleMaps(address: String) {
        if let mapURL = URL(string: "comgooglemaps://?q=\(address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"),
           UIApplication.shared.canOpenURL(mapURL) {
            UIApplication.shared.open(mapURL, options: [:], completionHandler: nil)
        } else if let webURL = URL(string: "https://maps.google.com/?q=\(address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        }
    }

    static func copyTextToClipboard(context: UIViewController, textToCopy: String) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = textToCopy
        let alert = UIAlertController(title: nil, message: NSLocalizedString("Text copied to clipboard", comment: ""), preferredStyle: .alert)
        context.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true, completion: nil)
        }
    }
}

class BigDataSharConstants {
    static var storiesArray: [StoryModel] = []
    static var openingHourArray: [WorkingHoursModel] = []
    static var subscriptionKey: String = ""
    static var isOneTimePurchase: Bool = false
}
