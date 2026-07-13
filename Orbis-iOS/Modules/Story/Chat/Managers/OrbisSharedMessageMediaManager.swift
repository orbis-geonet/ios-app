//
//  OrbisSharedMessageMediaManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 29/07/2021.
//

import Foundation
import UIKit
import FirebaseStorage
import FirebaseDatabase
import FirebaseFirestore
import CodableFirebase

class OrbisSharedMessageMediaManager {
    static let shared = OrbisSharedMessageMediaManager()
    private let messageManager = OrbisChatManager()
    
    var conversationRef: CollectionReference! = Firestore.firestore().collection(FirebaseFirestoreNode.conversation.rawValue)
    var chatRef: CollectionReference = Firestore.firestore().collection(FirebaseFirestoreNode.chatMessages.rawValue)
    
    let orbisSharedMessageMediaUploadManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    var pendingMessages = OrbisChatMessages()
    
    func invalidateAllRequests(completion: @escaping responseBlock) {
        pendingMessages = []
        orbisSharedMessageMediaUploadManager.invalidateAllSessionRequests(completion: completion)
    }
    
    private func sendMediaMessage(documentId: String?, message: OrbisChatMessage, completion: @escaping responseBlock) -> String {
        if let dict = try? message.toDictionary() {
            let newDoc = (documentId == nil) ? chatRef.document() : chatRef.document(documentId!)
            newDoc.setData(dict) { [weak self] err in
                if let error = err {
                    completion(nil, error)
                }
                else {
                    var lastMessage = message
                    lastMessage.id = newDoc.documentID
                    self?.messageManager.updateLastMessage(onConversation: message.conversationId!, withMessage: lastMessage)
                    self?.messageManager.fetchChatMessage(withId: newDoc.documentID, completion: completion)
                }
            }
            return newDoc.documentID
        }
        else {
            completion(nil, CommonError.invalidDataFormat)
            return ""
        }
    }
    
    func sendImageMessage(message: OrbisChatMessage) -> String {
        guard let imageData = message.pendingImageData else { return ""}
        pendingMessages.append(message)
        var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskId = UIApplication.shared.beginBackgroundTask {
            [weak self ] in
            self?.endBackgroundTask(withId: backgroundTaskId)
        }
        let newDoc = chatRef.document()
        _ = uploadImage(imageData: imageData) { [weak self] data, err in
            if let error = err {
                self?.pendingMessages.removeAll(where: {$0.id == message.id})
                NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Message.pendingMessageMediaUploadFailure), object: (error, message))
                self?.endBackgroundTask(withId: backgroundTaskId)
                return
            }
            else {
                let imageName = data as! String
                var messageToSend = message
                messageToSend.mediaUrl = imageName
                _ = self?.sendMediaMessage(documentId: newDoc.documentID, message: messageToSend, completion: { data, err in
                    if let error = err {
                        self?.deleteAllUploadedImages(inList: [imageName])
                        self?.pendingMessages.removeAll(where: {$0.id == message.id})
                        NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Message.pendingMessageMediaUploadFailure), object: (error, messageToSend))
                        self?.endBackgroundTask(withId: backgroundTaskId)
                        return
                    }
                    else {
                        self?.pendingMessages.removeAll(where: {$0.id == message.id})
                        NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Message.pendingMessageMediaUploadSuccess), object: messageToSend)
                        self?.endBackgroundTask(withId: backgroundTaskId)
                    }
                })
                
            }
        }
        return newDoc.documentID
    }
    
    func sendVideoMessage(message: OrbisChatMessage) -> String {
        guard let videoUrlString = message.pendingVideo else { return "" }
        pendingMessages.append(message)
        var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskId = UIApplication.shared.beginBackgroundTask {
            [weak self ] in
            self?.endBackgroundTask(withId: backgroundTaskId)
        }
        if let url = URL(string: videoUrlString) {
            do {
                let newDoc = chatRef.document()
                let data = try Data(contentsOf: url)
                _ = uploadVideo(data: data) { [weak self] data, err in
                    if let error = err {
                        self?.pendingMessages.removeAll(where: {$0.id == message.id})
                        NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Message.pendingMessageMediaUploadFailure), object: (error, message))
                        self?.endBackgroundTask(withId: backgroundTaskId)
                        return
                    }
                    else {
                        let videoName = data as! String
                        var messageToSend = message
                        messageToSend.mediaUrl = videoName
                        _ = self?.sendMediaMessage(documentId: newDoc.documentID, message: messageToSend, completion: { data, err in
                            if let error = err {
                                self?.deleteAllUploadedVideo(inList: [videoName])
                                self?.pendingMessages.removeAll(where: {$0.id == message.id})
                                NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Message.pendingMessageMediaUploadFailure), object: (error, messageToSend))
                                self?.endBackgroundTask(withId: backgroundTaskId)
                                return
                            }
                            else {
                                self?.pendingMessages.removeAll(where: {$0.id == message.id})
                                NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Message.pendingMessageMediaUploadSuccess), object: messageToSend)
                                self?.endBackgroundTask(withId: backgroundTaskId)
                            }
                        })
                    }
                }
                return newDoc.documentID
            }
            catch {
                debugPrint("Error in url data: \(error.localizedDescription)")
                return ""
            }
        }
        return ""
    }
    
    private func endBackgroundTask(withId id: UIBackgroundTaskIdentifier) {
        if id == .invalid { return }
        UIApplication.shared.endBackgroundTask(id)
    }
    
    private func deleteAllUploadedImages(inList list: [String]) {
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.conversationImages.rawValue)
        for imageName in list {
            let fileRef = storageRef.child(imageName)
            fileRef.delete { err in
                debugPrint("Error in deleting conversation photos \(err?.localizedDescription ?? "")")
            }
        }
    }
    
    private func deleteAllUploadedVideo(inList list: [String]) {
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.conversationVideos.rawValue)
        for videoName in list {
            let fileRef = storageRef.child(videoName)
            fileRef.delete { err in
                debugPrint("Error in deleting conversation video \(err?.localizedDescription ?? "")")
            }
        }
    }
    
    private func cancelAllUploadTasks(in list: [StorageUploadTask]) {
        for task in list {
            task.cancel()
        }
    }
    
    private func uploadImage(imageData: Data, completion: @escaping responseBlock) -> StorageUploadTask {
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.conversationImages.rawValue)
        var imageName = UUID().uuidString
        imageName = imageName + imageData.fileExtension
        let fileRef = storageRef.child(imageName)
        // Create file metadata including the content type
        let metadata = StorageMetadata()
        metadata.contentType = imageData.mimeType
        let uploadTask = fileRef.putData(imageData, metadata: metadata) { metadata, err in
            if let error = err {
                completion(nil, error)
                return
            }
            guard let _ = metadata else {
                completion(nil, ResponseError.invalidData)
                return
            }
            let imageThumbRef = Database.database().reference().child(FirebaseRTDBNode.conversationPhotos.rawValue).child(String(imageName.split(separator: ".").first!))
            self.observeThumbnailGeneration(forRef: imageThumbRef, imageName: imageName, completion: completion)
        }
        return uploadTask
    }
    
    private func observeThumbnailGeneration(forRef ref: DatabaseReference, imageName: String, completion: @escaping responseBlock) {
        ref.observe(.value) { snapshot in
            if let data = snapshot.value, let arrayData = data as? [String: Any] {
                var generatedThumbnails = 0
                for (_, value) in arrayData {
                    if let thumbData = value as? [String: Any], let generatedValue = thumbData["generated"] as? Bool {
                        if generatedValue == true {
                            generatedThumbnails += 1
                        }
                    }
                }
                if generatedThumbnails >= 3 {
                    ref.removeAllObservers()
                    completion(imageName, nil)
                }
            }
        }
    }
    
    private func uploadVideo(data: Data, completion: @escaping responseBlock) -> StorageUploadTask {
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.conversationVideos.rawValue)
        var videoName = UUID().uuidString
        videoName = videoName + data.fileExtension
        let fileRef = storageRef.child(videoName)
        // Create file metadata including the content type
        let metadata = StorageMetadata()
        metadata.contentType = data.mimeType
        let uploadTask = fileRef.putData(data, metadata: metadata) { metadata, err in
            if let error = err {
                completion(nil, error)
                return
            }
            guard let _ = metadata else {
                completion(nil, ResponseError.invalidData)
                return
            }
            completion(videoName, nil)
        }
        return uploadTask
    }
}
