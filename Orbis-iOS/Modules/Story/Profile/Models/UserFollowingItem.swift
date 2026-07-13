//
//  UserFollowingItem.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/07/2021.
//

import Foundation

typealias UserFollowingItems = [UserFollowingItem]

struct UserFollowingItem: Codable {
    var user: OrbisUser?
    var group: Group?
    var place: OrbisPlace?
    var type: String?
    var listType: UserFollowingListType {
        return UserFollowingListType(rawValue: type?.lowercased() ?? "") ?? .user
    }
}
