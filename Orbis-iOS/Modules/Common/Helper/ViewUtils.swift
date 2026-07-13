//
//  ViewUtils.swift
//  Orbis-iOS
//
//  Created by Kamran on 03/11/2024.
//


import UIKit
import FirebaseStorage
import CoreGraphics
import GoogleMaps

class ViewUtils {
    static let twoSpaces = "  "

    static func setAppLocale(context: UIViewController, language: String) {
        let locale = Locale(identifier: language)
       // Locale.setDefault(locale)
        //var config = context.view.window?.windowScene?.interfaceOrientation.configuration
        //config?.locale = locale
    }

    static func loadGroupPhoto(context: UIViewController, imageView: UIImageView, imageName: String? = nil) {
        if imageName == nil || imageName!.isEmpty {
            imageView.image = UIImage(named: "ic_user")
        } else {
            let storageRef = Storage.storage().reference().child(Constants.GROUP_PHOTO_STORAGE + Utils.getImageUrl200(imageName: imageName!))
            storageRef.downloadURL { (url, error) in
                if let error = error {
                    print("Failed to get download URL: \(error.localizedDescription)")
                    imageView.image = UIImage(named: "ic_user")
                } else if let url = url {
                    imageView.loadImage(from: url, placeholder: UIImage(named: "ic_user"))
                }
            }
        }
    }

    static func loadUserProfilePic(context: UIViewController, imageView: UIImageView, imageName: String?, providerImage: String?) {
            if let imageName = imageName, !imageName.isEmpty {
                let storageRef = Storage.storage().reference().child(Constants.PROFILE_PICTURES + Utils.getImageUrl200(imageName: imageName))
                storageRef.downloadURL { (url, error) in
                    if let error = error {
                        print("Failed to get download URL: \(error.localizedDescription)")
                        imageView.image = UIImage(named: "ic_user")
                    } else if let url = url {
                        imageView.loadImage(from: url, placeholder: UIImage(named: "ic_user"))
                    }
                }
            } else if let providerImage = providerImage, !providerImage.isEmpty {
                let uri = URL(string: providerImage)
                var load: String = providerImage
                if providerImage.contains("fbsbx"), let asid = uri?.queryParameters!["asid"] {
                    load = "https://graph.facebook.com/\(asid)/picture?width=600&height=600"
                }
                imageView.loadImage(from: URL(string: load), placeholder: UIImage(named: "ic_user"))
            } else {
                imageView.image = UIImage(named: "ic_user")
            }
        }

    static func checkSeeMore(textView: UITextView, text: String, maxLines: Int) {
//        textView.text = text
//        DispatchQueue.main.async {
//            if textView.numberOfLines > maxLines {
//                let lastCharIndex = textView.layoutManager.characterRange(forGlyphRange: textView.layoutManager.glyphRange(forBoundingRect: textView.bounds, in: textView.textContainer), actualGlyphRange: nil).upperBound - 1
//                textView.text = String(text.prefix(lastCharIndex - 5)) + "... view more"
//                let attributedString = NSMutableAttributedString(string: textView.text)
//                if let range = textView.text.range(of: "view more") {
//                    attributedString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: NSRange(range, in: textView.text))
//                }
//                textView.attributedText = attributedString
//            }
//        }
    }

    static func getPlaceIcon(type: String) -> UIImage? {
        switch type {
        case "LOCATION": return UIImage(named: "ic_group_1")
        case "BUILDING": return UIImage(named: "ic_group_2")
        case "BAR": return UIImage(named: "ic_group_3")
        case "HOUSE_2": return UIImage(named: "ic_group_4")
        case "CASTLE": return UIImage(named: "ic_group_5")
        case "SPORTS_CENTER": return UIImage(named: "ic_group_6")
        case "FAST_FOOD": return UIImage(named: "ic_group_7")
        case "SHOPPING": return UIImage(named: "ic_group_8")
        case "RESTAURANT": return UIImage(named: "ic_group_9")
        case "MUSIC": return UIImage(named: "ic_group_10")
        case "BEACH": return UIImage(named: "ic_group_11")
        case "SCHOOL": return UIImage(named: "ic_group_12")
        case "TWO_BUILDINGS": return UIImage(named: "ic_group_13")
        case "PARK": return UIImage(named: "ic_group_14")
        case "HOUSE": return UIImage(named: "ic_group_15")
        default: return UIImage(named: "ic_group_1")
        }
    }

    static func convertDpToPixel(dp: CGFloat, context: UIViewController) -> Int {
        let scale = context.view.window?.screen.scale ?? UIScreen.main.scale
        return Int(dp * scale)
    }

    static func convertTimeStampToFormatted(timestamp: String) -> String {
        if #available(iOS 11.0, *) {
            if let inst = ISO8601DateFormatter().date(from: timestamp) {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd/MM/yy 'at' HH:mm"
                return formatter.string(from: inst)
            }
        } else {
            let inputFormat = DateFormatter()
            inputFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            inputFormat.timeZone = TimeZone(abbreviation: "UTC")
            if let date = inputFormat.date(from: timestamp) {
                let outputFormat = DateFormatter()
                outputFormat.dateFormat = "dd/MM/yy 'at' HH:mm"
                return outputFormat.string(from: date)
            }
        }
        return timestamp
    }

    static func convertTimeStampToDate(dateStr: String?) -> Date? {
        guard let dateStr = dateStr else { return nil }
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SS'Z'",
            "yyyy-MM-dd'T'HH:mm.SS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss'Z'"
        ]
        let dateFormat = DateFormatter()
        // Set the time zone to the current device timezone
        dateFormat.timeZone = TimeZone.current

        // Set locale to "en_US_POSIX" for consistent parsing
        dateFormat.locale = Locale(identifier: "en_US_POSIX")
        for format in formats {
            dateFormat.dateFormat = format
            if let date = dateFormat.date(from: dateStr) {
                return date
            }
        }
        return nil
    }

    static func applyShadow(view: UIView, backgroundColorValue: UIColor, cornerRadiusValue: CGFloat, shadowColorValue: UIColor, elevationValue: CGFloat, shadowGravity: Int, dx: CGFloat = 0, dy: CGFloat = 0) {
        view.layer.cornerRadius = cornerRadiusValue
        view.layer.shadowColor = shadowColorValue.cgColor
        view.layer.shadowOffset = CGSize(width: dx, height: dy)
        view.layer.shadowRadius = elevationValue / 2
        view.layer.shadowOpacity = 1.0
        view.layer.backgroundColor = backgroundColorValue.cgColor
    }

    static func changeViewColor(view: UIView, color: UIColor) {
        if let colorDrawable = view.backgroundColor {
            view.backgroundColor = color
        }
    }

    static func changeStrokeColor(view: UIView, color: UIColor) {
        if let gradientDrawable = view.layer as? CAShapeLayer {
            gradientDrawable.strokeColor = color.cgColor
        }
    }

    static func colorDrawable(view: UIView, color: UIColor) {
        view.backgroundColor = color
    }

    static func colorTintImageView(view: UIImageView, color: UIColor) {
        view.tintColor = color
    }

    static func setBackgroundDrawable(view: UIView, drawable: UIImage?) {
        view.backgroundColor = UIColor(patternImage: drawable ?? UIImage())
    }

    static func togglePasswordEye(editText: UITextField, imageView: UIImageView, context: UIViewController) {
        if editText.isSecureTextEntry {
            imageView.tintColor = UIColor.gray
            editText.isSecureTextEntry = false
        } else {
            imageView.tintColor = UIColor.black
            editText.isSecureTextEntry = true
        }
        if let text = editText.text {
            editText.selectedTextRange = editText.textRange(from: editText.endOfDocument, to: editText.endOfDocument)
        }
    }

    static func showDialogue(context: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        context.present(alert, animated: true, completion: nil)
    }
}

extension UIImageView {
    func loadImage(from url: URL?, placeholder: UIImage?) {
        self.image = placeholder
        guard let url = url else { return }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Failed to load image: \(error.localizedDescription)")
                return
            }

            guard let data = data, let image = UIImage(data: data) else {
                print("Failed to convert data to image.")
                return
            }

            DispatchQueue.main.async {
                self.image = image
            }
        }
        task.resume()
    }
}


