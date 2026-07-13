//
//  VideoPostCellViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 31/05/2021.
//

import Foundation
import UIKit
import FirebaseStorage

class VideoPostCellViewModel: PostCellViewModel {
    var description: String {
        return model.details ?? ""
    }
    
    var mediaUrls: [String] {
        return model.signedUrls ?? []
    }
    
    var videoName: String {
        return model.mediaUrls?.first ?? ""
    }
    
    var videoThumbnailLink: StorageReference? {
        guard !videoName.isEmpty else {
            return nil
        }
        let nameWithoutExt = String(videoName.split(separator: ".").first ?? "")
        return nameWithoutExt.getFirebaseReference(storage: .postVideo, imageSizeResolution: .fourHundred)
    }
    
    var pendingVideos: [String] {
        return model.pendingPostVideos ?? []
    }
    
    var imageCount: Int {
        return isPendingPost ? pendingVideos.count : mediaUrls.count
    }
    
    func getPendingVideoLink(at index: Int) -> String {
        return pendingVideos[index]
    }
    
    func getImageLink(at index: Int) -> String {
        return mediaUrls[index]
    }
    
    func fetchMediaUrl(forName name: String, completion: @escaping responseBlock) {
        guard name.isNotUrlLink else {
            completion(name, nil)
            return
        }
        let ref = name.getFirebaseFileStorageReference(storage: .postVideo)
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
