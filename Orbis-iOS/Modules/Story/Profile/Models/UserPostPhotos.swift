//
//  UserPostPhotos.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 02/04/2021.
//

import Foundation

typealias UserPostPhotos = [UserPostPhoto]

struct UserPostPhoto {
    var userId: String
    var photoUrl: String
}

enum ProfileMediaSourceType: String {
    case instagram = "INSTAGRAM"
    case orbis = "ORBIS"
    case none
}

enum ProfileMediaMimeType: String {
    case image = "IMAGE"
    case video = "VIDEO"
    case carousel = "CAROUSEL"
}

typealias UserProfileMediaList = [UserProfileMedia]

struct UserProfileMedia: Codable {
    var pictureKey: String?
    var userKey: String?
    var pictureUrl: [String]?
    var type: String?
    var timestamp: String?
    var imageType: String?
    
    var sourceType: ProfileMediaSourceType {
        return ProfileMediaSourceType(rawValue: type ?? "") ?? .none
    }
    
    var mediaType: ProfileMediaMimeType {
        return ProfileMediaMimeType(rawValue: imageType ?? "") ?? .image
    }
    
    var pendingImagesData: [Data]? = nil
}
