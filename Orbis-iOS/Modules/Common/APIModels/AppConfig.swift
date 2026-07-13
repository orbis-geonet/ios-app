//
//  AppConfig.swift
//  Orbis-iOS
//
//  Created by Kamran on 02/11/2024.
//


struct AppConfig: Codable {
    var feedAdsFrequency: Int = 0
    var interstitialAdTimeout: Int = 0
    var isAdsEnabled: Bool = false
    var mapInitialZoom: Double = 0.0
    var storyAdsFrequency: Int = 0
}
