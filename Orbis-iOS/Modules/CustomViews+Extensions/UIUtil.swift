//
//  UIUtil.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/03/2021.
//

import Foundation
import Toast_Swift
import Lottie

struct AppElementTags {
    static let appLoaderTag = 1001
}

class UIUtil {
    
    static func getCurrentLanguageCode() -> String {
        return Locale.current.languageCode ?? "en"
    }
    
    static func showGlobalToast(message: String) {
        DispatchQueue.main.async {
            for window in UIApplication.shared.windows {
                window.hideAllToasts()
                window.makeToast(message)
            }
        }
    }
    
    static func getAppLoader(height: CGFloat, width: CGFloat) -> LottieAnimationView {
        let loader = LottieAnimationView(name: "app-loader")
        loader.frame.size = CGSize(width: width, height: height)
        loader.backgroundBehavior = .pauseAndRestore
        loader.loopMode = .loop
        loader.backgroundColor = .clear
        loader.contentMode = .scaleAspectFit
        return loader
    }
    
    static func getAppPendingPostLoader(height: CGFloat, width: CGFloat) -> LottieAnimationView {
        let loader = LottieAnimationView(name: "post-pending-loader")
        loader.frame.size = CGSize(width: width, height: height)
        loader.backgroundBehavior = .pauseAndRestore
        loader.loopMode = .loop
        loader.backgroundColor = .clear
        loader.contentMode = .scaleAspectFit
        return loader
    }
    
    static func getWhiteAppLoader(height: CGFloat, width: CGFloat) -> LottieAnimationView {
        let loader = LottieAnimationView(name: "app-loader-white")
        loader.frame.size = CGSize(width: width, height: height)
        loader.backgroundBehavior = .pauseAndRestore
        loader.loopMode = .loop
        loader.backgroundColor = .clear
        loader.contentMode = .scaleAspectFit
        return loader
    }
}
