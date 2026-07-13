//
//  OrbisMessage.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 20/04/2021.
//

import Foundation

struct UserOnlineActivity: Decodable {
    var lastActive: Double?
}

enum OrbisMessageType: String {
    case text = "TEXT"
    case image = "IMAGE"
    case video = "VIDEO"
}

typealias OrbisConversationList = [OrbisConversation]

struct OrbisConversation: Codable {
    var id: String?
    var timestamp: Double?
    var lastMessage: OrbisChatMessage?
    var participants: [String]?
    var participantUsers: OrbisUsers?
    var isValidParticipant = true
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case lastMessage
        case participants
    }
    
    var participantKey: String? {
        guard let selfUserKey = UserSessionManager.shared.currentUser?.userKey else { return nil }
        return participants?.first(where: {$0 != selfUserKey})
    }
    
    mutating func updateParticipantUsers(users: OrbisUsers?) {
        self.participantUsers = users
    }
}

typealias OrbisChatMessages = [OrbisChatMessage]

struct OrbisChatMessage: Codable {
    var id: String?
    var message: String?
    var timestamp: Double?
    var isRead: Bool?
    var senderId: String?
    var mediaUrl: String?
    var type: String?
    var conversationId: String?
    
    var isReceived: Bool {
        return senderId != UserSessionManager.shared.currentUser?.userKey
    }
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case message
        case isRead
        case senderId
        case mediaUrl
        case type
        case conversationId
    }
    
    var messageType: OrbisMessageType {
        return OrbisMessageType(rawValue: type ?? "") ?? .text
    }
    
    var pendingImageData: Data? = nil
    var pendingVideo: String? = nil
    
    var isPending: Bool {
        return pendingImageData != nil || pendingVideo != nil
    }
}
