//
//  PlaceDetailViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 03/04/2021.
//

import Foundation
import Alamofire
import CoreLocation

class PlaceDetailViewModel {
    var model: OrbisPlace!
    let manager = OrbisPlaceDetailManager()
    let eventManager = EventDetailManager()
    var eventPosts = OrbisFeedPosts()
    var nearbyGroups: Groups {
        return model.competingGroups?.sorted(by: {$0.percentage ?? 0 > $1.percentage ?? 0}) ?? []
    }
    var isEventsView: Bool = false
    var placeDescription: String {
        return (model.description ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppStrings.Places.emptyPlaceDescription : (model.description ?? "")
    }
    var placeDistance: Double {
//        guard let userLocation = UserSessionManager.shared.userCurrentLocation, let placeLoc = model.coordinates else { return Double.greatestFiniteMagnitude }
        guard let userLocation = Constants.location?.coordinate, let placeLoc = model.coordinates else { return Double.greatestFiniteMagnitude }
        let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let coordinates = CLLocation(latitude: placeLoc.latitude ?? 0, longitude: placeLoc.longitude ?? 0)
        return userLoc.distance(from: coordinates) / 1000
    }
    var isFollowUnfollowProcessing = false
    
    init(place: OrbisPlace) {
        self.model = place
        initializePagination()
        initializeEventsPagination()
    }
    
    var placeFeed: OrbisFeedPostResponses = []
    
    var onPlaceDetailSyncError: ((Error) -> Void)?
    var onPlaceDetailSyncSuccess: (() -> Void)?
    
    var onPlaceDetailUpdateError: ((Error) -> Void)?
    var onPlaceDetailUpdateSuccess: (() -> Void)?
    
    var onPlaceFeedFetched: (() -> Void)?
    var onPlaceFeedFetchedCompletePagination: (() -> Void)?
    var onPlaceFeedFetchError: ((Error) -> Void)?
    
    var onPostUpdated: (() -> Void)?
    
    var hasItemsLastPageReached = false
    var nextPageToken: String = ""
    private let offsetVal: Int = 50
    
    var onEventFeedFetched: (() -> Void)?
    var onEventFeedFetchedCompletePagination: (() -> Void)?
    var onEventFeedFetchError: ((Error) -> Void)?
    var onEventPostUpdated: (() -> Void)?
    
    var hasEventsItemLastPageReached = false
    var eventsPage: Int = 0
    private let eventsPageSize = 20
    
    var hasUserRated: Bool {
        return (model.userRate != nil)
    }
    
    var eventPostsCount: Int {
        return eventPosts.count + 2 // +1 for header cell +1 for event header cell
    }
    
    func getEventPostModel(at index: Int) -> OrbisFeedPost {
        return eventPosts[index]
    }
    
    func initializePagination() {
        placeFeed = OrbisSharedCreatePostManager.shared.pendingPosts.filter({$0.place?.placeKey == self.model.placeKey}).toPostListData
        hasItemsLastPageReached = false
        nextPageToken = ""
    }
    
    func initializeEventsPagination() {
        hasEventsItemLastPageReached = false
        eventPosts = []
        eventsPage = 0
    }
    
    var selfUser: OrbisUser? {
        return UserSessionManager.shared.currentUser
    }
    
    var isLoggedIn: Bool {
        if let user = selfUser, let key = user.userKey, !key.isEmpty {
            return true
        }
        return false
    }
    
    var hasFeedPosts: Bool {
        if isEventsView {
            return eventPostsCount > 2
        }
        return feedCount > 2
    }
    
    var canEditPlace: Bool {
        guard isLoggedIn else { return false }
        return model.canEdit ?? true
    }
    
    var feedCount: Int {
        return placeFeed.count + 2 // +1 for header cell +1 for group dominant cell
    }
    
    func updateSliderPageIndex(at index: Int, value: Int) {
        placeFeed[index].currentSliderPageIndex = value
    }
    
    func getFeedPostModel(at index: Int) -> OrbisFeedPostResponse {
        return placeFeed[index]
    }
    
    func syncPlaceDataWithServer() {
        manager.syncPlaceDetail(forPlace: self.model.placeKey!) { [weak self] (data, err) in
            if let error = err {
                self?.onPlaceDetailSyncError?(error)
                return
            }
            if let place = data as? OrbisPlace {
                self?.model = place
                self?.onPlaceDetailSyncSuccess?()
            }
            else {
                self?.onPlaceDetailSyncError?(ResponseError.invalidData)
            }
        }
    }
    
    func updatePlaceDescription(withText text: String) {
        let param: [String: Any] = [PlaceDomainParameterKeys.Update.description: text]
        manager.updatePlaceData(placeKey: self.model.placeKey!, withParam: param) { [weak self] (data, err) in
            if let error = err {
                self?.onPlaceDetailUpdateError?(error)
                return
            }
            if let place = data as? OrbisPlace {
                self?.model = place
                self?.onPlaceDetailUpdateSuccess?()
            }
            else {
                self?.onPlaceDetailUpdateError?(ResponseError.invalidData)
            }
        }
    }
    
    func uploadPlacePicture(image: UIImage) {
        let fileName = UUID().uuidString
        manager.uploadPlaceImage(withName: fileName, image: image) { [weak self] (data, err) in
            if let error = err {
                self?.onPlaceDetailUpdateError?(error)
                return
            }
            else {
                self?.updatePlacePictureData(imageName: data as! String)
            }
        }
    }
    
    private func updatePlacePictureData(imageName: String) {
        let param: [String: Any] = [PlaceDomainParameterKeys.Update.imageName: imageName]
        manager.updatePlaceData(placeKey: self.model.placeKey!, withParam: param) { [weak self] (data, err) in
            if let error = err {
                self?.onPlaceDetailUpdateError?(error)
                return
            }
            if let place = data as? OrbisPlace {
                self?.model = place
                self?.onPlaceDetailUpdateSuccess?()
            }
            else {
                self?.onPlaceDetailUpdateError?(ResponseError.invalidData)
            }
        }
    }
    
    func loadPlaceFeed() {
        self.manager.fetchPlaceFeed(placeKey: self.model.placeKey!, from: nextPageToken, limit: offsetVal) { [weak self] (data, err) in
            guard let self = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                        return
                    }
                    self.onPlaceFeedFetchError?(error)
                    return
                }
                else {
                    if let response = data as? OrbisFeedPaginatedResponse, let items = response.content {
                        if items.count > 0 {
                            self.placeFeed = (OrbisSharedCreatePostManager.shared.pendingPosts).filter({$0.place?.placeKey == self.model.placeKey}).toPostListData + items
                            self.onPlaceFeedFetched?()
                            self.nextPageToken = response.nextPage ?? ""
                            self.hasItemsLastPageReached = false
                        }
                        else {
                            self.hasItemsLastPageReached = true
                            self.onPlaceFeedFetchedCompletePagination?()
                        }
                    }
                    else {
                        self.hasItemsLastPageReached = true
                        self.onPlaceFeedFetchedCompletePagination?()
                        return
                    }
                }
        }
    }
    
    func loadMorePlaceFeed() {
        self.manager.fetchPlaceFeed(placeKey: self.model.placeKey!, from: nextPageToken, limit: offsetVal)  { [weak self] (data, err) in
                if let error = err {
                    if let afError = error as? AFError {
                        if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                            return
                        }
                    }
                    self?.onPlaceFeedFetchError?(error)
                    return
                }
                else {
                    if let response = data as? OrbisFeedPaginatedResponse, let items = response.content {
                        if items.count > 0 {
                            self?.placeFeed.append(contentsOf: items)
                            self?.onPlaceFeedFetched?()
                            self?.nextPageToken = response.nextPage ?? ""
                            self?.hasItemsLastPageReached = false
                        }
                        else {
                            self?.hasItemsLastPageReached = true
                            self?.onPlaceFeedFetchedCompletePagination?()
                        }
                    }
                    else {
                        self?.hasItemsLastPageReached = true
                        self?.onPlaceFeedFetchedCompletePagination?()
                        return
                    }
                }
        }
    }
    
    func followUnfollow(completion: @escaping responseBlock) {
        self.isFollowUnfollowProcessing = true
        if self.model.isFollowing {
            manager.unfollowPlace(key: self.model.placeKey!) { [weak self] data, err in
                self?.isFollowUnfollowProcessing = false
                if err == nil {
                    self?.model.following = false
                }
                completion(data, err)
            }
        }
        else {
            manager.followPlace(placeKey: self.model.placeKey!) { [weak self] data, err in
                self?.isFollowUnfollowProcessing = false
                if err == nil {
                    self?.model.following = true
                }
                completion(data, err)
            }
        }
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
    
    func reportPlace(withText text: String, completion: @escaping responseBlock) {
        guard let _ = UserSessionManager.shared.currentUser else { return }
        manager.reportPlace(key: self.model.placeKey!, text: text, completion: completion)
    }
    
    func reportPost(post: OrbisFeedPost, withText text: String, completion: @escaping responseBlock) {
        guard let _ = UserSessionManager.shared.currentUser else { return }
        OrbisSharedPostLikeCommentManager.shared.reportPost(post: post, text: text, completion: completion)
    }
    
    func removePost(postKey: String) {
        if let postIndex = self.placeFeed.firstIndex(where: {$0.post?.postKey == postKey}) {
            self.placeFeed.remove(at: postIndex)
        }
        else if let postIndex = self.placeFeed.firstIndex(where: {$0.slider?.contains(where: {$0.postKey == postKey}) ?? false}), var postSlider = self.placeFeed[postIndex].slider, let sliderPostIndex = postSlider.firstIndex(where: {$0.postKey == postKey}) {
            postSlider.remove(at: sliderPostIndex)
            var postObject = self.placeFeed[postIndex]
            postObject.slider = postSlider
            self.placeFeed[postIndex] = postObject
        }
        if let postIndex = self.eventPosts.firstIndex(where: {$0.postKey == postKey})  {
            self.eventPosts.remove(at: postIndex)
        }
        onPostUpdated?()
    }
    
    func updatePost(newPost: OrbisFeedPost, notify: Bool = true) {
        if var postObject = self.placeFeed.first(where: {$0.post?.postKey == newPost.postKey}), let post = postObject.post, let postIndex = self.placeFeed.firstIndex(where: {$0.post?.postKey == post.postKey}) {
            postObject.post = newPost
            self.placeFeed[postIndex] = postObject
            notify ? onPostUpdated?() : ()
        }
        else if let postIndex = self.placeFeed.firstIndex(where: {$0.slider?.contains(where: {$0.postKey == newPost.postKey}) ?? false}), var postSlider = self.placeFeed[postIndex].slider, let sliderPostIndex = postSlider.firstIndex(where: {$0.postKey == newPost.postKey}) {
            postSlider[sliderPostIndex] = newPost
            var postObject = self.placeFeed[postIndex]
            postObject.slider = postSlider
            self.placeFeed[postIndex] = postObject
            notify ? onPostUpdated?() : ()
        }
        if let postIndex = self.eventPosts.firstIndex(where: {$0.postKey == newPost.postKey}) {
            self.eventPosts[postIndex] = newPost
            notify ? onPostUpdated?() : ()
        }
    }
    
    func updateCommentCount(key: String, count: Int) {
        updatePostsCommentCount(key: key, count: count)
    }
    
    private func updatePostsCommentCount(key: String, count: Int) {
        if var postObject = self.placeFeed.first(where: {$0.post?.postKey == key}), var post = postObject.post, let postIndex = self.placeFeed.firstIndex(where: {$0.post?.postKey == post.postKey}) {
            post.commentsCount = count
            postObject.post = post
            self.placeFeed[postIndex] = postObject
        }
        else if let postIndex = self.placeFeed.firstIndex(where: {$0.slider?.contains(where: {$0.postKey == key}) ?? false}), var postSlider = self.placeFeed[postIndex].slider, var sliderPost = postSlider.first(where: {$0.postKey == key}), let sliderPostIndex = postSlider.firstIndex(where: {$0.postKey == key}) {
            sliderPost.commentsCount = count
            postSlider[sliderPostIndex] = sliderPost
            var postObject = self.placeFeed[postIndex]
            postObject.slider = postSlider
            self.placeFeed[postIndex] = postObject
        }
    }
    
    func getIndex(for post: OrbisFeedPost) -> Int? {
        if let postObject = self.placeFeed.first(where: {$0.post?.postKey == post.postKey}), let post = postObject.post, let postIndex = self.placeFeed.firstIndex(where: {$0.post?.postKey == post.postKey}) {
            return postIndex
        }
        return nil
    }
    
    func replaceExpandedPost(expandedPost newPost: OrbisFeedPost) {
        if var postObject = self.placeFeed.first(where: {$0.post?.postKey == newPost.postKey}), let post = postObject.post, let postIndex = self.placeFeed.firstIndex(where: {$0.post?.postKey == post.postKey}) {
            postObject.post = newPost
            self.placeFeed[postIndex] = postObject
        }
        else if let postIndex = self.placeFeed.firstIndex(where: {$0.slider?.contains(where: {$0.postKey == newPost.postKey}) ?? false}), var postSlider = self.placeFeed[postIndex].slider, let sliderPostIndex = postSlider.firstIndex(where: {$0.postKey == newPost.postKey}) {
            postSlider[sliderPostIndex] = newPost
            var postObject = self.placeFeed[postIndex]
            postObject.slider = postSlider
            self.placeFeed[postIndex] = postObject
        }
    }
    
    // MARK:- Events
    
    func loadPlaceEvents() {
        self.manager.fetchPlaceEvents(placeKey: self.model.placeKey!, page: self.eventsPage, limit: self.eventsPageSize) { [weak self] (data, err) in
            guard let self = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                        return
                    }
                    if let afError = error as? AFError {
                        if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                            return
                        }
                    }
                    self.onEventFeedFetchError?(error)
                    return
                }
                else {
                    if let items = data as? OrbisFeedPosts {
                        if items.count > 0 {
                            self.eventPosts = items
                            self.onEventFeedFetched?()
                            self.eventsPage += 1
                            self.hasEventsItemLastPageReached = false
                        }
                        else {
                            self.hasEventsItemLastPageReached = true
                            self.onEventFeedFetchedCompletePagination?()
                        }
                    }
                    else {
                        self.onEventFeedFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
    
    func loadMorePlaceEvents() {
        self.manager.fetchPlaceEvents(placeKey: self.model.placeKey!, page: self.eventsPage, limit: self.eventsPageSize) { [weak self] (data, err) in
            guard let self = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                        return
                    }
                    if let afError = error as? AFError {
                        if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                            return
                        }
                    }
                    self.onEventFeedFetchError?(error)
                    return
                }
                else {
                    if let items = data as? OrbisFeedPosts {
                        if items.count > 0 {
                            self.eventPosts.append(contentsOf: items)
                            self.onEventFeedFetched?()
                            self.eventsPage += 1
                            self.hasEventsItemLastPageReached = false
                        }
                        else {
                            self.hasEventsItemLastPageReached = true
                            self.onEventFeedFetchedCompletePagination?()
                        }
                    }
                    else {
                        self.onEventFeedFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
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
}
