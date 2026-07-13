//
//  OrbisPostModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 04/05/2021.
//

import Foundation
import UIKit
import GoogleMobileAds

struct OrbisRichLinkData: Codable {
    var canonicalUrl: String?
    var description: String?
    var imageUrl: String?
    var originalUrl: String?
    var title: String?
}

enum OrbisFeedPostType: String {
    case slider = "SLIDER"
    case post = "POST"
    case nativeAd = "NATIVE_GAD"
}

struct OrbisFeedPaginatedResponse: Codable {
    var nextPage: String?
    var content: OrbisFeedPostResponses?
}

typealias OrbisFeedPostResponses = [OrbisFeedPostResponse]

struct OrbisFeedPostResponse: Codable {
    var type: String
    var post: OrbisFeedPost?
    var slider: OrbisFeedPosts?
    var ad: NativeAd?
    var feedPostType: OrbisFeedPostType {
        return OrbisFeedPostType(rawValue: self.type) ?? .post
    }
    var from: String?
    var currentSliderPageIndex: Int = 0
    
    enum CodingKeys: String, CodingKey {
        case type
        case post
        case slider
        case from
    }
}

typealias OrbisFeedPosts = [OrbisFeedPost]

struct OrbisFeedPost: Codable {
    var coordinates: OrbisLocationModel?
    var postKey: String?
    var checkInPolygonCoordinateKey: String?
    var timestamp: String?
    var type: String?
    var title: String?
    var details: String?
    var richLinkData: OrbisRichLinkData?
    var mediaUrls: [String]?
    var signedUrls: [String]?
    var group: Group?
    var user: OrbisUser?
    var place: OrbisPlace?
    var seen: Bool?
    var likesCount: Int?
    var commentsCount: Int?
    var hasLiked: Bool?
    //Event parameters
    var address: String?
    var plannedTime: String?
    var plannedEndTime: String?
    var confirmedUsers: OrbisUsers?
    var shareLink: String?
    var attending: Bool?
    var confirmedCount: Int?
    
    var isDeleted = false
    
    var isDescriptionExpanded: Bool = false
    
    var postType: OrbisPostType {
        return OrbisPostType(rawValue: type ?? "") ?? .unknown
    }
    
    init(key: String) {
        self.postKey = key
    }
    
    init(user: OrbisUser, datePosted: String, feedDescription: String, imageLinks: [String], likeCount: Int, commentCount: Int, hasLiked: Bool, showOtherUsers: Bool, type: OrbisPostType, location: String ) {
        self.user = user
        self.timestamp = datePosted
        self.details = feedDescription
        self.mediaUrls = imageLinks
        self.type = type.rawValue
//        if type == .checkinPost {
//            checkinPosts = FeedManager.shared.getRandomCheckinPosts()
//        }
    }
    
    enum CodingKeys: String, CodingKey {
        case coordinates
        case postKey
        case checkInPolygonCoordinateKey
        case timestamp
        case type
        case title
        case details
        case richLinkData
        case mediaUrls
        case signedUrls
        case group
        case user
        case place
        case seen
        case likesCount
        case commentsCount
        case hasLiked = "userLiked"
        case address
        case plannedTime
        case plannedEndTime
        case confirmedUsers
        case shareLink
        case attending
        case confirmedCount
    }

    var likeCount: Int {
        return likesCount ?? 0
    }
    var commentCount: Int {
        return commentsCount ?? 0
    }
    var showOtherUsers: Bool {
        if let _ = group {
            return user != nil
        }
        return false
    }
    var location: String {
        return place?.name ?? ""
    }
    var checkinPosts: OrbisFeedPosts? = nil
    var isPendingPost = false
    var pendingPostImages: [UIImage]? = nil
    var pendingPostImagesData: [Data]? = nil
    var pendingPostVideos: [String]? = nil
    
    var isSelfPostedOrSuperAdmin: Bool {
        if let user = UserSessionManager.shared.currentUser {
            if user.superAdmin == true {
                return true
            }
            return self.user?.userKey == user.userKey
        }
        return false
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
    
    mutating func incrementComment() {
        guard let commentCount = commentsCount else {
            commentsCount = 1
            return
        }
        commentsCount = commentCount + 1
    }
    
    mutating func decrementComment() {
        guard let commentCount = commentsCount else {
            commentsCount = 0
            return
        }
        commentsCount = (commentCount - 1) < 0 ? 0 : (commentCount - 1)
    }
}

extension OrbisFeedPosts {
    
    var toPostListData: OrbisFeedPostResponses {
        var data = OrbisFeedPostResponses()
        self.forEach { post in
            let postData =  OrbisFeedPostResponse(type: OrbisFeedPostType.post.rawValue, post: post, slider: nil)
            if !data.contains(where: {$0.post?.postKey == post.postKey}) {
                data.append(postData)
            }
        }
        return data
    }
    
}
