//
//  Utils.swift
//  Orbis-iOS
//
//  Created by Kamran on 03/11/2024.
//


import Foundation
import UIKit
import AVFoundation
import CommonCrypto
import SystemConfiguration
import SDWebImage
import Photos

class Utils {

    static func formatTime(_ millis: Int64) -> String {
        let hours = (millis / 3_600_000) % 24
        let minutes = (millis / 60_000) % 60
        let seconds = (millis / 1_000) % 60

        if hours == 0 && minutes <= 1 {
            return "Online"
        } else if hours == 0 && minutes > 1 {
            return "Online \(minutes) minutes ago"
        } else {
            return "Online \(hours) minutes ago"
        }
    }

    static func getPath(from context: UIViewController, uri: URL) -> String? {
        // iOS equivalent for obtaining file path from URI
        if uri.isFileURL {
            return uri.path
        } else if uri.scheme == "content" {
            let asset = PHAsset.fetchAssets(withALAssetURLs: [uri], options: nil).firstObject
            var localId: String?
            if let asset = asset {
                localId = asset.localIdentifier
            }
            return localId
        }
        return nil
    }

    static func getImageUrl200(imageName: String) -> String {
        var image_200x200 = imageName
        if imageName.hasSuffix(".jpeg") {
            image_200x200 = imageName.replacingOccurrences(of: ".jpeg", with: "_200x200.jpeg")
        } else if imageName.hasSuffix(".png") {
            image_200x200 = imageName.replacingOccurrences(of: ".png", with: "_200x200.png")
        } else if imageName.hasSuffix(".jpg") {
            image_200x200 = imageName.replacingOccurrences(of: ".jpg", with: "_200x200.jpg")
        } else {
            image_200x200 += "_200x200.jpeg"
        }
        return image_200x200
    }

    static func getImageUrl400(imageName: String) -> String {
        var image_400x400 = imageName
        if imageName.hasSuffix(".jpeg") {
            image_400x400 = imageName.replacingOccurrences(of: ".jpeg", with: "_400x400.jpeg")
        } else if imageName.hasSuffix(".png") {
            image_400x400 = imageName.replacingOccurrences(of: ".png", with: "_400x400.png")
        } else if imageName.hasSuffix(".jpg") {
            image_400x400 = imageName.replacingOccurrences(of: ".jpg", with: "_400x400.jpg")
        } else {
            image_400x400 += "_400x400.jpeg"
        }
        return image_400x400
    }

    static func getImageUrl680(imageName: String) -> String {
        var image_680x680 = imageName
        if imageName.hasSuffix(".jpeg") {
            image_680x680 = imageName.replacingOccurrences(of: ".jpeg", with: "_680x680.jpeg")
        } else if imageName.hasSuffix(".png") {
            image_680x680 = imageName.replacingOccurrences(of: ".png", with: "_680x680.png")
        } else if imageName.hasSuffix(".jpg") {
            image_680x680 = imageName.replacingOccurrences(of: ".jpg", with: "_680x680.jpg")
        } else {
            image_680x680 += "_680x680.jpeg"
        }
        return image_680x680
    }

    static func getMd5String(stringToConvert: String) -> String {
        guard let messageData = stringToConvert.data(using: .utf8) else { return "" }
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))

        _ = digestData.withUnsafeMutableBytes { digestBytes in
            messageData.withUnsafeBytes { messageBytes in
                CC_MD5(messageBytes.baseAddress, CC_LONG(messageData.count), digestBytes.bindMemory(to: UInt8.self).baseAddress)
            }
        }
        return digestData.map { String(format: "%02hhx", $0) }.joined()
    }

    static func convertDpToPixel(dp: CGFloat, context: UIViewController) -> CGFloat {
        let scale = UIScreen.main.scale
        return dp * scale
    }

    static func isValidEmailId(_ email: String) -> Bool {
        let emailRegEx = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    static func generateRandomPassword() -> String {
        let letters = "abcdefghjklmnopqrstuvwxyzABCDEFGHJKMNOPQRSTUVWXYZ1234567890"
        let numbers = "1234567890"
        let specialChars = "!@#$%^&*_=+-/"
        var pw = ""
        for _ in 0..<8 {
            if let letter = letters.randomElement() {
                pw.append(letter)
            }
        }
        if let number = numbers.randomElement() {
            pw.append(number)
        }
        if let specialChar = specialChars.randomElement() {
            pw.append(specialChar)
        }
        return pw
    }
}
