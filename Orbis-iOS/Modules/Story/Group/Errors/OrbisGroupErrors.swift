//
//  OrbisGroupErrors.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 30/04/2021.
//

import Foundation

enum OrbisGroupError: Error {
    case alreadyJoined
    case notAMember
    case alreadyFollowed
    case notFollowed
    case notAuthorized
    case alreadyUnhidden
}

extension OrbisGroupError:CustomStringConvertible {
    var description: String{
        switch self {
        case .alreadyJoined:
            return "You have already joined this group".localized
        case .notAMember:
            return "You are not a member of this group".localized
        case .alreadyFollowed:
            return "You have already followed this group".localized
        case .notFollowed:
            return "You have not followed this group yet".localized
        case .notAuthorized:
            return "You are not authorized to perform this action".localized
        case .alreadyUnhidden:
            return "Group stories are already unhidden".localized
        }
    }
}
