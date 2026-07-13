//
//  ProfileFeedViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 02/04/2021.
//

import Foundation
import Alamofire

class ProfileFeedViewModel {
    let detailManager = UserProfileManager()
    let eventManager = EventDetailManager()
    var user: OrbisUser!
    let isViewingSelf: Bool!
    
    var onUserFeedFetched: (() -> Void)?
    var onUserFeedFetchedCompletePagination: (() -> Void)?
    var onUserFeedFetchError: ((Error) -> Void)?
    
    var onPostUpdated: (() -> Void)?
    
    var userFeed: OrbisFeedPostResponses = []
    var hasItemsLastPageReached = false
    var nextPageToken: String = ""
    private let offsetVal: Int = 50
    
    init(user: OrbisUser!, isViewingSelf: Bool) {
        self.isViewingSelf = isViewingSelf
        self.user = user
        initializePagination()
    }
    
    var hasFeedPosts: Bool {
        return feedCount > 0
    }
    
    var feedCount: Int {
        return userFeed.count
    }
    
    func updateSliderPageIndex(at index: Int, value: Int) {
        userFeed[index].currentSliderPageIndex = value
    }
    
    func getFeedPostModel(at index: Int) -> OrbisFeedPostResponse {
        return userFeed[index]
    }
    
    func initializePagination() {
        userFeed = OrbisSharedCreatePostManager.shared.pendingPosts.filter({$0.user?.userKey == self.user.userKey}).toPostListData
        hasItemsLastPageReached = false
        nextPageToken = ""
    }
    
    func loadUserFeed() {
        self.detailManager.fetchUserFeed(userKey: self.user.userKey!, from: nextPageToken, limit: offsetVal) { [weak self] (data, err) in
            guard let self = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                        return
                    }
                    self.onUserFeedFetchError?(error)
                    return
                }
                else {
                    if let response = data as? OrbisFeedPaginatedResponse, let items = response.content {
                        if items.count > 0 {
                            self.userFeed = (OrbisSharedCreatePostManager.shared.pendingPosts).filter({$0.user?.userKey == self.user.userKey}).toPostListData + items
                            self.onUserFeedFetched?()
                            self.nextPageToken = response.nextPage ?? ""
                            self.hasItemsLastPageReached = false
                        }
                        else {
                            self.hasItemsLastPageReached = true
                            self.onUserFeedFetchedCompletePagination?()
                        }
                    }
                    else {
                        self.hasItemsLastPageReached = true
                        self.onUserFeedFetchedCompletePagination?()
                        return
                    }
                }
        }
    }
    
    func loadMoreUserFeed() {
        self.detailManager.fetchUserFeed(userKey: self.user.userKey!, from: nextPageToken, limit: offsetVal)  { [weak self] (data, err) in
                if let error = err {
                    if let afError = error as? AFError {
                        if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                            return
                        }
                    }
                    self?.onUserFeedFetchError?(error)
                    return
                }
                else {
                    if let response = data as? OrbisFeedPaginatedResponse, let items = response.content {
                        if items.count > 0 {
                            self?.userFeed.append(contentsOf: items)
                            self?.onUserFeedFetched?()
                            self?.nextPageToken = response.nextPage ?? ""
                            self?.hasItemsLastPageReached = false
                        }
                        else {
                            self?.hasItemsLastPageReached = true
                            self?.onUserFeedFetchedCompletePagination?()
                        }
                    }
                    else {
                        self?.hasItemsLastPageReached = true
                        self?.onUserFeedFetchedCompletePagination?()
                        return
                    }
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
    
    func reportPost(post: OrbisFeedPost, withText text: String, completion: @escaping responseBlock) {
        guard let _ = UserSessionManager.shared.currentUser else { return }
        OrbisSharedPostLikeCommentManager.shared.reportPost(post: post, text: text, completion: completion)
    }
    
    func removePost(postKey: String) {
        if let postIndex = self.userFeed.firstIndex(where: {$0.post?.postKey == postKey}) {
            self.userFeed.remove(at: postIndex)
        }
        else if let postIndex = self.userFeed.firstIndex(where: {$0.slider?.contains(where: {$0.postKey == postKey}) ?? false}), var postSlider = self.userFeed[postIndex].slider, let sliderPostIndex = postSlider.firstIndex(where: {$0.postKey == postKey}) {
            postSlider.remove(at: sliderPostIndex)
            var postObject = self.userFeed[postIndex]
            postObject.slider = postSlider
            self.userFeed[postIndex] = postObject
        }
        onPostUpdated?()
    }
    
    func updatePost(newPost: OrbisFeedPost, notify: Bool = true) {
        if var postObject = self.userFeed.first(where: {$0.post?.postKey == newPost.postKey}), let post = postObject.post, let postIndex = self.userFeed.firstIndex(where: {$0.post?.postKey == post.postKey}) {
            postObject.post = newPost
            self.userFeed[postIndex] = postObject
            notify ? onPostUpdated?() : ()
        }
        else if let postIndex = self.userFeed.firstIndex(where: {$0.slider?.contains(where: {$0.postKey == newPost.postKey}) ?? false}), var postSlider = self.userFeed[postIndex].slider, let sliderPostIndex = postSlider.firstIndex(where: {$0.postKey == newPost.postKey}) {
            postSlider[sliderPostIndex] = newPost
            var postObject = self.userFeed[postIndex]
            postObject.slider = postSlider
            self.userFeed[postIndex] = postObject
            notify ? onPostUpdated?() : ()
        }
    }
    
    func updateCommentCount(key: String, count: Int) {
        updatePostsCommentCount(key: key, count: count)
    }
    
    private func updatePostsCommentCount(key: String, count: Int) {
        if var postObject = self.userFeed.first(where: {$0.post?.postKey == key}), var post = postObject.post, let postIndex = self.userFeed.firstIndex(where: {$0.post?.postKey == post.postKey}) {
            post.commentsCount = count
            postObject.post = post
            self.userFeed[postIndex] = postObject
        }
        else if let postIndex = self.userFeed.firstIndex(where: {$0.slider?.contains(where: {$0.postKey == key}) ?? false}), var postSlider = self.userFeed[postIndex].slider, var sliderPost = postSlider.first(where: {$0.postKey == key}), let sliderPostIndex = postSlider.firstIndex(where: {$0.postKey == key}) {
            sliderPost.commentsCount = count
            postSlider[sliderPostIndex] = sliderPost
            var postObject = self.userFeed[postIndex]
            postObject.slider = postSlider
            self.userFeed[postIndex] = postObject
        }
    }
    
    func getIndex(for post: OrbisFeedPost) -> Int? {
        if let postObject = self.userFeed.first(where: {$0.post?.postKey == post.postKey}), let post = postObject.post, let postIndex = self.userFeed.firstIndex(where: {$0.post?.postKey == post.postKey}) {
            return postIndex
        }
        return nil
    }
    
    func replaceExpandedPost(expandedPost newPost: OrbisFeedPost) {
        if var postObject = self.userFeed.first(where: {$0.post?.postKey == newPost.postKey}), let post = postObject.post, let postIndex = self.userFeed.firstIndex(where: {$0.post?.postKey == post.postKey}) {
            postObject.post = newPost
            self.userFeed[postIndex] = postObject
        }
        else if let postIndex = self.userFeed.firstIndex(where: {$0.slider?.contains(where: {$0.postKey == newPost.postKey}) ?? false}), var postSlider = self.userFeed[postIndex].slider, let sliderPostIndex = postSlider.firstIndex(where: {$0.postKey == newPost.postKey}) {
            postSlider[sliderPostIndex] = newPost
            var postObject = self.userFeed[postIndex]
            postObject.slider = postSlider
            self.userFeed[postIndex] = postObject
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
