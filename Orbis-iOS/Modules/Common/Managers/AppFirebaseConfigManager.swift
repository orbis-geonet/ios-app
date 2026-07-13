//
//  AppFirebaseConfigManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 08/09/2021.
//

import Foundation
import FirebaseFirestore
import CodableFirebase
import Firebase

class AppFirebaseConfig: Codable {
    var configId: String?
    var isAdsEnabled: Bool?
    var feedAdsFrequency: Int?
    var storyAdsFrequency: Int?
    var interstitialAdTimeout: Int?
    var mapInitialZoom: Float?
}

class AppFirebaseAppLinks: Codable {
    var id: String?
    var orbisContactEmail: String?
    var orbisPrivacyLink: String?
    var orbisTOSLink: String?
    var orbisWebsiteLink: String?
}

class AppFirebaseConfigManager {
    static let shared = AppFirebaseConfigManager()
    private let configRef: CollectionReference = Firestore.firestore().collection(FirebaseFirestoreNode.appConfig.rawValue)
    private let linksRef: CollectionReference = Firestore.firestore().collection(FirebaseFirestoreNode.appLinks.rawValue)
    private var config: AppFirebaseConfig?
    private var appLinks: AppFirebaseAppLinks?
    var hasConfigLoaded = false
    
    var isAdsEnabled: Bool {
        return config?.isAdsEnabled ?? false
    }
    
    var feedAdsFrequency: Int {
        return config?.feedAdsFrequency ?? 10
    }
    
    var storyAdsFrequency: Int {
        return config?.storyAdsFrequency ?? 10
    }
    
    var interstitialAdTimeout: Int {
        return config?.interstitialAdTimeout ?? 5
    }
    
    var mapInitialZoom: Float {
        return config?.mapInitialZoom ?? 12.5
    }
    
    var orbisEmail: String {
        return appLinks?.orbisContactEmail ?? Applinks.orbisEmail
    }
    
    var orbisWebsiteLink: String {
        return appLinks?.orbisWebsiteLink ?? Applinks.orbisWebsiteLink
    }
    
    var orbisTOSlink: String {
        return appLinks?.orbisTOSLink ?? Applinks.orbisTOSlink
    }
    
    var orbisPrivacyLink: String {
        return appLinks?.orbisPrivacyLink ?? Applinks.orbisPrivacyLink
    }
    
    func fetchAppConfig(completion: @escaping responseBlock) {
        let query = configRef
        query.getDocuments { snapshot, err in
            if let error = err {
                debugPrint("Error in fetching app config \(error.localizedDescription)")
            }
            else {
                if let snapshot = snapshot, let document = snapshot.documents.first {
                    let data = document.data()
                    do {
                        let config = try FirestoreDecoder().decode(AppFirebaseConfig.self, from: data)
                        config.configId = document.documentID
                        self.config = config
                    }
                    catch {
                        print("error in fetching app config: \(error)")
                    }
                }
                else {
                    debugPrint("Empty config data")
                }
            }
            self.linksRef.getDocuments { linkSnap, linkErr in
                if let error = linkErr {
                    debugPrint("Error in fetching app links \(error.localizedDescription)")
                }
                else {
                    if let snapshot = linkSnap, let document = snapshot.documents.first {
                        let data = document.data()
                        do {
                            let appLinks = try FirestoreDecoder().decode(AppFirebaseAppLinks.self, from: data)
                            appLinks.id = document.documentID
                            self.appLinks = appLinks
                        }
                        catch {
                            print("error in fetching app links: \(error)")
                        }
                    }
                    else {
                        debugPrint("Empty app links data")
                    }
                }
                self.hasConfigLoaded = true
                completion(true, nil)
            }
        }
    }
}
