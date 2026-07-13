//
//  MessageListItemViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 20/04/2021.
//

import Foundation

class ConversationListItemViewModel {
    var conversation: OrbisConversation!
    var selfUser: OrbisUser {
        return UserSessionManager.shared.currentUser!
    }
    
    init(conversation: OrbisConversation) {
        self.conversation = conversation
    }
    
    private var isSenderSelf: Bool {
        return conversation.lastMessage?.senderId == selfUser.userKey
    }
    
    var isRead: Bool {
        if isSenderSelf {
            return true
        }
        return conversation.lastMessage?.isRead ?? false
    }
    
    var messageContent: String {
        guard let lastMessage = conversation.lastMessage else {
            return ""
        }
        switch lastMessage.messageType {
        case .text:
            return lastMessage.message ?? ""
        case .image:
            return (isSenderSelf ? "\(AppStrings.Messaging.you)" : "\(userName)") + " \(AppStrings.Messaging.sentImage)"
        case .video:
            return (isSenderSelf ? "\(AppStrings.Messaging.you)" : "\(userName)") + " \(AppStrings.Messaging.sendVideo)"
        }
    }
    
    var userName: String {
        return conversation.participantUsers?.first(where: {$0.userKey != selfUser.userKey})?.userDisplayName ?? AppStrings.orbisUser
    }
    
    var userPropicLink: String {
        return conversation.participantUsers?.first(where: {$0.userKey != selfUser.userKey})?.proPicLink ?? ""
    }
}
