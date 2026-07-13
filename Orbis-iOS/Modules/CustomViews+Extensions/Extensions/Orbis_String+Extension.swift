//
//  String+Extension.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 11/04/2021.
//

import Foundation
import UIKit
import Alamofire
import FirebaseAuth
import FirebaseStorage

enum OrbisImageSizeResolution: String {
    case twoHundred
    case fourHundred
    case sixEighty
    
    func getImageSizePostfix() -> String {
        switch self {
        case .twoHundred:
            return AppValues.imageSize200
        case .fourHundred:
            return AppValues.imageSize400
        case .sixEighty:
            return AppValues.imageSize680
        }
    }
}

extension String {
    
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }
    
    var isValidPassword: Bool {
        return self.count >= 8
    }
    
    var isValidField: Bool {
        return !isEmpty
    }
    
    var toProperURLString: String {
        if self.hasPrefix("http://") || self.hasPrefix("https://") {
            return self
        } else {
            return "http://" + self
        }
    }
    
    var isValidLink: Bool {
        let types: NSTextCheckingResult.CheckingType = [.link]
        let detector = try? NSDataDetector(types: types.rawValue)
        guard (detector != nil && self.count > 0) else { return false }
        if detector!.numberOfMatches(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.count)) > 0 {
            return true
        }
        return false
    }
    
    var isNotUrlLink: Bool {
        if let url = NSURL(string: self) {
            return !UIApplication.shared.canOpenURL(url as URL)
        }
        return true
    }
    
    func findTextWidth(font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let myText = self
        let size = (myText as NSString).size(withAttributes: fontAttributes)
        return size.width
    }
    
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func getFirebaseReference(storage: ProjectStorageDirectories, imageSizeResolution: OrbisImageSizeResolution) -> StorageReference {
        let name = self.contains(".") ? self : self.appending(".jpg")
        let splittedName = name.split(separator: ".")
        var optimizedName = name
        if splittedName.count == 2 {
            let imageOriginalName = String(splittedName.first!)
            let imageExtension = String(name.split(separator: ".").last ?? "")
            optimizedName = imageOriginalName + imageSizeResolution.getImageSizePostfix() + "." + imageExtension
        }
        let storageRef = Storage.storage().reference().child(storage.rawValue).child(optimizedName)
        return storageRef
    }
    
    func getFirebaseFileStorageReference(storage: ProjectStorageDirectories) -> StorageReference {
        let storageRef = Storage.storage().reference().child(storage.rawValue).child(self)
        return storageRef
    }
    
    func getFirebaseReference(removingSizeModifier sizeModifier: OrbisImageSizeResolution, from ref: StorageReference) -> StorageReference {
        guard ref.name.contains(sizeModifier.rawValue) else { return ref }
        let nameRemovingModifier = ref.name.replacingOccurrences(of: sizeModifier.rawValue, with: "")
        return ref.parent()!.child(nameRemovingModifier)
    }
    
    var toFirebaseAuthProviderName: String {
        switch self {
        case FacebookAuthProviderID:
            return "Facebook"
        case GoogleAuthProviderID:
            return "Google"
        case TwitterAuthProviderID:
            return "Twitter"
        case EmailAuthProviderID:
            return "Email"
        case "apple.com":
            return "Apple"
        default:
            return self
        }
    }
    
    var fetchContainingUrls: [String] {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
        guard matches.count > 0 else { return [] }
        return matches.map { result -> String in
            let range = Range(result.range, in: self)
            let url = self[range!]
            return String(url)
        }
    }
    
    var mapUrlPostfix: String {
        return self + "mapUrl"
    }
    
    var withPostSharePrefix: String {
        return "Checkout this post from Orbis:\n" + self
    }
    
    var localized: String {
//        return NSLocalizedString(self, comment: "")
        let defaultLanguage = Locale.current.languageCode ?? Locale.preferredLanguages.first!.components(separatedBy: "-").first!
        let userLanguage = UserSessionManager.shared.currentUser?.language
        
        print(localized(forLanguage: userLanguage ?? defaultLanguage))
        
        return localized(forLanguage: userLanguage ?? defaultLanguage)
    }
    
    /*
    private func localized(forLanguage language: String = Locale.current.languageCode ?? Locale.preferredLanguages.first!.components(separatedBy: "-").first!) -> String {
        
        guard let path = Bundle.main.path(forResource: language == "en" ? "Base" : language, ofType: "lproj") else {
            
            let basePath = Bundle.main.path(forResource: "Base", ofType: "lproj")!
            
            print( "basePath localized Path --- \(basePath)")
            
            return Bundle(path: basePath)!.localizedString(forKey: self, value: "", table: nil)
        }
        
        return Bundle(path: path)!.localizedString(forKey: self, value: "", table: nil)
    }
    */
    
    /*
    private func localized(forLanguage language: String = Locale.current.languageCode ?? Locale.preferredLanguages.first!.components(separatedBy: "-").first!) -> String {
        // Determine the language path
        let resource = language == "en" ? "Base" : language

        // Try to find the path for the given language
        guard let path = Bundle.main.path(forResource: resource, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Fallback to Base.lproj if the language folder doesn't exist
            let basePath = Bundle.main.path(forResource: "Base", ofType: "lproj")!
            return Bundle(path: basePath)!.localizedString(forKey: self, value: "", table: nil)
        }

        // Return the localized string from the appropriate bundle
        return bundle.localizedString(forKey: self, value: "", table: nil)
    }
     */
    
    
    private func localized(forLanguage language: String = Locale.current.languageCode ?? Locale.preferredLanguages.first!.components(separatedBy: "-").first!) -> String {
        // Determine the correct resource folder
        let resource: String
        if language == "en" {
            // Use "Base" for English if no "en.lproj" exists
            resource = Bundle.main.path(forResource: "en", ofType: "lproj") != nil ? "en" : "Base"
        } else {
            resource = language
        }
        
        // Try to find the path for the resource
        guard let path = Bundle.main.path(forResource: resource, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Fallback to Base.lproj if the folder for the language doesn't exist
            let basePath = Bundle.main.path(forResource: "Base", ofType: "lproj")!
            return Bundle(path: basePath)!.localizedString(forKey: self, value: "", table: nil)
        }
        
        // Return the localized string from the correct bundle
        return bundle.localizedString(forKey: self, value: "", table: nil)
    }

}

extension String: ParameterEncoding {

    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.httpBody = data(using: .utf8, allowLossyConversion: false)
        return request
    }

}

extension String {
    var toCurrencySymbol: String {
        let code = self.uppercased()
        let locale = NSLocale(localeIdentifier: code)
        if locale.displayName(forKey: .currencySymbol, value: code) == code {
            let newlocale = NSLocale(localeIdentifier: code.dropLast() + "_en")
            return newlocale.displayName(forKey: .currencySymbol, value: code) ?? self
        }
        return locale.displayName(forKey: .currencySymbol, value: code) ?? self
    }
}
extension String {
    
    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }
}
