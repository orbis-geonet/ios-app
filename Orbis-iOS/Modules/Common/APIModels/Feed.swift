//
//  Feed.swift
//  Orbis-iOS
//
//  Created by Kamran on 02/11/2024.
//


import Foundation

struct Feed: Codable {
    let nextPage: String
    let content: [FeedContent]

    init(nextPage: String, content: [FeedContent] = []) {
        self.nextPage = nextPage
        self.content = content
    }
}

import Foundation

struct FeedContent: Codable {
    var type: String
    var post: FeedPost?
    var slider: [FeedPost]
    var group: GroupDetails?
    var place: PlaceDetails?
    var placeUploadPhoto: URL?
    var showNoItem: Bool?
    var loaded: Bool
    var stories: [StoryModel]
    var comments: [CommentModel]
    var noItemTitle: String

    enum CodingKeys: String, CodingKey {
        case type
        case post
        case slider
        case group
        case place
        case placeUploadPhoto
        case showNoItem
        case loaded
        case stories
        case comments
        case noItemTitle
    }

    init(
        type: String = "",
        post: FeedPost? = nil,
        slider: [FeedPost] = [],
        group: GroupDetails? = nil,
        place: PlaceDetails? = nil,
        placeUploadPhoto: URL? = nil,
        showNoItem: Bool? = nil,
        loaded: Bool = false,
        stories: [StoryModel] = [],
        comments: [CommentModel] = [],
        noItemTitle: String = ""
    ) {
        self.type = type
        self.post = post
        self.slider = slider
        self.group = group
        self.place = place
        self.placeUploadPhoto = placeUploadPhoto
        self.showNoItem = showNoItem
        self.loaded = loaded
        self.stories = stories
        self.comments = comments
        self.noItemTitle = noItemTitle
    }
}


struct StoryModel: Codable {
    let storyKey: String
    let group: GroupDetails
    let posts: [FeedPost]

    enum CodingKeys: String, CodingKey {
        case storyKey
        case group
        case posts
    }

    init(storyKey: String, group: GroupDetails, posts: [FeedPost] = []) {
        self.storyKey = storyKey
        self.group = group
        self.posts = posts
    }
}


struct CommentModel: Codable {
    let commentKey: String
    let text: String
    let timestamp: String
    let createTimestamp: String
    let deleted: Bool
    var userLiked: Bool
    var likesCount: Int
    let post: FeedPost
    let replies: [ReplyModel]
    let user: UserProfile
    var selectedForReply: Bool = false

    enum CodingKeys: String, CodingKey {
        case commentKey
        case text
        case timestamp
        case createTimestamp
        case deleted
        case userLiked
        case likesCount
        case post
        case replies
        case user
        case selectedForReply
    }

    init(
        commentKey: String,
        text: String,
        timestamp: String,
        createTimestamp: String,
        deleted: Bool,
        userLiked: Bool,
        likesCount: Int,
        post: FeedPost,
        replies: [ReplyModel] = [],
        user: UserProfile,
        selectedForReply: Bool = false
    ) {
        self.commentKey = commentKey
        self.text = text
        self.timestamp = timestamp
        self.createTimestamp = createTimestamp
        self.deleted = deleted
        self.userLiked = userLiked
        self.likesCount = likesCount
        self.post = post
        self.replies = replies
        self.user = user
        self.selectedForReply = selectedForReply
    }
}

struct ReplyModel: Codable {
    let commentKey: String
    let replyToKey: String
    let user: UserProfile
    let text: String
    let timestamp: String
    let createTimestamp: String
    let deleted: Bool
    var likesCount: Int
    var userLiked: Bool

    enum CodingKeys: String, CodingKey {
        case commentKey
        case replyToKey
        case user
        case text
        case timestamp
        case createTimestamp
        case deleted
        case likesCount
        case userLiked
    }

    init(
        commentKey: String,
        replyToKey: String,
        user: UserProfile,
        text: String,
        timestamp: String,
        createTimestamp: String,
        deleted: Bool,
        likesCount: Int,
        userLiked: Bool
    ) {
        self.commentKey = commentKey
        self.replyToKey = replyToKey
        self.user = user
        self.text = text
        self.timestamp = timestamp
        self.createTimestamp = createTimestamp
        self.deleted = deleted
        self.likesCount = likesCount
        self.userLiked = userLiked
    }
}
