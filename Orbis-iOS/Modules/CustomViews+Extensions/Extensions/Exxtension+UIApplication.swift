//
//  Exxtension+UIApplication.swift
//  Orbis-iOS
//
//  Created by Zohaib on 23/03/2025.
//

import UIKit

extension UIApplication {
    func openAppStore(for appID: String) {
        let appStoreURL = "https://itunes.apple.com/app/\(appID)"
        guard let url = URL(string: appStoreURL) else {
            return
        }

        DispatchQueue.main.async {
            if self.canOpenURL(url) {
                self.open(url)
            }
        }
    }
}
