//
//  OrbisChatManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 28/07/2021.
//

import Foundation
import FirebaseFirestore
import CodableFirebase
import Firebase

typealias ChatFetchResponse = (documents: [DocumentSnapshot], messages: OrbisChatMessages)

class OrbisChatManager {
    var conversationRef: CollectionReference! = Firestore.firestore().collection(FirebaseFirestoreNode.conversation.rawValue)
    var chatRef: CollectionReference = Firestore.firestore().collection(FirebaseFirestoreNode.chatMessages.rawValue)
    
    func syncConversationDetail(forId id: String, completion: @escaping responseBlock) {
        let query = conversationRef.document(id)
        query.getDocument(source: .server) { snapshot, err in
            if let error = err {
                completion(nil, error)
            }
            else {
                if let conversationData = snapshot?.data() {
                    do {
                        var conversation = try FirestoreDecoder().decode(OrbisConversation.self, from: conversationData)
                        conversation.id = id
                        completion(conversation, nil)
                    }
                    catch {
                        print("error in mapping conversation data: \(error)")
                        completion(nil, error)
                    }
                }
                else {
                    completion(nil, CommonError.emptyData)
                }
            }
        }
    }
    
    func fetchConversationMessages(inConversation id: String, lastSnapshot: DocumentSnapshot?, limit: Int, completion: @escaping responseBlock) {
        var query = chatRef
            .whereField(OrbisConversationParameterKeys.Conversation.conversationId, isEqualTo: id)
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
                    let messages = listData.compactMap { (snapshot) -> OrbisChatMessage? in
                        do {
                            var message = try FirestoreDecoder().decode(OrbisChatMessage.self, from: snapshot.data())
                            message.id = snapshot.documentID
                            return message
                        }
                        catch {
                            print("error in mapping conversation messages: \(error)")
                            return nil
                        }
                    }
                    completion(ChatFetchResponse(documents: listData, messages: messages), nil)
                }
                else {
                    completion(ChatFetchResponse(documents: [], messages: OrbisChatMessages()), nil)
                }
            }
        }
    }
    
    func fetchChatMessage(withId id: String, completion: @escaping responseBlock) {
        let query = chatRef.document(id)
        query.getDocument { snapshot, err in
            if let error = err {
                completion(nil, error)
            }
            else {
                if let data = snapshot?.data() {
                    do {
                        var chatMessage = try FirestoreDecoder().decode(OrbisChatMessage.self, from: data)
                        chatMessage.id = snapshot?.documentID
                        completion(chatMessage, nil)
                    }
                    catch {
                        print("error in fetching chat message: \(error)")
                        completion(nil, error)
                    }
                }
                else {
                    completion(nil, CommonError.emptyData)
                }
            }
        }
    }
    
    func updateLastMessage(onConversation id: String, withMessage message: OrbisChatMessage) {
        if let lastMessageDict = try? message.toDictionary() {
            let updatedData: [String: Any] = [
                OrbisConversationParameterKeys.Conversation.timestamp: message.timestamp ?? Date().unixTimestamp,
                OrbisConversationParameterKeys.Conversation.lastMessage: lastMessageDict
            ]
            conversationRef.document(id).updateData(updatedData)
        }
    }
    
    func sendTextMessage(message: OrbisChatMessage, completion: @escaping responseBlock) -> String {
        if let dict = try? message.toDictionary() {
            let newDoc = chatRef.document()
            newDoc.setData(dict) { [weak self] err in
                if let error = err {
                    completion(nil, error)
                }
                else {
                    var lastMessage = message
                    lastMessage.id = newDoc.documentID
                    self?.updateLastMessage(onConversation: message.conversationId!, withMessage: lastMessage)
                    self?.fetchChatMessage(withId: newDoc.documentID, completion: completion)
                }
            }
            return newDoc.documentID
        }
        else {
            completion(nil, CommonError.invalidDataFormat)
            return ""
        }
    }
    
}
