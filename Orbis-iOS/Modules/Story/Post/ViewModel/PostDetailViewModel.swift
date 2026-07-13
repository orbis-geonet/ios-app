//
//  PostDetailViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 11/08/2021.
//

import Foundation
import Alamofire
import CoreLocation

class PostDetailViewModel {
    var model: OrbisFeedPost!
    let manager = PostDetailManager()
    let eventManager = EventDetailManager()
    var sliderPageIndex: Int = 0
    
    init(post: OrbisFeedPost, pageIndex: Int) {
        self.model = post
        self.sliderPageIndex = pageIndex
    }
    
    var onPostDetailSyncError: ((Error) -> Void)?
    var onPostDetailSyncSuccess: (() -> Void)?
    var onPostUpdated: (() -> Void)?

    func updateSliderPageIndex(value: Int) {
        self.sliderPageIndex = value
    }
    
    func syncPostDetailsWithServer() {
        manager.fetchPostDetails(withKey: model.postKey!) { [weak self] (data, err) in
            if let error = err {
                self?.onPostDetailSyncError?(error)
                return
            }
            if let post = data as? OrbisFeedPost {
                self?.model = post
                self?.onPostDetailSyncSuccess?()
            }
            else {
                self?.onPostDetailSyncError?(ResponseError.invalidData)
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
    
    func updatePost(newPost: OrbisFeedPost, notify: Bool = true) {
        guard newPost.postKey == self.model.postKey else { return }
        self.model = newPost
        notify ? onPostUpdated?() : ()
    }
    
    func replaceExpandedPost(expandedPost newPost: OrbisFeedPost) {
        guard newPost.postKey == self.model.postKey else { return }
        self.model = newPost
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
