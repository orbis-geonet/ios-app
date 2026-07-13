//
//  ConversationViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 20/04/2021.
//

import Foundation
import FirebaseFirestore
import CodableFirebase

class ConversationViewModel {
    var chatRef: CollectionReference = Firestore.firestore().collection(FirebaseFirestoreNode.chatMessages.rawValue)
    var userActivityRef: CollectionReference = Firestore.firestore().collection(FirebaseFirestoreNode.userActivity.rawValue)
    let manager = OrbisChatManager()
    var selfUser: OrbisUser! {
        return UserSessionManager.shared.currentUser!
    }
    var participant: OrbisUser? {
        return model.participantUsers?.first(where: {$0.userKey != selfUser.userKey})
    }
    var model: OrbisConversation!
    
    var chatMessages: OrbisChatMessages = []
    var hasItemsLastPageReached = false
    var lastSnapshot: DocumentSnapshot?
    private let offsetVal: Int = 10
    var newMessagesListener: ListenerRegistration?
    var userActivityListener: ListenerRegistration?
    
    var onChatFetched: ((Bool) -> Void)?
    var onChatFetchedCompletePagination: (() -> Void)?
    var onChatFetchError: ((Error) -> Void)?
    var onNewMessageObserved: ((Int) -> Void)?
    var onMessageUpdateObserved: ((Int) -> Void)?
    
    var onConversationSynched: (() -> Void)?
    var onLastActiveStatusUpdate: ((String) -> Void)?
    
//    var hasInitialNewMessagesObserved = false
    var hasObserveBeenCalled = false
    var userLastActivityDate: Date?
    var userLastActivityDateString: String {
        return userLastActivityDate?.timeAgoSinceNow(activeString: AppStrings.Messaging.activeNow, prefix: "\(AppStrings.Messaging.online) ") ?? ""
    }
    
    init(conversation: OrbisConversation) {
        self.model = conversation
        initializePagination()
    }
    
    deinit {
        newMessagesListener?.remove()
        userActivityListener?.remove()
    }
    
    var count: Int {
        return chatMessages.count
    }
    
    func getMessage(at index: Int) -> OrbisChatMessage {
        return chatMessages[index]
    }
    
    var participantName: String {
        return participant?.userDisplayName ?? AppStrings.orbisUser
    }
    
    var participantPropicLink: String {
        return participant?.proPicLink ?? ""
    }
    
    func initializePagination() {
        chatMessages = []
        hasItemsLastPageReached = false
        lastSnapshot = nil
    }
    
    func syncConversationInfo() {
        guard let selfUser = UserSessionManager.shared.currentUser else { return }
        manager.syncConversationDetail(forId: model.id!) { [weak self] data, err in
            if let error = err {
                debugPrint("Error in conversation sync \(error.localizedDescription)")
                self?.onConversationSynched?()
            }
            else if var objc = data as? OrbisConversation {
                if let participantKey = objc.participantKey {
                    UserProfileManager().getChatUserDetail(forKey: participantKey) { data, err in
                        if let user = data as? OrbisUser, user.blocked != true {
                            objc.updateParticipantUsers(users: [selfUser, user])
                        }
                        else {
                            objc.updateParticipantUsers(users: [selfUser, OrbisUser(key: UUID().uuidString, name: "Orbis User", proPicLink: nil)])
                            objc.isValidParticipant = false
                            print("Error in fetching profile")
                        }
                        self?.model = objc
                        self?.onConversationSynched?()
                    }
                }
                else {
                    objc.updateParticipantUsers(users: [selfUser, OrbisUser(key: UUID().uuidString, name: "Orbis User", proPicLink: nil)])
                    self?.model = objc
                    self?.onConversationSynched?()
                }
            }
            self?.observeUserActivity()
        }
    }
    
    func fetchMessages() {
        initializePagination()
        manager.fetchConversationMessages(inConversation: model.id!, lastSnapshot: lastSnapshot, limit: offsetVal) { [ weak self] data, err in
            guard let self = self else { return }
            if let error = err {
                self.onChatFetchError?(error)
                return
            }
            if let items = data as? ChatFetchResponse {
                if items.messages.count > 0 {
                    self.chatMessages = items.messages.reversed() + OrbisSharedMessageMediaManager.shared.pendingMessages.filter({$0.conversationId == self.model.id})
                    self.lastSnapshot = items.documents.last
                    self.hasItemsLastPageReached = false
                    self.onChatFetched?(true)
                }
                else {
                    self.hasItemsLastPageReached = true
                    self.onChatFetchedCompletePagination?()
                }
                if !self.hasObserveBeenCalled {
                    self.hasObserveBeenCalled = true
                    self.observeNewMessages()
                }
            }
            else {
                self.onChatFetchError?(ResponseError.invalidData)
            }
        }
    }
    
    func fetchMoreMessages() {
        manager.fetchConversationMessages(inConversation: model.id!, lastSnapshot: lastSnapshot, limit: offsetVal) { [ weak self] data, err in
            guard let self = self else { return }
            if let error = err {
                self.onChatFetchError?(error)
                return
            }
            if let items = data as? ChatFetchResponse {
                if items.messages.count > 0 {
                    items.messages.forEach { message in
                        if let index = self.chatMessages.firstIndex(where: {$0.id == message.id}) {
                            self.chatMessages[index] = message
                        }
                        else {
                            self.chatMessages.insert(message, at: 0)
                        }
                    }
                    self.lastSnapshot = items.documents.last
                    self.hasItemsLastPageReached = false
                    self.onChatFetched?(false)
                }
                else {
                    self.hasItemsLastPageReached = true
                    self.onChatFetchedCompletePagination?()
                }
            }
            else {
                self.onChatFetchError?(ResponseError.invalidData)
            }
        }
    }
    
    private func observeNewMessages() {
        newMessagesListener = self.chatRef.whereField(OrbisConversationParameterKeys.Conversation.conversationId, isEqualTo: model.id!).addSnapshotListener { [weak self] snapshotsData, err in
            if let snapshot = snapshotsData, !snapshot.metadata.isFromCache {
//                if self?.hasInitialNewMessagesObserved == false {
//                    self?.hasInitialNewMessagesObserved = true
//                }
//                else {
//                    snapshot.documentChanges.forEach { [weak self] change in
//                        self?.handleChatMessageDocumentChanges(change: change)
//                    }
//                }
                snapshot.documentChanges.forEach { [weak self] change in
                    self?.handleChatMessageDocumentChanges(change: change)
                }
            }
        }
    }
    
    private func handleChatMessageDocumentChanges(change: DocumentChange) {
        switch change.type {
        case .added:
            let document = change.document
            guard var message = try? FirestoreDecoder().decode(OrbisChatMessage.self, from: document.data()) else { return }
            guard message.conversationId == model.id else { return }
            guard !self.chatMessages.contains(where: {$0.id == document.documentID}) else {
                let index = self.chatMessages.firstIndex(where: {$0.id == document.documentID})!
                self.chatMessages[index].mediaUrl = message.mediaUrl
                self.chatMessages[index].timestamp = message.timestamp
                self.onMessageUpdateObserved?(index)
                return
            }
            message.id = document.documentID
            self.chatMessages.append(message)
            self.onNewMessageObserved?(self.chatMessages.lastIndex(where: {$0.id == message.id})!)
        default:
            return
        }
    }
    
    private func observeUserActivity() {
        guard let participantKey = self.participant?.userKey else { return }
        userActivityListener = self.userActivityRef.document(participantKey).addSnapshotListener { [weak self] snapshotsData, err in
            if let snapshot = snapshotsData, let snapshotData = snapshot.data() {
                guard let userActivity = try? FirestoreDecoder().decode(UserOnlineActivity.self, from: snapshotData) else { return }
                guard let lastActiveValue = userActivity.lastActive else { return }
                let activeDate = Date(timeIntervalSince1970: lastActiveValue/1000)
                let userLastActiveText = activeDate.timeAgoSinceNow(activeString: "Active now", prefix: "Online ")
                self?.userLastActivityDate = activeDate
                self?.onLastActiveStatusUpdate?(userLastActiveText)
            }
        }
    }
    
    func markAllMessagesAsRead() {
        guard let participants = model.participants, let memberId = participants.first(where: {$0 != selfUser.userKey}) else { return }
        let ref = chatRef
            .whereField(OrbisConversationParameterKeys.Conversation.conversationId, isEqualTo: model.id!)
            .whereField(OrbisConversationParameterKeys.Conversation.isRead, isEqualTo: false)
            .whereField(OrbisConversationParameterKeys.Conversation.senderId, isEqualTo: memberId)
        ref.getDocuments(source: .server) { snapshotData, err in
            if let snapshot = snapshotData {
                snapshot.documents.forEach { [weak self] document in
                    guard let self = self else { return }
                    self.chatRef.document(document.documentID).updateData([OrbisConversationParameterKeys.Conversation.isRead: true])
                }
            }
        }
        manager.conversationRef.document(model.id!).getDocument { [weak self] snapshotData, err in
            guard let self = self else { return }
            if let snapshot = snapshotData?.data(), let convo = try? FirebaseDecoder().decode(OrbisConversation.self, from: snapshot), var lastMessageDict = try? convo.lastMessage?.toDictionary() {
                lastMessageDict[OrbisConversationParameterKeys.Conversation.isRead] = true
                self.manager.conversationRef.document(self.model.id!).updateData([OrbisConversationParameterKeys.Conversation.lastMessage: lastMessageDict])
            }
        }
        
    }
    
    func sendMessage(text: String, completion: @escaping responseBlock) {
        var msgObject = OrbisChatMessage(id: nil, message: text, timestamp: Date().unixTimestamp, isRead: false, senderId: selfUser.userKey, mediaUrl: nil, type: OrbisMessageType.text.rawValue, conversationId: model.id!)
        let id = manager.sendTextMessage(message: msgObject) { data, err in
        }
        msgObject.id = id
        chatMessages.append(msgObject)
        completion(true, nil)
    }
    
    func sendImageMessage(data: Data, completion: @escaping responseBlock) {
        var msgObject = OrbisChatMessage(id: UUID().uuidString, message: "", timestamp: Date().unixTimestamp, isRead: false, senderId: selfUser.userKey, mediaUrl: nil, type: OrbisMessageType.image.rawValue, conversationId: model.id!)
        msgObject.pendingImageData = data
        let id = OrbisSharedMessageMediaManager.shared.sendImageMessage(message: msgObject)
        msgObject.id = id
        chatMessages.append(msgObject)
        completion(true, nil)
    }
    
    func sendVideoMessage(videoPath: String, completion: @escaping responseBlock) {
        var msgObject = OrbisChatMessage(id: UUID().uuidString, message: "", timestamp: Date().unixTimestamp, isRead: false, senderId: selfUser.userKey, mediaUrl: nil, type: OrbisMessageType.video.rawValue, conversationId: model.id!)
        msgObject.pendingVideo = videoPath
        let id = OrbisSharedMessageMediaManager.shared.sendVideoMessage(message: msgObject)
        msgObject.id = id
        chatMessages.append(msgObject)
        completion(true, nil)
    }
}
