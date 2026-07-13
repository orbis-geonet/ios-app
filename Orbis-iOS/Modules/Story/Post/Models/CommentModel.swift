//
//  CommentModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 18/04/2021.
//

import Foundation


typealias OrbisPostCommentsRequests = [OrbisPostCommentRequest]

struct OrbisPostCommentRequest {
    var text: String
    var replyToKey: String?
    
    var toParameter: [String: Any] {
        var parameter = [
            "text": text
        ]
        if let commentKey = replyToKey {
            parameter["replyToKey"] = commentKey
        }
        return parameter
    }
}

typealias PostComments = [PostComment]

struct PostComment: Codable {
    var commentKey: String
    var post: OrbisFeedPost?
    var replyToKey: String?
    var replies: PostComments?
    var user: OrbisUser?
    var text: String
    var timestamp: String?
    var deleted: Bool?
    var likesCount: Int?
    var hasLiked: Bool?
    var isPending: Bool = false
    
    var commentPostedDateString: String {
        return Date.fromString(string: timestamp ?? "", with: ISOCommonFormatter.shared)?.timeAgoSinceNow() ?? ""
    }
    
    enum CodingKeys: String, CodingKey {
        case commentKey
        case post
        case replyToKey
        case replies
        case user
        case text
        case timestamp
        case deleted
        case likesCount
        case hasLiked = "userLiked"
    }
    
    var hasMoreReplies: Bool {
        return false
    }
    
    var hasReplies: Bool {
        if let replies = self.replies {
            return replies.count > 0
        }
        return false
    }
    
    init(key: String, text: String, post: OrbisFeedPost) {
        self.commentKey = key
        self.text = text
        self.post = post
        self.isPending = true
        self.user = UserSessionManager.shared.currentUser
        self.timestamp = Date().isoDateString
    }
    
    init(key: String, text: String, post: OrbisFeedPost, commentKey: String) {
        self.commentKey = key
        self.text = text
        self.post = post
        self.replyToKey = commentKey
        self.isPending = true
        self.user = UserSessionManager.shared.currentUser
        self.timestamp = Date().isoDateString
    }
    
    var toCommentRequestObject: OrbisPostCommentRequest {
        return OrbisPostCommentRequest(text: text, replyToKey: replyToKey)
    }
    
    mutating func incrementLike() {
        guard let likeCount = likesCount else {
            likesCount = 1
            return
        }
        likesCount = likeCount + 1
    }
    
    mutating func decrementLike() {
        guard let likeCount = likesCount else {
            likesCount = 0
            return
        }
        likesCount = (likeCount - 1) < 0 ? 0 : (likeCount - 1)
    }
}
