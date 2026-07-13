//
//  ForceUpdateManager.swift
//  Orbis-iOS
//
//  Created by Zohaib on 23/03/2025.
//

import Foundation

//import FirebaseRemoteConfig
//
//class ForceUpdateManager {
//    static let shared = ForceUpdateManager()
//    private var alertController: UIAlertController?
//
//    func verifyVersion() {
//        let remoteConfig = RemoteConfig.remoteConfig()
//        let expirationDuration = 0
//        
//        remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) { status, error in
//            if status == .success {
//                remoteConfig.activate { _, _ in
//                    print("RemoteConfig activated successfully")
//                    self.checkForUpdate()
//                }
//            } else {
//                print("Error fetching remote config: \(error?.localizedDescription ?? "Unknown error")")
//                self.checkForUpdate() // Fallback to defaults
//            }
//        }
//    }
//
//    private func checkForUpdate() {
//        if ForceUpdateChecker().check() == .shouldUpdate {
//            DispatchQueue.main.async {
//                if self.alertController == nil {
//                    self.alertController = UIAlertController(
//                        title: "New Version Available",
//                        message: "There is a new version available to download, please update your app.",
//                        preferredStyle: .alert
//                    )
//                    
//                    let action = UIAlertAction(title: "Update", style: .default, handler: self.goToAppStore)
//                    self.alertController?.addAction(action)
//                }
//                
//                if let topVC = self.getTopViewController() {
//                    if topVC.presentedViewController == nil {
//                        topVC.present(self.alertController!, animated: true)
//                    }
//                }
//            }
//        }
//    }
//
//    private func getTopViewController() -> UIViewController? {
//        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
//            return nil
//        }
//        
//        var topVC = window.rootViewController
//        while let presentedVC = topVC?.presentedViewController {
//            topVC = presentedVC
//        }
//        return topVC
//    }
//
//    private func goToAppStore(action: UIAlertAction) {
//        let appId = "1453025529"
//        if let url = URL(string: "https://apps.apple.com/us/app/id\(appId)"),
//           UIApplication.shared.canOpenURL(url) {
//            UIApplication.shared.open(url, options: [:], completionHandler: nil)
//        }
//    }
//}



import FirebaseRemoteConfig

class ForceUpdateManager {
    static let shared = ForceUpdateManager()
    private var alertController: UIAlertController?
    private let appId = "1453025529"

    func verifyVersion() {
        checkForUpdate()
    }

    private func checkForUpdate() {
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(appId)&country=us") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch App Store version: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let appStoreVersion = results.first?["version"] as? String,
                   let installedVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    
                    print("App Store Version: \(appStoreVersion), Installed Version: \(installedVersion)")

                    if self.isUpdateAvailable(installedVersion, appStoreVersion) {
                        DispatchQueue.main.async {
                            self.showUpdateAlert()
                        }
                    }
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }.resume()
    }

    private func isUpdateAvailable(_ installedVersion: String, _ appStoreVersion: String) -> Bool {
        return installedVersion.compare(appStoreVersion, options: .numeric) == .orderedAscending
    }

    private func showUpdateAlert() {
        if self.alertController == nil {
            self.alertController = UIAlertController(
                title: "New Version Available",
                message: "There is a new version available to download, please update your app.",
                preferredStyle: .alert
            )
            
            let action = UIAlertAction(title: "Update", style: .default, handler: self.goToAppStore)
            self.alertController?.addAction(action)
        }
        
        if let topVC = self.getTopViewController() {
            if topVC.presentedViewController == nil {
                topVC.present(self.alertController!, animated: true)
            }
        }
    }

    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        
        var topVC = window.rootViewController
        while let presentedVC = topVC?.presentedViewController {
            topVC = presentedVC
        }
        return topVC
    }

    private func goToAppStore(action: UIAlertAction) {
        if let url = URL(string: "https://apps.apple.com/us/app/id\(appId)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
