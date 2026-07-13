//
//  ChatMessageViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 20/04/2021.
//

import Foundation

class ChatMessageViewModel {
    var message: OrbisChatMessage!
    var shouldShowDay: Bool!
    
    init(message: OrbisChatMessage, shouldShowDay: Bool) {
        self.message = message
        self.shouldShowDay = shouldShowDay
    }
    
    var messageContent: String {
        return message.message ?? ""
    }
    
    var dateString: String {
        return message.timestamp?.epochToChatDateString() ?? ""
    }
    
    var timeString: String {
        return message.timestamp?.epochToChatTimeString() ?? ""
    }
    
    var mediaUrl: String {
        return message.mediaUrl ?? ""
    }
    
    var pendingImageData: Data? {
        return message.pendingImageData
    }
    
    var isPendingMessage: Bool {
        return message.isPending
    }
    
    var pendingVideo: String {
        return message.pendingVideo ?? ""
    }
    
    func fetchMediaUrl(forName name: String, completion: @escaping responseBlock) {
        let ref = name.getFirebaseFileStorageReference(storage: .conversationVideos)
        if let url = OrbisVideoCacheManager.shared.getUrl(forUrl: ref.fullPath) {
            completion(url, nil)
            return
        }
        else {
            ref.downloadURL {  url, err in
                if let videoUrl = url {
                    OrbisVideoCacheManager.shared.addUrl(forUrl: ref.fullPath, url: videoUrl.absoluteString)
                    completion(videoUrl.absoluteString, nil)
                    return
                }
                else {
                    completion(nil, err ?? ResponseError.invalidData)
                    return
                }
            }
        }
    }
}
