//
//  FeedDao.swift
//  Orbis-iOS
//
//  Created by Kamran on 02/12/2024.
//


import RealmSwift

class FeedDao {
    
    // Remove the shared `realm` instance; instead, initialize it per method
    private func getRealm() -> Realm {
        return try! Realm() // Ensure each thread gets its own Realm instance
    }

    // Get all cached feeds from nearby based on city
//    func getAllCachedFeedsFromNearByOnCity(city: String) -> [FeedEntity] {
//        let realm = getRealm() // Get a thread-safe Realm instance
//       // return realm.objects(FeedEntity.self).filter("fromNearby == true AND city == %@", city)
//        return Array(realm.objects(FeedEntity.self).filter("fromNearby == true AND city == %@", city))
//    }
    
    func getAllCachedFeedsFromNearByOnCity(city: String) -> [FeedEntity] {
        let realm = getRealm()
        let results = realm.objects(FeedEntity.self).filter("fromNearby == true AND city == %@", city)
        
        // Create detached copies of Realm objects
        return results.map { feedEntity in
            let detachedEntity = FeedEntity()
            detachedEntity.nextPage = feedEntity.nextPage
            detachedEntity.city = feedEntity.city
            detachedEntity.fromNearby = feedEntity.fromNearby
            detachedEntity.content = feedEntity.content
            return detachedEntity
        }
    }

    // Check if a page is contained
    func isPageContained(page: String) -> Bool {
        let realm = getRealm() // Get a thread-safe Realm instance
        return realm.objects(FeedEntity.self).filter("fromNearby == true AND nextPage == %@", page).count > 0
    }

    // Delete all nearby feeds based on city
    func deleteAllNearByFeeds(city: String) {
        let realm = getRealm() // Get a thread-safe Realm instance
        let feedsToDelete = realm.objects(FeedEntity.self).filter("fromNearby == true AND city == %@", city)
        try! realm.write {
            realm.delete(feedsToDelete)
        }
    }

    // Delete all user feeds based on city
    func deleteAllMyFeeds(city: String) {
        let realm = getRealm() // Get a thread-safe Realm instance
        let feedsToDelete = realm.objects(FeedEntity.self).filter("fromNearby == false AND city == %@", city)
        try! realm.write {
            realm.delete(feedsToDelete)
        }
    }

    // Get all cached feeds from the user based on city
    func getAllCachedFeedsFromUser(city: String) -> [FeedEntity] {
        let realm = getRealm() // Get a thread-safe Realm instance
        let results = realm.objects(FeedEntity.self).filter("fromNearby == false AND city == %@", city)
        
        // Create detached copies of Realm objects
        return results.map { feedEntity in
            let detachedEntity = FeedEntity()
            detachedEntity.nextPage = feedEntity.nextPage
            detachedEntity.city = feedEntity.city
            detachedEntity.fromNearby = feedEntity.fromNearby
            detachedEntity.content = feedEntity.content
            return detachedEntity
        }
        
    }

    // Insert or update a feed
    func insertFeed(feed: FeedEntity) {
        let realm = getRealm() // Get a thread-safe Realm instance
        try! realm.write {
            realm.add(feed, update: .modified) // Update if exists
        }
    }

    // Update a feed
    func updateFeed(feed: FeedEntity) {
        let realm = getRealm() // Get a thread-safe Realm instance
        try! realm.write {
            realm.add(feed, update: .modified) // Use `add` with `.modified` for updates
        }
    }
}
