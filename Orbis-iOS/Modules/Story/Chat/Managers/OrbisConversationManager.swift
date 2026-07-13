//
//  OrbisConversationManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/07/2021.
//

import Foundation
import FirebaseFirestore
import CodableFirebase
import Firebase

typealias ConversationListResponse = (documents: [DocumentSnapshot], conversations: OrbisConversationList)

class OrbisConversationManager {
    var conversationRef: CollectionReference! = Firestore.firestore().collection(FirebaseFirestoreNode.conversation.rawValue)
    var chatRef: CollectionReference = Firestore.firestore().collection(FirebaseFirestoreNode.chatMessages.rawValue)
    
    func fetchUnreadMessagesCount(completion: @escaping responseBlock) {
        guard let selfUser = UserSessionManager.shared.currentUser else {
            completion(0, nil)
            return
        }
        let query = conversationRef
            .whereField(OrbisConversationParameterKeys.Conversation.participants, arrayContains: selfUser.userKey!)
            .whereField("lastMessage.isRead", isEqualTo: false)
            .whereField("lastMessage.senderId", isNotEqualTo: selfUser.userKey!)
        query.getDocuments(source: .server) { snapshot, err in
            if let error = err {
                completion(nil, error)
            }
            else {
                completion(snapshot?.documents.count ?? 0, nil)
            }
        }
    }
    
    func fetchUserConversationList(forUser userKey: String, lastSnapshot: DocumentSnapshot?, limit: Int, completion: @escaping responseBlock) {
        guard let selfUser = UserSessionManager.shared.currentUser else {
            completion(nil, CommonError.invalidUser)
            return
        }
        var query = conversationRef
            .whereField(OrbisConversationParameterKeys.Conversation.participants, arrayContains: userKey)
            .whereField(OrbisConversationParameterKeys.Conversation.lastMessage, isNotEqualTo: NSNull())
            .order(by: OrbisConversationParameterKeys.Conversation.lastMessage)
            .order(by: OrbisConversationParameterKeys.Conversation.timestamp, descending: true)
        if let lastSnapshot = lastSnapshot {
            query = query.start(afterDocument: lastSnapshot)
        }
        query = query.limit(to: limit)
        query.getDocuments(source: .server) { snapshot, err in
            if let error = err {
                completion(nil, error)
            }
            else {
                if let listData = snapshot?.documents {
                    var conversations = listData.compactMap { (snapshot) -> OrbisConversation? in
                        do {
                            var conversation = try FirestoreDecoder().decode(OrbisConversation.self, from: snapshot.data())
                            conversation.id = snapshot.documentID
                            return conversation
                        }
                        catch {
                            print("error in mapping conversation: \(error)")
                            return nil
                        }
                    }
                    let group = DispatchGroup()
                    let userManager = UserProfileManager()
                    for conversation in conversations {
                        var updatedConvo = conversation
                        group.enter()
                        if let particpantId = conversation.participants?.first(where: {$0 != userKey}) {
                            userManager.getChatUserDetail(forKey: particpantId) { data, err in
                                if let user = data as? OrbisUser, user.blocked != true {
                                    updatedConvo.updateParticipantUsers(users: [selfUser, user])
                                }
                                else {
                                    updatedConvo.updateParticipantUsers(users: [selfUser, OrbisUser(key: UUID().uuidString, name: "Orbis User", proPicLink: nil)])
                                    updatedConvo.isValidParticipant = false
                                    print("Error in fetching profile")
                                }
                                if conversations.contains(where: {$0.id == updatedConvo.id}) {
                                    conversations.removeAll(where: {$0.id == updatedConvo.id})
                                    conversations.append(updatedConvo)
                                    conversations.sort(by: {$0.timestamp! > $1.timestamp!})
                                }
                                else {
                                    conversations.append(updatedConvo)
                                    conversations.sort(by: {$0.timestamp! > $1.timestamp!})
                                }
                                group.leave()
                            }
                        }
                        else {
                            if conversations.contains(where: {$0.id == updatedConvo.id}) {
                                conversations.removeAll(where: {$0.id == updatedConvo.id})
                                conversations.append(updatedConvo)
                                conversations.sort(by: {$0.timestamp! > $1.timestamp!})
                            }
                            else {
                                conversations.append(updatedConvo)
                                conversations.sort(by: {$0.timestamp! > $1.timestamp!})
                            }
                            group.leave()
                        }
                    }
                    group.notify(queue: .main) {
                        completion(ConversationListResponse(documents: listData, conversations: conversations), nil)
                    }
                }
                else {
                    completion(ConversationListResponse(documents: [], conversations: OrbisConversationList()), nil)
                }
            }
        }
    }
    
    func checkIfConversationExists(forUser selfKey: String, withUser participantKey: String, completion: @escaping responseBlock) {
        let query = conversationRef
            .whereField(OrbisConversationParameterKeys.Conversation.participants, arrayContains: selfKey)
        query.getDocuments(source: .server) { snapshot, err in
            if let error = err {
                completion(nil, error)
            }
            else {
                if let data = snapshot?.documents {
                    let conversations = data.compactMap { (snapshot) -> OrbisConversation? in
                        do {
                            var conversation = try FirestoreDecoder().decode(OrbisConversation.self, from: snapshot.data())
                            conversation.id = snapshot.documentID
                            return conversation
                        }
                        catch {
                            print("error in mapping conversation: \(error)")
                            return nil
                        }
                    }
                    let consists = conversations.contains(where: {$0.participants?.contains(participantKey) ?? false})
                    completion(consists, nil)
                }
                else {
                    completion(false, nil)
                }
            }
        }
    }
    
    func getConversation(ofUser key: String, withUser participantKey: String, completion: @escaping responseBlock) {
        guard let selfUser = UserSessionManager.shared.currentUser else {
            completion(nil, CommonError.invalidUser)
            return
        }
        let query = conversationRef
            .whereField(OrbisConversationParameterKeys.Conversation.participants, arrayContains: key)
        query.getDocuments(source: .server) { snapshot, err in
            if let error = err {
                completion(nil, error)
            }
            else {
                if let data = snapshot?.documents {
                    let conversations = data.compactMap { (snapshot) -> OrbisConversation? in
                        do {
                            var conversation = try FirestoreDecoder().decode(OrbisConversation.self, from: snapshot.data())
                            conversation.id = snapshot.documentID
                            return conversation
                        }
                        catch {
                            print("error in mapping conversation: \(error)")
                            return nil
                        }
                    }
                    var userConversation = conversations.filter({$0.participants?.contains(participantKey) ?? false}).first
                    if let particpantId = userConversation?.participants?.first(where: {$0 != key}) {
                        let userManager = UserProfileManager()
                        userManager.syncProfileDetail(forUser: particpantId) { data, err in
                            if let user = data as? OrbisUser, user.blocked != true {
                                userConversation?.updateParticipantUsers(users: [selfUser, user])
                            }
                            else {
                                userConversation?.updateParticipantUsers(users: [selfUser, OrbisUser(key: UUID().uuidString, name: "Orbis User", proPicLink: nil)])
                                userConversation?.isValidParticipant = false
                                print("Error in fetching profile")
                            }
                            completion(userConversation, nil)
                        }
                    }
                    else {
                        completion(userConversation, nil)
                    }
                }
                else {
                    completion(nil, nil)
                }
            }
        }
    }
    
    func createConversation(ofUser user: OrbisUser, withUser participant: OrbisUser, completion: @escaping responseBlock) {
        getConversation(ofUser: user.userKey!, withUser: participant.userKey!) { [weak self] data, err in
            guard let self = self else { return }
            if let error = err {
                completion(nil, error)
            }
            else if let convo = data as? OrbisConversation {
                completion(convo, nil)
            }
            else {
                // create
//                let convoUser = OrbisUser(key: user.userKey, name: user.name, proPicLink: user.imageName)
//                let participantUser = OrbisUser(key: participant.userKey, name: participant.name, proPicLink: participant.imageName)
                let convo = OrbisConversation(id: nil, timestamp: Date().unixTimestamp, lastMessage: nil, participants: [user.userKey!, participant.userKey!], participantUsers: nil)
                if let dict = try? convo.toDictionary() {
                    self.conversationRef.addDocument(data: dict) { [weak self] err2 in
                        if let error2 = err2 {
                            completion(nil, error2)
                        }
                        else {
                            self?.getConversation(ofUser: user.userKey!, withUser: participant.userKey!, completion: completion)
                        }
                    }
                }
                else {
                    completion(nil, CommonError.invalidDataFormat)
                }
                
            }
        }
    }
    
    func fetchConversation(withId id: String, completion: @escaping responseBlock) {
        let query = conversationRef.document(id)
        query.getDocument { snapshot, err in
            if let error = err {
                completion(nil, error)
            }
            else {
                if let data = snapshot?.data() {
                    do {
                        var conversation = try FirestoreDecoder().decode(OrbisConversation.self, from: data)
                        conversation.id = snapshot?.documentID
                        completion(conversation, nil)
                    }
                    catch {
                        print("error in fetching conversation: \(error)")
                        completion(nil, error)
                    }
                }
                else {
                    completion(nil, CommonError.emptyData)
                }
            }
        }
    }
    
    
}
