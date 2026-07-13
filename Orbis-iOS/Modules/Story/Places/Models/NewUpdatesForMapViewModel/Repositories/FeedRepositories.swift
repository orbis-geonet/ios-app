//
//  FeedRepositories.swift
//  Orbis-iOS
//
//  Created by Kamran on 04/12/2024.
//


import Foundation
import Combine

class FeedRepositories {
    private let apiInterface = ApiServiceImplementation()
    private let prefManager = PrefManager()
    private let feedDao = FeedDao()
    

    private func getBearerToken() -> String {
        guard let token = prefManager.getIdToken(), !token.isEmpty else { return "" }
        return "Bearer \(token)"
    }
    
    func getCachedNearByFeed(city: String) -> [FeedEntity] {
        let results = feedDao.getAllCachedFeedsFromNearByOnCity(city: city)
        return Array(results)
    }
    
    func getCachedMyFeed(city: String) -> [FeedEntity] {
        let results = feedDao.getAllCachedFeedsFromUser(city: city)
        return Array(results)
    }
    
    func cacheFeed(feedList: FeedEntity) {
        feedDao.insertFeed(feed: feedList)
    }
    
    func modifyCachedFeed(feedList: FeedEntity) {
        feedDao.updateFeed(feed: feedList)
    }
    
    func isPageContained(page: String) -> Bool {
        return feedDao.isPageContained(page: page)
    }
    
    func deleteNearByCachedFeed(city: String) {
        feedDao.deleteAllNearByFeeds(city: city)
    }
    
    func deleteMyCachedFeed(city: String) {
        feedDao.deleteAllMyFeeds(city: city)
    }
    

}
