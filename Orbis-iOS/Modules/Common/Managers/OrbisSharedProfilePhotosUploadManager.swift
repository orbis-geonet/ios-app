//
//  OrbisSharedProfilePhotosUploadManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 15/07/2021.
//

import Foundation
import UIKit
import FirebaseStorage
import FirebaseDatabase

class OrbisSharedProfilePhotosUploadManager {
    static let shared = OrbisSharedProfilePhotosUploadManager()
    
    let orbisSharedProfilePhotosUploadManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    var pendingPhotosUpload = UserProfileMediaList()
    
    func invalidateAllRequests(completion: @escaping responseBlock) {
        pendingPhotosUpload = []
        orbisSharedProfilePhotosUploadManager.invalidateAllSessionRequests(completion: completion)
    }
    
    func uploadProfileImages(imageMedia: UserProfileMedia, parameters: [String: Any], url: String, headers: [String: String]) {
        guard let imagesData = imageMedia.pendingImagesData else { return }
        var imageNames = [String]()
        var uploadTasks = [StorageUploadTask]()
        let group = DispatchGroup()
        pendingPhotosUpload.append(imageMedia)
        var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
        if imagesData.count > 0 {
            backgroundTaskId = UIApplication.shared.beginBackgroundTask {
                [weak self ] in
                self?.endBackgroundTask(withId: backgroundTaskId)
            }
        }
        for imageData in imagesData {
            group.enter()
            let task = uploadImage(imageData: imageData) { [weak self] data, err in
                if let error = err {
                    self?.cancelAllUploadTasks(in: uploadTasks)
                    self?.deleteAllUploadedImages(inList: imageNames)
                    self?.pendingPhotosUpload.removeAll(where: {$0.pictureKey == imageMedia.pictureKey})
                    NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.UserProfilePhotoUpload.pendingProfileMediaUploadFailure), object: (error, imageMedia))
                    self?.endBackgroundTask(withId: backgroundTaskId)
                    return
                }
                else {
                    imageNames.append(data as! String)
                }
                group.leave()
            }
            uploadTasks.append(task)
        }
        group.notify(queue: DispatchQueue(label: "ProfileMediaUploadTask", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .inherit)) { [weak self] in
            var postCreateParam = parameters
            postCreateParam[UserProfileDomainParameterKeys.ProfileMedia.mediaUrl] = imageNames
            self?.orbisSharedProfilePhotosUploadManager.processApiRequest(urlLink: url, parameters: postCreateParam, method: .post, headers: headers, isContentJSON: true) { [weak self] data, err in
                self?.endBackgroundTask(withId: backgroundTaskId)
                if let error = err {
                    self?.deleteAllUploadedImages(inList: imageNames)
                    self?.pendingPhotosUpload.removeAll(where: {$0.pictureKey == imageMedia.pictureKey})
                    NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.UserProfilePhotoUpload.pendingProfileMediaUploadFailure), object: (error, imageMedia))
                }
                else {
                    self?.pendingPhotosUpload.removeAll(where: {$0.pictureKey == imageMedia.pictureKey})
                    NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.UserProfilePhotoUpload.pendingProfileMediaUploadSuccess), object: imageMedia)
                }
                self?.endBackgroundTask(withId: backgroundTaskId)
            }
        }
    }
    
    private func endBackgroundTask(withId id: UIBackgroundTaskIdentifier) {
        if id == .invalid { return }
        UIApplication.shared.endBackgroundTask(id)
    }
    
    private func deleteAllUploadedImages(inList list: [String]) {
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.userProfilePhotos.rawValue)
        for imageName in list {
            let fileRef = storageRef.child(imageName)
            fileRef.delete { err in
                debugPrint("Error in deleting profile photos \(err?.localizedDescription ?? "")")
            }
        }
    }
    
    private func deleteAllUploadedVideo(inList list: [String]) {
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.userProfileVideos.rawValue)
        for videoName in list {
            let fileRef = storageRef.child(videoName)
            fileRef.delete { err in
                debugPrint("Error in deleting profile video \(err?.localizedDescription ?? "")")
            }
        }
    }
    
    private func cancelAllUploadTasks(in list: [StorageUploadTask]) {
        for task in list {
            task.cancel()
        }
    }
    
    private func uploadImage(imageData: Data, completion: @escaping responseBlock) -> StorageUploadTask {
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.userProfilePhotos.rawValue)
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
            let imageThumbRef = Database.database().reference().child(FirebaseRTDBNode.userProfilePersonalPictures.rawValue).child(String(imageName.split(separator: ".").first!))
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
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.userProfileVideos.rawValue)
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
