//
//  UserProfileDomainKeys.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 08/07/2021.
//

import Foundation

enum UserFollowingListType: String {
    case user
    case place
    case group
}

struct UserProfileDomainParameterKeys {
    struct Update {
        static let imageName = "imageName"
        static let accountPrivate = "accountPrivate"
        static let name = "displayName"
        static let dob = "dateOfBirth"
        static let gender = "gender"
        static let password = "password"
        static let language = "language"
    }
    struct Fetch {
        static let page = "page"
        static let size = "size"
    }
    struct Search {
        static let page = "page"
        static let limit = "size"
        static let name = "name"
        static let type = "type"
    }
    struct ProfileMedia {
        static let mediaUrl = "pictureUrl"
    }
    struct ChangePassword {
        static let email = "email"
        static let oldPass = "oldPassword"
        static let newPass = "newPassword"
    }
}
