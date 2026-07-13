//
//  FeedViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/03/2021.
//

import Foundation
import UIKit
import Alamofire
import CoreLocation
import GoogleMobileAds

enum OrbisNewsFeedType: String {
    case newsFeed
    case nearbyFeed
}

class MyFeedViewModel {
    let type: OrbisNewsFeedType!
    let manager = NewsFeedManager()
    var posts: OrbisFeedPostResponses = []
    let eventManager = EventDetailManager()
    let groupManager = GroupDetailManager()
    var stories: OrbisStories = []
    var containsStories: Bool {
        return stories.count > 0
    }
    
    var onFeedFetched: (() -> Void)?
    var onFeedFetchedCompletePagination: (() -> Void)?
    var onFeedFetchError: ((Error) -> Void)?
    var onFeedUpdated: (() -> Void)?
    
    var hasItemsLastPageReached = false
    var nextPageToken: String = ""
    private let offsetVal: Int = 50
    private let nearbyDistance: Double = 25
    
    var onStoriesFetched: (() -> Void)?
    var onStoriesFetchedCompletePagination: (() -> Void)?
    var onStoriesFetchError: ((Error) -> Void)?
    var onStoriesUpdated: (() -> Void)?
    
    var hasStoriesItemsLastPageReached = false
    var storiesListSeenParam: Bool = false
    var storiesPageNumber: Int = 0
    private let storiesPageSize: Int = 250
    
    var isAdsEnabled: Bool {
        return AppFirebaseConfigManager.shared.isAdsEnabled
    }
    var adsFrequency: Int {
        return AppFirebaseConfigManager.shared.feedAdsFrequency
    }
    
    var nativeAds = [NativeAd]()
    
    var userCurrentLocation: CLLocationCoordinate2D? {
        return UserSessionManager.shared.userCurrentLocation
    }
    
    let feedRepositories = FeedRepositories()
    
    @Published var feed: [OrbisFeedPaginatedResponse] = []
    var isInitialfeedLoad = true
    
    init(type: OrbisNewsFeedType) {
        self.type = type
        initializePagination()
        initializeStoriesPagination()
    }
    
    var shouldFetchMoreAds: Bool {
        let purePostsCount = posts.filter({$0.feedPostType != .nativeAd}).count
        let maxAdsCount = purePostsCount / adsFrequency
        return nativeAds.count < maxAdsCount
    }
    
    var feedCount: Int {
        return containsStories ? posts.count + 1 : posts.count // +1 for story cell
    }
    
    var hasFeedPosts: Bool {
        return posts.count > 0
    }
    
    func appendAdsIfNecessary() {
        guard isAdsEnabled && nativeAds.count > 0 else {
            return
        }
        posts.removeAll(where: {$0.feedPostType == .nativeAd})
        guard posts.count > adsFrequency else {
            return
        }
        let numberOfPostsToAppend = posts.count / adsFrequency
        var adPosition = adsFrequency
        var appendedAds = 0
        adLoop: for nativeAd in nativeAds {
            let adPost = OrbisFeedPostResponse(type: OrbisFeedPostType.nativeAd.rawValue, post: nil, slider: nil, ad: nativeAd, from: nil)
            if numberOfPostsToAppend > appendedAds {
                self.posts.insert(adPost, at: adPosition)
                appendedAds += 1
                adPosition = (adsFrequency * (appendedAds + 1)) + appendedAds
            }
            else {
                break adLoop
            }
        }
    }
    
    func updateSliderPageIndex(at index: Int, value: Int) {
        posts[index].currentSliderPageIndex = value
    }
    
    func getPostModel(at index: Int) -> OrbisFeedPostResponse {
        return posts[index]
    }
    
    func getIndex(for post: OrbisFeedPost) -> Int? {
        if let postObject = self.posts.first(where: {$0.post?.postKey == post.postKey}), let post = postObject.post, let postIndex = self.posts.firstIndex(where: {$0.post?.postKey == post.postKey}) {
            return postIndex
        }
        return nil
    }
    
    func initializePagination() {
        posts = OrbisSharedCreatePostManager.shared.pendingPosts.toPostListData
        hasItemsLastPageReached = false
        nextPageToken = ""
    }
    
    func initializeStoriesPagination() {
        stories = []
        hasStoriesItemsLastPageReached = false
        storiesPageNumber = 0
        storiesListSeenParam = false
    }
    
    func reorderStoriesWRTSeen() {
        var unseenStories = OrbisStories()
        var seenStories = OrbisStories()
        stories.forEach { story in
            story.hasSeenAll ? seenStories.append(story) : unseenStories.append(story)
        }
        self.stories = unseenStories + seenStories
        self.onFeedFetched?()
    }
    
    func loadNewsFeed(isUpdated: Bool = false) {
//        guard let loc = self.userCurrentLocation else {
//            onFeedFetchError?(CommonError.emptyUserLocation)
//            return
//        }
        if !isUpdated {
            self.getNewsFeedFirst()
        }else{
            //Delete current all feed  within that city
            DispatchQueue.global(qos: .background).async {
                //print("cachingSystem: all nearby feed for city \(currentCity) deleted")
                self.feedRepositories.deleteMyCachedFeed(city: Constants.feedCity ?? "")
            }
        }
        
        guard let loc = Constants.location?.coordinate else {
            NetLog.log("⚠︎ feed blocked: Constants.location nil")
            onFeedFetchError?(CommonError.emptyUserLocation)
            return
        }
        
        initializePagination()
        self.manager.invalidateAllNewsFeedNetworkRequests { [weak self] _, _ in
            guard let self = self else { return }
//            self.manager.fetchNewsFeed(longitude: loc.longitude, latitude: loc.latitude, from: self.nextPageToken, limit: self.offsetVal) { [weak self] (data, err) in
//                guard let self = self else { return }
            self.manager.fetchNewsFeed(longitude: loc.longitude, latitude: loc.latitude, from: self.nextPageToken, limit: self.offsetVal) { [weak self] (data, err) in
                guard let self = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                        return
                    }
                    self.onFeedFetchError?(error)
                    return
                }
                else {
                    if let response = data as? OrbisFeedPaginatedResponse, let items = response.content {
                        if items.count > 0 {
                            
                            //MARK: Cache Data
                            let newData = convertFeedToFeedEntityMyFeed(feed: response, currentCity: Constants.feedCity ?? "")
                            //print("cachingSystem: caching \(t.content?.count ?? 0) on \(currentCity)")
                            DispatchQueue.global(qos: .background).async {
                                self.feedRepositories.cacheFeed(feedList: newData)
                            }
                            //MARK: End of Cache Data
                            
                            self.posts = OrbisSharedCreatePostManager.shared.pendingPosts.toPostListData + items
                            self.nextPageToken = response.nextPage ?? ""
                            self.hasItemsLastPageReached = false
                            self.appendAdsIfNecessary()
                            self.onFeedFetched?()
                        }
                        else {
                            self.hasItemsLastPageReached = true
                            self.onFeedFetchedCompletePagination?()
                        }
                    }
                    else {
                        self.hasItemsLastPageReached = true
                        self.onFeedFetchedCompletePagination?()
                        return
                    }
                }
            }
        }
    }
    
    func loadMoreNewsFeed() {
//        guard let loc = self.userCurrentLocation else {
//            onFeedFetchError?(CommonError.emptyUserLocation)
//            return
//        }
        
        
        guard let loc = Constants.location?.coordinate else {
            NetLog.log("⚠︎ feed blocked: Constants.location nil")
            onFeedFetchError?(CommonError.emptyUserLocation)
            return
        }
        
        
        self.manager.fetchNewsFeed(longitude: loc.longitude, latitude: loc.latitude, from: self.nextPageToken, limit: self.offsetVal)  { [weak self] (data, err) in
            if let error = err {
                if let afError = error as? AFError {
                    if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                        return
                    }
                }
                self?.onFeedFetchError?(error)
                return
            }
            else {
                if let response = data as? OrbisFeedPaginatedResponse, let items = response.content {
                    if items.count > 0 {
                        self?.posts.append(contentsOf: items)
                        self?.nextPageToken = response.nextPage ?? ""
                        self?.hasItemsLastPageReached = false
                        self?.appendAdsIfNecessary()
                        self?.onFeedFetched?()
                    }
                    else {
                        self?.hasItemsLastPageReached = true
                        self?.onFeedFetchedCompletePagination?()
                    }
                }
                else {
                    self?.hasItemsLastPageReached = true
                    self?.onFeedFetchedCompletePagination?()
                    return
                }
            }
        }
    }
    
    func loadNewsStories() {
        initializeStoriesPagination()
        self.manager.invalidateAllNewsFeedStoriesNetworkRequests { [weak self] _, _ in
            guard let self = self else { return }
            self.manager.fetchNewsStories(seen: self.storiesListSeenParam, page: self.storiesPageNumber, limit: self.storiesPageSize) { [weak self] (data, err) in
                guard let self = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                        return
                    }
                    self.onStoriesFetchError?(error)
                    return
                }
                else {
                    if let items = data as? OrbisStories {
                        if items.count > 0 {
                            self.stories = items
                            self.onStoriesFetched?()
                            self.storiesPageNumber += 1
                            self.hasStoriesItemsLastPageReached = false
                        }
                        else {
                            if self.storiesListSeenParam == false {
                                self.storiesListSeenParam = true
                                self.storiesPageNumber = 0
                                self.hasStoriesItemsLastPageReached = false
                                self.loadMoreNewsStories()
                            }
                            else {
                                self.hasStoriesItemsLastPageReached = true
                                self.onStoriesFetchedCompletePagination?()
                            }
                        }
                    }
                    else {
                        self.onStoriesFetchError?(ResponseError.invalidData)
                        return
                    }
                }
            }
        }
    }
    
    func loadMoreNewsStories() {
        self.manager.fetchNewsStories(seen: self.storiesListSeenParam, page: self.storiesPageNumber, limit: self.storiesPageSize)  { [weak self] (data, err) in
            guard let self = self else { return }
            if let error = err {
                if let afError = error as? AFError {
                    if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                        return
                    }
                }
                self.onStoriesFetchError?(error)
                return
            }
            else {
                if let items = data as? OrbisStories {
                    if items.count > 0 {
                        self.stories.append(contentsOf: items)
                        self.onStoriesFetched?()
                        self.storiesPageNumber += 1
                        self.hasStoriesItemsLastPageReached = false
                    }
                    else {
                        if self.storiesListSeenParam == false {
                            self.storiesListSeenParam = true
                            self.storiesPageNumber = 0
                            self.hasStoriesItemsLastPageReached = false
                            self.loadMoreNewsStories()
                        }
                        else {
                            self.hasStoriesItemsLastPageReached = true
                            self.onStoriesFetchedCompletePagination?()
                        }
                    }
                }
                else {
                    self.onStoriesFetchError?(ResponseError.invalidData)
                    return
                }
            }
        }
    }
    
    // MARK:- Nearby feed load
    
    func loadNearbyFeed(isUpdated: Bool = false) {
//        guard let loc = self.userCurrentLocation else {
//            onFeedFetchError?(CommonError.emptyUserLocation)
//            return
//        }
        if !isUpdated {
            self.getNearByFeedFirst()
        }else{
            //Delete current all feed  within that city
            DispatchQueue.global(qos: .background).async {
               // print("cachingSystem: all nearby feed for city \(currentCity) deleted")
                self.feedRepositories.deleteNearByCachedFeed(city: Constants.feedCity ?? "")
            }
        }
        
        guard let loc = Constants.location?.coordinate else {
            NetLog.log("⚠︎ feed blocked: Constants.location nil")
            onFeedFetchError?(CommonError.emptyUserLocation)
            return
        }
        
        initializePagination()
        self.manager.invalidateAllNearbyFeedNetworkRequests { [weak self] _, _ in
            guard let self = self else { return }
//            self.manager.fetchNearbyFeed(distance: self.nearbyDistance, longitude: loc.longitude, latitude: loc.latitude, from: self.nextPageToken, limit: self.offsetVal) { [weak self] (data, err) in
            self.manager.fetchNearbyFeed(distance: self.nearbyDistance, longitude: loc.longitude, latitude: loc.latitude, from: self.nextPageToken, limit: self.offsetVal) { [weak self] (data, err) in
                guard let self = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                        return
                    }
                    self.onFeedFetchError?(error)
                    return
                }
                else {
                    if let response = data as? OrbisFeedPaginatedResponse, let items = response.content {
                        if items.count > 0 {
                            //MARK: Cache Data
                            let newData = convertFeedToFeedEntityMyFeed(feed: response, currentCity: Constants.feedCity ?? "")
                            //print("cachingSystem: caching \(t.content?.count ?? 0) on \(currentCity)")
                            DispatchQueue.global(qos: .background).async {
                                if (isUpdated){
                                    self.feedRepositories.cacheFeed(feedList: newData)
                                }else{
                                    self.manageCacheForNewData(feed: response, currentCity: Constants.feedCity ?? "")
                                }
                            }
                            //MARK: End of Cache Data
                            
                            self.posts = OrbisSharedCreatePostManager.shared.pendingPosts.toPostListData + items
                            self.nextPageToken = response.nextPage ?? ""
                            self.hasItemsLastPageReached = false
                            self.appendAdsIfNecessary()
                            self.onFeedFetched?()
                        }
                        else {
                            self.hasItemsLastPageReached = true
                            self.onFeedFetchedCompletePagination?()
                        }
                    }
                    else {
                        self.hasItemsLastPageReached = true
                        self.onFeedFetchedCompletePagination?()
                        return
                    }
                }
            }
        }
    }
    
    func loadMoreNearbyFeed() {
        // Parity: use Constants.location (map-camera coords) like the other five loaders, not the
        // GPS-only userCurrentLocation — otherwise nearby-feed page 1 loads but pages 2+ strand a
        // location-denied / city-picked user. (Was the lone loader missed by the migration.)
        guard let loc = Constants.location?.coordinate else {
            NetLog.log("⚠︎ feed blocked: Constants.location nil")
            onFeedFetchError?(CommonError.emptyUserLocation)
            return
        }
        
        
        self.manager.fetchNearbyFeed(distance: self.nearbyDistance,longitude: loc.longitude, latitude: loc.latitude, from: self.nextPageToken, limit: self.offsetVal)  { [weak self] (data, err) in
            if let error = err {
                if let afError = error as? AFError {
                    if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                        return
                    }
                }
                self?.onFeedFetchError?(error)
                return
            }
            else {
                if let response = data as? OrbisFeedPaginatedResponse, let items = response.content {
                    if items.count > 0 {
                        self?.posts.append(contentsOf: items)
                        self?.nextPageToken = response.nextPage ?? ""
                        self?.hasItemsLastPageReached = false
                        self?.appendAdsIfNecessary()
                        self?.onFeedFetched?()
                    }
                    else {
                        self?.hasItemsLastPageReached = true
                        self?.onFeedFetchedCompletePagination?()
                    }
                }
                else {
                    self?.hasItemsLastPageReached = true
                    self?.onFeedFetchedCompletePagination?()
                    return
                }
            }
        }
    }
    
    func loadNearbyStories() {
//        guard let loc = self.userCurrentLocation else {
//            onStoriesFetchError?(CommonError.emptyUserLocation)
//            return
//        }
        
        guard let loc = Constants.location?.coordinate else {
            NetLog.log("⚠︎ feed blocked: Constants.location nil")
            onFeedFetchError?(CommonError.emptyUserLocation)
            return
        }
        
        
        initializeStoriesPagination()
        self.manager.invalidateAllNearbyStoriesNetworkRequests { [weak self] _, _ in
            guard let self = self else { return }
            self.manager.fetchNearbyStories(longitude: loc.longitude, latitude: loc.latitude, seen: self.storiesListSeenParam, page: self.storiesPageNumber, limit: self.storiesPageSize) { [weak self] (data, err) in
                guard let self = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                        return
                    }
                    self.onStoriesFetchError?(error)
                    return
                }
                else {
                    if let items = data as? OrbisStories {
                        if items.count > 0 {
                            self.stories = items
                            self.onStoriesFetched?()
                            self.storiesPageNumber += 1
                            self.hasStoriesItemsLastPageReached = false
                        }
                        else {
                            if self.storiesListSeenParam == false {
                                self.storiesListSeenParam = true
                                self.storiesPageNumber = 0
                                self.hasStoriesItemsLastPageReached = false
                                self.loadMoreNearbyStories()
                            }
                            else {
                                self.hasStoriesItemsLastPageReached = true
                                self.onStoriesFetchedCompletePagination?()
                            }
                        }
                    }
                    else {
                        self.onStoriesFetchError?(ResponseError.invalidData)
                        return
                    }
                }
            }
        }
    }
    
    func loadMoreNearbyStories() {
//        guard let loc = self.userCurrentLocation else {
//            onStoriesFetchError?(CommonError.emptyUserLocation)
//            return
//        }
        
        
        guard let loc = Constants.location?.coordinate else {
            NetLog.log("⚠︎ feed blocked: Constants.location nil")
            onFeedFetchError?(CommonError.emptyUserLocation)
            return
        }
        
        
        self.manager.fetchNearbyStories(longitude: loc.longitude, latitude: loc.latitude, seen: self.storiesListSeenParam, page: self.storiesPageNumber, limit: self.storiesPageSize)  { [weak self] (data, err) in
            print("data is \(data)")
            if let error = err {
                if let afError = error as? AFError {
                    if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                        return
                    }
                }
                self?.onStoriesFetchError?(error)
                return
            }
            else {
                if let items = data as? OrbisStories {
                    print("total items are \(items.count)")
                    if items.count > 0 {
                        for item in items {
                            if self?.stories.contains(where: {$0.group.groupKey == item.group.groupKey}) == false {
                                self?.stories.append(item)
                            }
                        }
                        self?.onStoriesFetched?()
                        self?.storiesPageNumber += 1
                        self?.hasStoriesItemsLastPageReached = false
                    }
                    else {
                        if self?.storiesListSeenParam == false {
                            self?.storiesListSeenParam = true
                            self?.storiesPageNumber = 0
                            self?.hasStoriesItemsLastPageReached = false
                            self?.loadMoreNearbyStories()
                        }
                        else {
                            self?.hasStoriesItemsLastPageReached = true
                            self?.onStoriesFetchedCompletePagination?()
                        }
                    }
                }
                else {
                    self?.onStoriesFetchError?(ResponseError.invalidData)
                    return
                }
            }
        }
    }
    
    func markStorySeen(key: String) {
        guard let storyObj = self.stories.first(where: {$0.posts.contains(where: {$0.postKey == key})}), let storyIndex = self.stories.firstIndex(where: {$0.storyKey == storyObj.storyKey}) else { return }
        guard var post = storyObj.posts.first(where: {$0.postKey == key }), let postIndex = storyObj.posts.firstIndex(where: {$0.postKey == key}) else { return }
        post.seen = true
        storyObj.posts[postIndex] = post
        self.stories[storyIndex] = storyObj
        manager.markStorySeen(postKey: key) { data, err in
            if let error = err {
                debugPrint("Error in marking story read: \(error.localizedDescription)")
            }
        }
    }
    
    func updateCommentCount(key: String, count: Int) {
        updateStoriesCommentCount(key: key, count: count)
        updatePostsCommentCount(key: key, count: count)
    }
    
    private func updatePostsCommentCount(key: String, count: Int) {
        if var postObject = self.posts.first(where: {$0.post?.postKey == key}), var post = postObject.post, let postIndex = self.posts.firstIndex(where: {$0.post?.postKey == post.postKey}) {
            post.commentsCount = count
            postObject.post = post
            self.posts[postIndex] = postObject
        }
        else if let postIndex = self.posts.firstIndex(where: {$0.slider?.contains(where: {$0.postKey == key}) ?? false}), var postSlider = self.posts[postIndex].slider, var sliderPost = postSlider.first(where: {$0.postKey == key}), let sliderPostIndex = postSlider.firstIndex(where: {$0.postKey == key}) {
            sliderPost.commentsCount = count
            postSlider[sliderPostIndex] = sliderPost
            var postObject = self.posts[postIndex]
            postObject.slider = postSlider
            self.posts[postIndex] = postObject
        }
    }
    
    private func updateStoriesCommentCount(key: String, count: Int) {
        guard let storyObj = self.stories.first(where: {$0.posts.contains(where: {$0.postKey == key})}), let storyIndex = self.stories.firstIndex(where: {$0.storyKey == storyObj.storyKey}) else { return }
        guard var post = storyObj.posts.first(where: {$0.postKey == key }), let postIndex = storyObj.posts.firstIndex(where: {$0.postKey == key}) else { return }
        post.commentsCount = count
        storyObj.posts[postIndex] = post
        self.stories[storyIndex] = storyObj
    }
    
    func likeUnlikePost(post: OrbisFeedPost) {
        guard let _ = UserSessionManager.shared.currentUser else { return }
        let hasLiked = post.hasLiked ?? false
        if hasLiked {
            var updatedLikePost = post
            updatedLikePost.hasLiked = false
            updatedLikePost.decrementLike()
            self.updatePost(newPost: updatedLikePost)
            OrbisSharedPostLikeCommentManager.shared.unlikePost(key: post.postKey!) { [weak self] data, err in
                if let post = data as? OrbisFeedPost {
                    self?.updatePost(newPost: post)
                }
            }
        }
        else {
            var updatedLikePost = post
            updatedLikePost.hasLiked = true
            updatedLikePost.incrementLike()
            self.updatePost(newPost: updatedLikePost)
            OrbisSharedPostLikeCommentManager.shared.likePost(key: post.postKey!) { [weak self] data, err in
                if let post = data as? OrbisFeedPost {
                    self?.updatePost(newPost: post)
                }
            }
        }
    }
    
    func reportPost(post: OrbisFeedPost, withText text: String, completion: @escaping responseBlock) {
        guard let _ = UserSessionManager.shared.currentUser else { return }
        OrbisSharedPostLikeCommentManager.shared.reportPost(post: post, text: text, completion: completion)
    }
    
    func removePost(postKey: String) {
        if let postIndex = self.posts.firstIndex(where: {$0.post?.postKey == postKey}) {
            self.posts.remove(at: postIndex)
        }
        else if let postIndex = self.posts.firstIndex(where: {$0.slider?.contains(where: {$0.postKey == postKey}) ?? false}), var postSlider = self.posts[postIndex].slider, let sliderPostIndex = postSlider.firstIndex(where: {$0.postKey == postKey}) {
            postSlider.remove(at: sliderPostIndex)
            var postObject = self.posts[postIndex]
            postObject.slider = postSlider
            self.posts[postIndex] = postObject
        }
        appendAdsIfNecessary()
        onFeedUpdated?()
        removeStoryPost(postKey: postKey)
    }
    
    private func removeStoryPost(postKey: String) {
        guard let storyObj = self.stories.first(where: {$0.posts.contains(where: {$0.postKey == postKey})}), let storyIndex = self.stories.firstIndex(where: {$0.storyKey == storyObj.storyKey}) else { return }
        guard let postIndex = storyObj.posts.firstIndex(where: {$0.postKey == postKey}) else { return }
        storyObj.posts.remove(at: postIndex)
        self.stories[storyIndex] = storyObj
        onStoriesUpdated?()
    }
    
    func updatePost(newPost: OrbisFeedPost, notify: Bool = true) {
        if var postObject = self.posts.first(where: {$0.post?.postKey == newPost.postKey}), let post = postObject.post, let postIndex = self.posts.firstIndex(where: {$0.post?.postKey == post.postKey}) {
            postObject.post = newPost
            self.posts[postIndex] = postObject
        }
        else if let postIndex = self.posts.firstIndex(where: {$0.slider?.contains(where: {$0.postKey == newPost.postKey}) ?? false}), var postSlider = self.posts[postIndex].slider, let sliderPostIndex = postSlider.firstIndex(where: {$0.postKey == newPost.postKey}) {
            postSlider[sliderPostIndex] = newPost
            var postObject = self.posts[postIndex]
            postObject.slider = postSlider
            self.posts[postIndex] = postObject
        }
        notify ? onFeedUpdated?() : ()
        updateStoryPost(newPost: newPost)
    }
    
    func replaceExpandedPost(expandedPost newPost: OrbisFeedPost) {
        if var postObject = self.posts.first(where: {$0.post?.postKey == newPost.postKey}), let post = postObject.post, let postIndex = self.posts.firstIndex(where: {$0.post?.postKey == post.postKey}) {
            postObject.post = newPost
            self.posts[postIndex] = postObject
        }
        else if let postIndex = self.posts.firstIndex(where: {$0.slider?.contains(where: {$0.postKey == newPost.postKey}) ?? false}), var postSlider = self.posts[postIndex].slider, let sliderPostIndex = postSlider.firstIndex(where: {$0.postKey == newPost.postKey}) {
            postSlider[sliderPostIndex] = newPost
            var postObject = self.posts[postIndex]
            postObject.slider = postSlider
            self.posts[postIndex] = postObject
        }
    }
    
    private func updateStoryPost(newPost: OrbisFeedPost, notify: Bool = true) {
        guard let storyObj = self.stories.first(where: {$0.posts.contains(where: {$0.postKey == newPost.postKey})}), let storyIndex = self.stories.firstIndex(where: {$0.storyKey == storyObj.storyKey}) else { return }
        guard let postIndex = storyObj.posts.firstIndex(where: {$0.postKey == newPost.postKey}) else { return }
        storyObj.posts[postIndex] = newPost
        self.stories[storyIndex] = storyObj
        notify ? onStoriesUpdated?() : ()
    }
    
    func attendCancelAttendEvent(event: OrbisFeedPost, completion: @escaping responseBlock) {
        if event.attending == true {
            eventManager.cancelAttendEvent(key: event.postKey!) { [weak self] data, err in
                if let error = err {
                    completion(nil, error)
                }
                else {
                    var updatedEvent = event
                    updatedEvent.attending = false
                    self?.updatePost(newPost: updatedEvent)
                    completion(true, nil)
                }
            }
        }
        else {
            eventManager.attendEvent(key: event.postKey!) { [weak self] data, err in
                if let error = err {
                    completion(nil, error)
                }
                else {
                    var updatedEvent = event
                    updatedEvent.attending = true
                    self?.updatePost(newPost: updatedEvent)
                    completion(true, nil)
                }
            }
        }
    }
    
    func unfollowGroupStories(at index: Int, completion: @escaping responseBlock) {
        guard let groupKey = stories[index].group.groupKey else {
            completion(false, nil)
            return
        }
        groupManager.hideStories(fromGroup: groupKey) { [weak self] result, error in
            if let error = error {
                completion(nil, error)
            }
            else {
                self?.stories.remove(at: index)
                completion(true, nil)
            }
        }
    }
}
//MARK:- Cached Section
extension MyFeedViewModel {
    
    func getNearByFeedFirst() {
        if !Constants.newKMNewsFeedSession {
            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let self = self else { return }
                
                // Create a thread-safe Realm instance
                let cachedFeeds = self.feedRepositories.getCachedNearByFeed(city: Constants.feedCity ?? "")

                DispatchQueue.main.async {
                    if !cachedFeeds.isEmpty {
                        let newFeed = self.convertFeedEntitiesToFeed(feedEntities: cachedFeeds)
                        self.feed.append(newFeed)
                        
                        if let newContent = newFeed.content {
                            self.posts.append(contentsOf: newContent)
                            self.onFeedFetched?()
                        }
                    }
                }
            }
        } else {
            DispatchQueue.global(qos: .background).async {
                self.feedRepositories.deleteNearByCachedFeed(city: Constants.feedCity ?? "")
            }
            Constants.newKMNewsFeedSession = false
        }
    }

    
    func getNewsFeedFirst(){
        
        if !Constants.newMyFeedSession {
            
            DispatchQueue.global(qos: .background).async { [weak self] in
                
                guard let self = self else { return }
                
                let cachedFeeds = self.feedRepositories.getCachedMyFeed(city: Constants.feedCity ?? "")
                
                DispatchQueue.main.async {
                    
                    //print("cachingSystem: found my feeds on \(String(describing: Constants.feedCity))")
                    
                    if !cachedFeeds.isEmpty {
                        
                        let newFeed = self.convertFeedEntitiesToFeed(feedEntities: cachedFeeds)
                        //self.posts.append(newFeed.content)
                        if let newContent = newFeed.content {
                            self.posts.append(contentsOf: newContent)
                            self.onFeedFetched?()
                        } else {
                            print("newFeed.content is nil")
                        }
                    }
                }
            }
        } else {
           // print("cachingSystem: deleting my feeds on \(city)")
            
            DispatchQueue.global(qos: .background).async {
                self.feedRepositories.deleteMyCachedFeed(city: Constants.feedCity ?? "")
            }
            Constants.newMyFeedSession = false
        }
    }
    
    func manageCacheForNewData(feed: OrbisFeedPaginatedResponse, currentCity: String) {
        let newData = convertFeedToFeedEntity(feed: feed, currentCity: currentCity)

        DispatchQueue.global(qos: .background).async {
            // Create a thread-safe Realm instance
            if self.feedRepositories.isPageContained(page: feed.nextPage ?? "") {
                self.feedRepositories.modifyCachedFeed(feedList: newData)
            } else {
                self.feedRepositories.cacheFeed(feedList: newData)
            }
        }
    }

    func manageCacheForNewDataInFirstNearBy(feedEntities: [FeedEntity], currentCity: String) {
        DispatchQueue.global(qos: .background).async {
            for feedEntity in feedEntities {
                if self.feedRepositories.isPageContained(page: feedEntity.nextPage) {
                    print("cachingSystem: updating \(currentCity)")
                    self.feedRepositories.modifyCachedFeed(feedList: feedEntity)
                } else {
                    print("cachingSystem: all nearby feeds for city \(currentCity) deleted")
                    self.feedRepositories.deleteNearByCachedFeed(city: currentCity)
                    
                    print("cachingSystem: caching new data for city \(currentCity)")
                    self.feedRepositories.cacheFeed(feedList: feedEntity)
                }
            }
        }
    }
    func manageCacheForNewDataInFirstMyFeed(feed: OrbisFeedPaginatedResponse, currentCity: String) {
        let newData = convertFeedToFeedEntityMyFeed(feed: feed, currentCity: currentCity)
        
        DispatchQueue.global(qos: .background).async {
            if self.feedRepositories.isPageContained(page: feed.nextPage!) {
               // print("cachingSystem: updating \(feed.content?.count) on \(currentCity)")
                self.feedRepositories.modifyCachedFeed(feedList: newData)
            } else {
               // print("cachingSystem: all MY feed for city \(currentCity) deleted")
                self.feedRepositories.deleteMyCachedFeed(city: currentCity)
                
                //print("cachingSystem: caching \(feed.content?.count) on \(currentCity)")
                self.feedRepositories.cacheFeed(feedList: newData)
            }
        }
    }
    
    func convertFeedEntitiesToFeed(feedEntities: [FeedEntity]) -> OrbisFeedPaginatedResponse {
        var combinedContent = [OrbisFeedPostResponse]()
        var lastNextPage: String? = nil

        for feedEntity in feedEntities {
            if let jsonData = feedEntity.content.data(using: .utf8) {
                do {
                    // Decode `content` into an array of `OrbisFeedPostResponse`
                    let decodedContent = try JSONDecoder().decode([OrbisFeedPostResponse].self, from: jsonData)
                    combinedContent.append(contentsOf: decodedContent)
                } catch {
                    print("Error decoding feed entity content: \(error)")
                }
            }
            lastNextPage = feedEntity.nextPage // Update `nextPage` with the last available value
        }

        return OrbisFeedPaginatedResponse(nextPage: lastNextPage, content: combinedContent)
    }
    func convertFeedToFeedEntity(feed: OrbisFeedPaginatedResponse, currentCity: String) -> FeedEntity {
        let jsonData = try? JSONEncoder().encode(feed.content)
        let contentJson = jsonData != nil ? String(data: jsonData!, encoding: .utf8) : nil
        
        let entity = FeedEntity()
        entity.nextPage = feed.nextPage ?? ""
        entity.city = currentCity
        entity.content = contentJson ?? ""
        return entity
    }
    func convertFeedToFeedEntityMyFeed(feed: OrbisFeedPaginatedResponse, currentCity: String) -> FeedEntity {
        let jsonData = try? JSONEncoder().encode(feed.content)
        let contentJson = jsonData != nil ? String(data: jsonData!, encoding: .utf8) : nil
        
        let entity = FeedEntity()
        entity.nextPage = feed.nextPage ?? ""
        entity.city = currentCity
        entity.fromNearby = false
        entity.content = contentJson ?? ""
        return entity
    }

}
