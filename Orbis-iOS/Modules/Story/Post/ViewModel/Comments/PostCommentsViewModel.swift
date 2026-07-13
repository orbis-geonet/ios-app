//
//  PostCommentsViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 18/04/2021.
//

import Foundation
import Alamofire

class PostCommentsViewModel {
    var post: OrbisFeedPost!
    var postId: String {
        return self.post.postKey!
    }
    var comments: PostComments = []
    let manager = CommentsManager()
    var hasItemsLastPageReached = false
    var pageNumber: Int = 0
    private let offsetVal: Int = 10
    
    var onCommentsFetched: (() -> Void)?
    var onCommentsFetchedCompletePagination: (() -> Void)?
    var onCommentsFetchError: ((Error) -> Void)?
    
    var onNewCommentAdded: (() -> Void)?
    var onNewCommentRemoved: (() -> Void)?
    var onNewCommentAddFailure: ((Error) -> Void)?
    
    var onCommentsUpdated: ((Int) -> Void)?
    
    var userProPicLink: String {
        return UserSessionManager.shared.currentUser?.proPicLink ?? ""
    }
    
    var totalCommentCount: Int {
        var repliesCount = 0
        self.comments.forEach { comment in
            let commentRepliesCount = comment.replies?.count ?? 0
            repliesCount += commentRepliesCount
        }
        let totalCommentCount = comments.count + repliesCount
        return totalCommentCount
    }
    
    init(post: OrbisFeedPost) {
        self.post = post
        addCommentPostObservers()
        initializePagination()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func initializePagination() {
        comments = []
        hasItemsLastPageReached = false
        pageNumber = 0
    }
    
    private func addCommentPostObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(newCommentPostDidSucceed(_:)), name: NSNotification.Name(AppNotificationKeys.Comment.pendingCommentPostSuccess), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newCommentPostDidFail(_:)), name: NSNotification.Name(AppNotificationKeys.Comment.pendingCommentPostFailure), object: nil)
    }
    
    @objc private func newCommentPostDidSucceed(_ notification: NSNotification) {
        guard let objc = notification.object as? (PostComment, PostComment) else { return }
        guard let index = comments.firstIndex(where: {$0.commentKey == objc.1.commentKey}) else { return }
        comments[index] = objc.0
        onNewCommentAdded?()
    }
    
    @objc private func newCommentPostDidFail(_ notification: NSNotification) {
        guard let objc = notification.object as? (Error, PostComment) else { return }
        self.comments.removeAll(where: {$0.commentKey == objc.1.commentKey})
        onNewCommentAddFailure?(objc.0)
    }
    
    var count: Int {
        return comments.count
    }
    
    func getComment(at index: Int) -> PostComment {
        return comments[index]
    }
    
//    func loadMoreReplies(forIndex index: Int) {
//        var comment = comments[index]
//        let reply = manager.getRandomCommentReply(forComment: comment.id)
//        comment.replies?.append(reply)
//        comments[index] = comment
//    }
    
    func loadPostComments() {
        self.manager.fetchPostComments(postKey: self.postId, page: pageNumber, limit: offsetVal) { [weak self] (data, err) in
                guard let strongSelf2 = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") || nsError.description.contains("cancelled") {
                        return
                    }
                    if let afError = error as? AFError {
                        if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                            return
                        }
                    }
                    self?.onCommentsFetchError?(error)
                    return
                }
                else {
                    if let items = data as? PostComments {
                        if items.count > 0 {
                            self?.comments = items
                            self?.pageNumber = strongSelf2.pageNumber + 1
                            self?.hasItemsLastPageReached = false
                            self?.onCommentsFetched?()
                        }
                        else {
                            self?.hasItemsLastPageReached = true
                            self?.onCommentsFetchedCompletePagination?()
                        }
                    }
                    else {
                        self?.onCommentsFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
    
    func loadMorePostComments() {
        self.manager.fetchPostComments(postKey: self.postId, page: pageNumber, limit: offsetVal) { [weak self] (data, err) in
                guard let strongSelf2 = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") || nsError.description.contains("cancelled") {
                        return
                    }
                    if let afError = error as? AFError {
                        if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                            return
                        }
                    }
                    self?.onCommentsFetchError?(error)
                    return
                }
                else {
                    if let items = data as? PostComments {
                        if items.count > 0 {
                            self?.comments.append(contentsOf: items)
                            self?.pageNumber = strongSelf2.pageNumber + 1
                            self?.hasItemsLastPageReached = false
                            self?.onCommentsFetched?()
                        }
                        else {
                            self?.hasItemsLastPageReached = true
                            self?.onCommentsFetchedCompletePagination?()
                        }
                    }
                    else {
                        self?.onCommentsFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
    
    func postComment(text: String) {
        let newComment = OrbisSharedPostLikeCommentManager.shared.postComment(toPost: self.post, text: text)
        self.comments.append(newComment)
        let commentCountTuple = (postId, totalCommentCount)
        NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Comment.commentCountUpdated), object: commentCountTuple)
        onNewCommentAdded?()
    }
    
    func postCommentReply(text: String, commentKey: String) {
        if let index = self.comments.firstIndex(where: {$0.commentKey == commentKey}) {
            let newCommentReply = OrbisSharedPostLikeCommentManager.shared.postCommentReply(toComment: commentKey, post: self.post, text: text)
            var modifiedComment = self.comments[index]
            modifiedComment.replies?.append(newCommentReply)
            comments[index] = modifiedComment
            let commentCountTuple = (postId, totalCommentCount)
            NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Comment.commentCountUpdated), object: commentCountTuple)
            onNewCommentAdded?()
        }
    }
    
    func deleteComment(key: String) {
        OrbisSharedPostLikeCommentManager.shared.deleteComment(fromPost: self.postId, key: key)
        comments.removeAll(where: {$0.commentKey == key})
        let commentCountTuple = (postId, totalCommentCount)
        NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Comment.commentCountUpdated), object: commentCountTuple)
        onNewCommentRemoved?()
    }
    
    func deleteCommentReply(key: String, fromComment commentKey: String) {
        if let index = self.comments.firstIndex(where: {$0.commentKey == commentKey}) {
            OrbisSharedPostLikeCommentManager.shared.deleteComment(fromPost: self.postId, key: key)
            var modifiedComment = self.comments[index]
            modifiedComment.replies?.removeAll(where: {$0.commentKey == key})
            comments[index] = modifiedComment
            let commentCountTuple = (postId, totalCommentCount)
            NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Comment.commentCountUpdated), object: commentCountTuple)
            onNewCommentRemoved?()
        }
        
    }
    
    func likeUnlikeComment(comment: PostComment) {
        guard let _ = UserSessionManager.shared.currentUser else { return }
        let hasLiked = comment.hasLiked ?? false
        if hasLiked {
            var updatedComment = comment
            updatedComment.hasLiked = false
            updatedComment.decrementLike()
            self.updateComment(newComment: updatedComment)
            OrbisSharedPostLikeCommentManager.shared.unlikeComment(key: comment.commentKey, postKey: self.post!.postKey!) { [weak self] data, err in
                if let comment = data as? PostComment {
                    self?.updateComment(newComment: comment)
                }
            }
        }
        else {
            var updatedComment = comment
            updatedComment.hasLiked = true
            updatedComment.incrementLike()
            self.updateComment(newComment: updatedComment)
            OrbisSharedPostLikeCommentManager.shared.likeComment(key: comment.commentKey, postKey: self.post!.postKey!) { [weak self] data, err in
                if let comment = data as? PostComment {
                    self?.updateComment(newComment: comment)
                }
            }
        }
    }
    
    private func updateComment(newComment: PostComment) {
        if let commentIndex = self.comments.firstIndex(where: {$0.commentKey == newComment.commentKey}) {
            self.comments[commentIndex] = newComment
            onCommentsUpdated?(commentIndex)
        }
        else if var commentObjc = self.comments.first(where: {$0.replies?.contains(where: {$0.commentKey == newComment.commentKey}) == true}), let commentIndex = self.comments.firstIndex(where: {$0.commentKey == commentObjc.commentKey}) {
            if let replyIndex = commentObjc.replies?.firstIndex(where: {$0.commentKey == newComment.commentKey}) {
                commentObjc.replies?[replyIndex] = newComment
                self.comments[commentIndex] = commentObjc
                onCommentsUpdated?(commentIndex)
            }
        }
    }
}
