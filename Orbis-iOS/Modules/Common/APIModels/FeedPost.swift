//
//  FeedPost.swift
//  Orbis-iOS
//
//  Created by Kamran on 02/11/2024.
//


import Foundation

struct FeedPost: Codable {
    let coordinates: Coordinates?
    let postKey: String
    let checkInPolygonCoordinateKey: String
    let timestamp: String
    var type: String
    let title: String
    let details: String
    let address: String
    var richLinkData: RichLinkDatakeys?
    var group: GroupDetails?
    let signedUrls: [String]
    let mediaUrls: [String]
    var postVideo: String
    var postAudio: String
    var place: PlaceDetails?
    let shareLink: String
    let plannedTime: String
    let plannedEndTime: String
    var attending: Bool
    var user: UserInfo?
    var commentsCount: Int
    var likesCount: Int
    let confirmedCount: Int
    var userLiked: Bool
    var seen: Bool
    var attendedUsers: [User]

    init(
        coordinates: Coordinates? = nil,
        postKey: String = "",
        checkInPolygonCoordinateKey: String = "",
        timestamp: String = "",
        type: String = "",
        title: String = "",
        details: String = "",
        address: String = "",
        richLinkData: RichLinkDatakeys? = nil,
        group: GroupDetails? = nil,
        signedUrls: [String] = [],
        mediaUrls: [String] = [],
        postVideo: String = "",
        postAudio: String = "",
        place: PlaceDetails? = nil,
        shareLink: String = "",
        plannedTime: String = "",
        plannedEndTime: String = "",
        attending: Bool = false,
        user: UserInfo? = nil,
        commentsCount: Int = 0,
        likesCount: Int = 0,
        confirmedCount: Int = 0,
        userLiked: Bool = false,
        seen: Bool = false,
        attendedUsers: [User] = []
    ) {
        self.coordinates = coordinates
        self.postKey = postKey
        self.checkInPolygonCoordinateKey = checkInPolygonCoordinateKey
        self.timestamp = timestamp
        self.type = type
        self.title = title
        self.details = details
        self.address = address
        self.richLinkData = richLinkData
        self.group = group
        self.signedUrls = signedUrls
        self.mediaUrls = mediaUrls
        self.postVideo = postVideo
        self.postAudio = postAudio
        self.place = place
        self.shareLink = shareLink
        self.plannedTime = plannedTime
        self.plannedEndTime = plannedEndTime
        self.attending = attending
        self.user = user
        self.commentsCount = commentsCount
        self.likesCount = likesCount
        self.confirmedCount = confirmedCount
        self.userLiked = userLiked
        self.seen = seen
        self.attendedUsers = attendedUsers
    }
}
