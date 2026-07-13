//
//  OrbisConversationDomainKeys.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/07/2021.
//

import Foundation

struct OrbisConversationParameterKeys {
    struct Conversation {
        static let timestamp = "timestamp"
        static let lastMessage = "lastMessage"
        static let participants = "participants"
        static let conversationId = "conversationId"
        static let senderId = "senderId"
        static let isRead = "isRead"
    }
}
