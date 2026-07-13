//
//  PostBody.swift
//  Orbis-iOS
//
//  Created by Kamran on 02/11/2024.
//


import Foundation

struct PostBody: Codable {
    var coordinates: Coordinates?
    var checkin: Bool
    var title: String
    var details: String
    var richLinkData: RichLinkDatakeys?
    var mediaUrls: [String]
    var plannedTime: String
    var plannedEndTime: String
    var groupKey: String?
    var placeKey: String?
    var address: String
    var type: String
    var subType: String

    init(
        coordinates: Coordinates? = nil,
        checkin: Bool,
        title: String = "",
        details: String = "",
        richLinkData: RichLinkDatakeys? = nil,
        mediaUrls: [String] = [],
        plannedTime: String = "",
        plannedEndTime: String = "",
        groupKey: String? = nil,
        placeKey: String? = nil,
        address: String = "",
        type: String = "",
        subType: String = ""
    ) {
        self.coordinates = coordinates
        self.checkin = checkin
        self.title = title
        self.details = details
        self.richLinkData = richLinkData
        self.mediaUrls = mediaUrls
        self.plannedTime = plannedTime
        self.plannedEndTime = plannedEndTime
        self.groupKey = groupKey
        self.placeKey = placeKey
        self.address = address
        self.type = type
        self.subType = subType
    }
}

struct RichLinkDatakeys: Codable {
    static let canonicalUrl = "canonicalUrl"
    static let description = "description"
    static let imageUrl = "imageUrl"
    static let originalUrl = "originalUrl"
    static let title = "title"
}
