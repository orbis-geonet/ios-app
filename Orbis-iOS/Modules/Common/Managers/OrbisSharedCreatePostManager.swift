//
//  GroupSharedCreatePostManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 05/05/2021.
//

import Foundation
import UIKit
import FirebaseStorage
import FirebaseDatabase

class OrbisSharedCreatePostManager {
    static let shared = OrbisSharedCreatePostManager()
    private let createPostManager = CreatePostManager()
    
    let orbisCreatePostSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    var pendingPosts = OrbisFeedPosts()
    
    func invalidateAllRequests(completion: @escaping responseBlock) {
        pendingPosts = []
        orbisCreatePostSessionManager.invalidateAllSessionRequests(completion: completion)
    }
    
    func createEventPostWithImage(pendingPost: OrbisFeedPost, parameters: [String: Any], url: String, headers: [String: String], completion: @escaping responseBlock) {
        guard let imagesData = pendingPost.pendingPostImagesData else {
            completion(nil, CommonError.invalidDataFormat)
            return
        }
        var imageNames = [String]()
        var uploadTasks = [StorageUploadTask]()
        let group = DispatchGroup()
        var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
        if imagesData.count > 0 {
            backgroundTaskId = UIApplication.shared.beginBackgroundTask {
                [weak self ] in
                self?.endBackgroundTask(withId: backgroundTaskId)
            }
        }
        for imageData in imagesData {
            group.enter()
            let task = uploadEventImage(imageData: imageData) { [weak self] data, err in
                if let error = err {
                    self?.cancelAllUploadTasks(in: uploadTasks)
                    self?.deleteAllUploadedImages(inList: imageNames)
                    completion(nil, error)
                    return
                }
                else {
                    imageNames.append(data as! String)
                }
                group.leave()
            }
            uploadTasks.append(task)
        }
        group.notify(queue: DispatchQueue(label: "EventImageUploadTask", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .inherit)) { [weak self] in
            var postCreateParam = parameters
            postCreateParam[PostParameterKeys.Create.mediaUrls] = imageNames
            debugPrint("Create Event post with image called with parameters: \(postCreateParam)")
            self?.orbisCreatePostSessionManager.processApiRequest(urlLink: url, parameters: postCreateParam, method: .post, headers: headers, isContentJSON: true) { [weak self] data, err in
                self?.endBackgroundTask(withId: backgroundTaskId)
                if let error = err {
                    self?.deleteAllUploadedImages(inList: imageNames)
                    completion(nil, error)
                    return
                }
                else {
                    completion(pendingPost, nil)
                    return
                }
            }
        }
    }
    
    func createImagesPost(pendingPost: OrbisFeedPost, parameters: [String: Any], url: String, headers: [String: String]) {
        guard let imagesData = pendingPost.pendingPostImagesData else { return }
        var imageNames = [String]()
        var uploadTasks = [StorageUploadTask]()
        let group = DispatchGroup()
        pendingPosts.append(pendingPost)
        var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
        if imagesData.count > 0 {
            backgroundTaskId = UIApplication.shared.beginBackgroundTask {
                [weak self ] in
                self?.endBackgroundTask(withId: backgroundTaskId)
            }
        }
        var hasErrorOccured = false
        for imageData in imagesData {
            group.enter()
            let task = uploadImage(imageData: imageData) { [weak self] data, err in
                if let error = err {
                    self?.cancelAllUploadTasks(in: uploadTasks)
                    self?.deleteAllUploadedImages(inList: imageNames)
                    self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                    hasErrorOccured = true
                    NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.PostCreate.pendingPostCreateFailure), object: error)
                }
                else {
                    imageNames.append(data as! String)
                }
                group.leave()
            }
            uploadTasks.append(task)
        }
        group.notify(queue: DispatchQueue(label: "PostImageUploadTask", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .inherit)) { [weak self] in
            guard hasErrorOccured == false else { return }
            var postCreateParam = parameters
            postCreateParam[PostParameterKeys.Create.mediaUrls] = imageNames
            debugPrint("Create Image post called once with parameters: \(postCreateParam)")
            self?.orbisCreatePostSessionManager.processApiRequest(urlLink: url, parameters: postCreateParam, method: .post, headers: headers, isContentJSON: true) { [weak self] data, err in
                self?.endBackgroundTask(withId: backgroundTaskId)
                if let error = err {
                    self?.deleteAllUploadedImages(inList: imageNames)
                    self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                    NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.PostCreate.pendingPostCreateFailure), object: (error, pendingPost))
                }
                else {
                    if let isCheckin = postCreateParam[PostParameterKeys.Create.checkin] as? Bool, isCheckin, let place = pendingPost.place, let placeKey = place.placeKey {
                        CreatePlaceSharedManager.shared.addPlaceIdToNewlyBlockedObserver(placeKey: placeKey)
                    }
                    self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                    if let isCheckin = postCreateParam[PostParameterKeys.Create.checkin] as? Bool, isCheckin, let place = pendingPost.place, let placeKey = place.placeKey, CreatePlaceSharedManager.shared.newlyCreatedListContains(key: placeKey){
                        self?.showMapView(withCheckinPost: pendingPost)
                    }
                    NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.PostCreate.pendingPostCreateSuccess), object: pendingPost)
                }
                self?.endBackgroundTask(withId: backgroundTaskId)
            }
        }
    }
    
    func createAudioPost(audio: OrbisVoice, pendingPost: OrbisFeedPost, parameters: [String: Any], url: String, headers: [String: String]) {
        var audioNames = [String]()
        let group = DispatchGroup()
        pendingPosts.append(pendingPost)
        var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskId = UIApplication.shared.beginBackgroundTask {
            [weak self ] in
            self?.endBackgroundTask(withId: backgroundTaskId)
        }
        group.enter()
        var hasErrorOccured = false
        let _ = uploadAudio(data: audio.data) { [weak self] data, err in
            if let error = err {
                self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.PostCreate.pendingPostCreateFailure), object: error)
                hasErrorOccured = true
            }
            else {
                audioNames.append(data as! String)
            }
            group.leave()
        }
        group.notify(queue: DispatchQueue(label: "PostAudioUploadTask", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .inherit)) { [weak self] in
            guard hasErrorOccured == false else { return }
            var postCreateParam = parameters
            postCreateParam[PostParameterKeys.Create.mediaUrls] = audioNames
            self?.orbisCreatePostSessionManager.processApiRequest(urlLink: url, parameters: postCreateParam, method: .post, headers: headers, isContentJSON: true) { [weak self] data, err in
                self?.endBackgroundTask(withId: backgroundTaskId)
                if let error = err {
                    self?.deleteAllUploadedAudio(inList: audioNames)
                    self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                    NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.PostCreate.pendingPostCreateFailure), object: (error, pendingPost))
                }
                else {
                    if let isCheckin = postCreateParam[PostParameterKeys.Create.checkin] as? Bool, isCheckin, let place = pendingPost.place, let placeKey = place.placeKey {
                        CreatePlaceSharedManager.shared.addPlaceIdToNewlyBlockedObserver(placeKey: placeKey)
                    }
                    self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                    if let isCheckin = postCreateParam[PostParameterKeys.Create.checkin] as? Bool, isCheckin, let place = pendingPost.place, let placeKey = place.placeKey, CreatePlaceSharedManager.shared.newlyCreatedListContains(key: placeKey){
                        self?.showMapView(withCheckinPost: pendingPost)
                    }
                    NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.PostCreate.pendingPostCreateSuccess), object: pendingPost)
                }
                self?.endBackgroundTask(withId: backgroundTaskId)
            }
        }
    }
    
    func createVideoPost(videos: [String], pendingPost: OrbisFeedPost, parameters: [String: Any], url: String, headers: [String: String]) {
        guard let videosDataString = pendingPost.pendingPostVideos else { return }
        var videoNames = [String]()
        var uploadTasks = [StorageUploadTask]()
        let group = DispatchGroup()
        pendingPosts.append(pendingPost)
        var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
        if videosDataString.count > 0 {
            backgroundTaskId = UIApplication.shared.beginBackgroundTask {
                [weak self ] in
                self?.endBackgroundTask(withId: backgroundTaskId)
            }
        }
        var hasErrorOccured = false
        for videoUrlString in videosDataString {
            if let url = URL(string: videoUrlString) {
                do {
                    let data = try Data(contentsOf: url)
                    group.enter()
                    let task = uploadVideo(data: data) { [weak self] data, err in
                        if let error = err {
                            self?.cancelAllUploadTasks(in: uploadTasks)
                            self?.deleteAllUploadedVideo(inList: videoNames)
                            self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                            NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.PostCreate.pendingPostCreateFailure), object: error)
                            hasErrorOccured = true
                        }
                        else {
                            videoNames.append(data as! String)
                        }
                        group.leave()
                    }
                    uploadTasks.append(task)
                }
                catch {
                    debugPrint("Error in url data: \(error.localizedDescription)")
                    continue
                }
            }
        }
        group.notify(queue: DispatchQueue(label: "PostImageUploadTask", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .inherit)) { [weak self] in
            guard hasErrorOccured == false else { return }
            var postCreateParam = parameters
            postCreateParam[PostParameterKeys.Create.mediaUrls] = videoNames
            self?.orbisCreatePostSessionManager.processApiRequest(urlLink: url, parameters: postCreateParam, method: .post, headers: headers, isContentJSON: true) { [weak self] data, err in
                self?.endBackgroundTask(withId: backgroundTaskId)
                if let error = err {
                    self?.deleteAllUploadedVideo(inList: videoNames)
                    self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                    NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.PostCreate.pendingPostCreateFailure), object: (error, pendingPost))
                }
                else {
                    if let isCheckin = postCreateParam[PostParameterKeys.Create.checkin] as? Bool, isCheckin, let place = pendingPost.place, let placeKey = place.placeKey {
                        CreatePlaceSharedManager.shared.addPlaceIdToNewlyBlockedObserver(placeKey: placeKey)
                    }
                    self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                    if let isCheckin = postCreateParam[PostParameterKeys.Create.checkin] as? Bool, isCheckin, let place = pendingPost.place, let placeKey = place.placeKey, CreatePlaceSharedManager.shared.newlyCreatedListContains(key: placeKey){
                        self?.showMapView(withCheckinPost: pendingPost)
                    }
                    NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.PostCreate.pendingPostCreateSuccess), object: pendingPost)
                }
                self?.endBackgroundTask(withId: backgroundTaskId)
            }
        }
    }
    
    func createNormalPost(pendingPost: OrbisFeedPost, parameters: [String: Any], url: String, headers: [String: String]) {
        pendingPosts.append(pendingPost)
        self.orbisCreatePostSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .post, headers: headers, isContentJSON: true) { [weak self] data, err in
            if let error = err {
                self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.PostCreate.pendingPostCreateFailure), object: (error, pendingPost))
            }
            else {
                self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                if let isCheckin = parameters[PostParameterKeys.Create.checkin] as? Bool, isCheckin, let place = pendingPost.place, let placeKey = place.placeKey {
                    CreatePlaceSharedManager.shared.addPlaceIdToNewlyBlockedObserver(placeKey: placeKey)
                }
                if let isCheckin = parameters[PostParameterKeys.Create.checkin] as? Bool, isCheckin, let place = pendingPost.place, let placeKey = place.placeKey, CreatePlaceSharedManager.shared.newlyCreatedListContains(key: placeKey){
                    self?.showMapView(withCheckinPost: pendingPost)
                }
                NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.PostCreate.pendingPostCreateSuccess), object: pendingPost)
            }
        }
    }
    
    func createImagesPost(pendingPost: OrbisFeedPost, parameters: [String: Any], url: String, headers: [String: String], completion: @escaping responseBlock) {
        guard let imagesData = pendingPost.pendingPostImagesData else { return }
        var imageNames = [String]()
        var uploadTasks = [StorageUploadTask]()
        let group = DispatchGroup()
        pendingPosts.append(pendingPost)
        var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
        if imagesData.count > 0 {
            backgroundTaskId = UIApplication.shared.beginBackgroundTask {
                [weak self ] in
                self?.endBackgroundTask(withId: backgroundTaskId)
            }
        }
        var hasErrorOccured = false
        for imageData in imagesData {
            group.enter()
            let task = uploadImage(imageData: imageData) { [weak self] data, err in
                if let _ = err {
                    self?.cancelAllUploadTasks(in: uploadTasks)
                    self?.deleteAllUploadedImages(inList: imageNames)
                    self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                    hasErrorOccured = true
                }
                else {
                    imageNames.append(data as! String)
                }
                group.leave()
            }
            uploadTasks.append(task)
        }
        group.notify(queue: DispatchQueue(label: "PostImageUploadTask", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .inherit)) { [weak self] in
            guard hasErrorOccured == false else {
                completion(nil, CommonError.invalidDataFormat)
                return
            }
            var postCreateParam = parameters
            postCreateParam[PostParameterKeys.Create.mediaUrls] = imageNames
            
            //MARK: Kamran Code for CheckIN
            if (postCreateParam["checkin"] != nil) == true {
                if let mediaUrls = postCreateParam[PostParameterKeys.Create.mediaUrls] as? [String], !mediaUrls.isEmpty {
                    // Do something with mediaUrls, e.g., set a value or perform an operation
                    postCreateParam["subType"] = "IMAGE"
                }
                //IN last we need to set Type
                postCreateParam["type"] = "CHECK_IN"
            }
            
            //MARK: End of Kamran code for CheckIN
            
            debugPrint("Create Image post called once with parameters: \(postCreateParam)")
            self?.createPostManager.createPost(paramters: postCreateParam) {
                [weak self] data, err in
                self?.endBackgroundTask(withId: backgroundTaskId)
                if let error = err {
                    self?.deleteAllUploadedImages(inList: imageNames)
                    self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                    completion(nil, error)
                }
                else {
                    if let isCheckin = postCreateParam[PostParameterKeys.Create.checkin] as? Bool, isCheckin, let place = pendingPost.place, let placeKey = place.placeKey {
                        //MARK: Kamran code for checkIN
                        Constants.lastCheckinPlace = (data as? OrbisFeedPost)?.place?.toPlaceDetails()
                        Constants.lastCheckInPolygonCoordinateKey = (data as? OrbisFeedPost)?.checkInPolygonCoordinateKey
                        Constants.isSelfCheckIn = true
                        //MARK: end of Kamran code for checkIN
                        
                        CreatePlaceSharedManager.shared.addPlaceIdToNewlyBlockedObserver(placeKey: placeKey)
                    }
                    self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                    completion(data, nil)
                }
                self?.endBackgroundTask(withId: backgroundTaskId)
            }
        }
    }
    
    func createAudioPost(audio: OrbisVoice, pendingPost: OrbisFeedPost, parameters: [String: Any], url: String, headers: [String: String], completion: @escaping responseBlock) {
        var audioNames = [String]()
        let group = DispatchGroup()
        pendingPosts.append(pendingPost)
        var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskId = UIApplication.shared.beginBackgroundTask {
            [weak self ] in
            self?.endBackgroundTask(withId: backgroundTaskId)
        }
        group.enter()
        var hasErrorOccured = false
        let _ = uploadAudio(data: audio.data) { [weak self] data, err in
            if let error = err {
                self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                hasErrorOccured = true
                completion(nil, error)
                return
            }
            else {
                audioNames.append(data as! String)
            }
            group.leave()
        }
        group.notify(queue: DispatchQueue(label: "PostAudioUploadTask", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .inherit)) { [weak self] in
            guard hasErrorOccured == false else { return }
            var postCreateParam = parameters
            postCreateParam[PostParameterKeys.Create.mediaUrls] = audioNames
            
            //MARK: Kamran Code for CheckIN
            if (postCreateParam["checkin"] != nil) == true {
                if let mediaUrls = postCreateParam[PostParameterKeys.Create.mediaUrls] as? [String], !mediaUrls.isEmpty {
                    // Do something with mediaUrls, e.g., set a value or perform an operation
                    postCreateParam["subType"] = "AUDIO"
                }
                //IN last we need to set Type
                postCreateParam["type"] = "CHECK_IN"
            }
            
            //MARK: End of Kamran code for CheckIN
            
            self?.createPostManager.createPost(paramters: postCreateParam) {
                [weak self] data, err in
                if let error = err {
                    self?.deleteAllUploadedAudio(inList: audioNames)
                    self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                    completion(nil, error)
                }
                else {
                    if let isCheckin = postCreateParam[PostParameterKeys.Create.checkin] as? Bool, isCheckin, let place = pendingPost.place, let placeKey = place.placeKey {
                        
                        //MARK: Kamran code for checkIN
                        Constants.lastCheckinPlace = (data as? OrbisFeedPost)?.place?.toPlaceDetails()
                        Constants.lastCheckInPolygonCoordinateKey = (data as? OrbisFeedPost)?.checkInPolygonCoordinateKey
                        Constants.isSelfCheckIn = true
                        //MARK: end of Kamran code for checkIN
                        
                        CreatePlaceSharedManager.shared.addPlaceIdToNewlyBlockedObserver(placeKey: placeKey)
                    }
                    self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                    completion(data, nil)
                }
                self?.endBackgroundTask(withId: backgroundTaskId)
            }
        }
    }
    
    func createVideoPost(videos: [String], pendingPost: OrbisFeedPost, parameters: [String: Any], url: String, headers: [String: String], completion: @escaping responseBlock) {
        guard let videosDataString = pendingPost.pendingPostVideos else { return }
        var videoNames = [String]()
        var uploadTasks = [StorageUploadTask]()
        let group = DispatchGroup()
        pendingPosts.append(pendingPost)
        var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
        if videosDataString.count > 0 {
            backgroundTaskId = UIApplication.shared.beginBackgroundTask {
                [weak self ] in
                self?.endBackgroundTask(withId: backgroundTaskId)
            }
        }
        var hasErrorOccured = false
        for videoUrlString in videosDataString {
            if let url = URL(string: videoUrlString) {
                do {
                    let data = try Data(contentsOf: url)
                    group.enter()
                    let task = uploadVideo(data: data) { [weak self] data, err in
                        if let _ = err {
                            self?.cancelAllUploadTasks(in: uploadTasks)
                            self?.deleteAllUploadedVideo(inList: videoNames)
                            self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                            hasErrorOccured = true
                        }
                        else {
                            videoNames.append(data as! String)
                        }
                        group.leave()
                    }
                    uploadTasks.append(task)
                }
                catch {
                    debugPrint("Error in url data: \(error.localizedDescription)")
                    continue
                }
            }
        }
        group.notify(queue: DispatchQueue(label: "PostImageUploadTask", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .inherit)) { [weak self] in
            guard hasErrorOccured == false else {
                completion(nil, CommonError.invalidDataFormat)
                return
            }
            var postCreateParam = parameters
            postCreateParam[PostParameterKeys.Create.mediaUrls] = videoNames
            
            //MARK: Kamran Code for CheckIN
            if (postCreateParam["checkin"] != nil) == true {
                if let mediaUrls = postCreateParam[PostParameterKeys.Create.mediaUrls] as? [String], !mediaUrls.isEmpty {
                    // Do something with mediaUrls, e.g., set a value or perform an operation
                    postCreateParam["subType"] = "VIDEO"
                }
                //IN last we need to set Type
                postCreateParam["type"] = "CHECK_IN"
            }
            
            self?.createPostManager.createPost(paramters: postCreateParam) {
                [weak self] data, err in
                if let error = err {
                    self?.deleteAllUploadedVideo(inList: videoNames)
                    self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                    completion(nil, error)
                }
                else {
                    if let isCheckin = postCreateParam[PostParameterKeys.Create.checkin] as? Bool, isCheckin, let place = pendingPost.place, let placeKey = place.placeKey {
                        
                        //MARK: Kamran code for checkIN
                        Constants.lastCheckinPlace = (data as? OrbisFeedPost)?.place?.toPlaceDetails()
                        Constants.lastCheckInPolygonCoordinateKey = (data as? OrbisFeedPost)?.checkInPolygonCoordinateKey
                        Constants.isSelfCheckIn = true
                        //MARK: end of Kamran code for checkIN
                        
                        CreatePlaceSharedManager.shared.addPlaceIdToNewlyBlockedObserver(placeKey: placeKey)
                    }
                    self?.pendingPosts.removeAll(where: {$0.postKey == pendingPost.postKey})
                    completion(data, nil)
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
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.postImages.rawValue)
        for imageName in list {
            let fileRef = storageRef.child(imageName)
            fileRef.delete { err in
                debugPrint("Error in deleting post image \(err?.localizedDescription ?? "")")
            }
        }
    }
    
    private func deleteAllUploadedAudio(inList list: [String]) {
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.postAudio.rawValue)
        for audioName in list {
            let fileRef = storageRef.child(audioName)
            fileRef.delete { err in
                debugPrint("Error in deleting post audio \(err?.localizedDescription ?? "")")
            }
        }
    }
    
    private func deleteAllUploadedVideo(inList list: [String]) {
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.postVideo.rawValue)
        for videoName in list {
            let fileRef = storageRef.child(videoName)
            fileRef.delete { err in
                debugPrint("Error in deleting post video \(err?.localizedDescription ?? "")")
            }
        }
    }
    
    private func cancelAllUploadTasks(in list: [StorageUploadTask]) {
        for task in list {
            task.cancel()
        }
    }
    
    private func uploadEventImage(imageData: Data, completion: @escaping responseBlock) -> StorageUploadTask {
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.eventImages.rawValue)
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
            let imageThumbRef = Database.database().reference().child(FirebaseRTDBNode.eventImages.rawValue).child(String(imageName.split(separator: ".").first!))
            self.observeThumbnailGeneration(forRef: imageThumbRef, imageName: imageName, completion: completion)
        }
        return uploadTask
    }
    
    private func uploadImage(imageData: Data, completion: @escaping responseBlock) -> StorageUploadTask {
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.postImages.rawValue)
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
            let imageThumbRef = Database.database().reference().child(FirebaseRTDBNode.postImages.rawValue).child(String(imageName.split(separator: ".").first!))
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
    
    private func uploadAudio(data: Data, completion: @escaping responseBlock) -> StorageUploadTask {
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.postAudio.rawValue)
        var audioName = UUID().uuidString
        audioName = audioName + data.fileExtension
        let fileRef = storageRef.child(audioName)
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
            completion(audioName, nil)
        }
        return uploadTask
    }
    
    private func uploadVideo(data: Data, completion: @escaping responseBlock) -> StorageUploadTask {
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.postVideo.rawValue)
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
    
    func showMapView(withCheckinPost post: OrbisFeedPost) {
        guard var place = post.place else { return }
        guard let keyWindow = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first else { return }
        guard let rootNavVC = keyWindow.rootViewController as? UINavigationController else { return }
        place.lastSize = 500
        place.lastCheckInTimestamp = Date().iso8601withFractionalSeconds
        if place.lastSizeChangeTimestamp == nil {
            place.lastSizeChangeTimestamp = place.lastCheckInTimestamp
        }
        place.dominantGroup = post.group
        place.dominantGroupKey = post.group?.groupKey
        place.checkInPolygonCoordinateKey = post.checkInPolygonCoordinateKey
        if let homeVC = rootNavVC.viewControllers.first as? HomeMapViewController {
            rootNavVC.dismiss(animated: false) {
                rootNavVC.popToRootViewController(animated: false)
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
                    homeVC.handlePlaceCheckinSuccess(place: place)
                }
            }
        }
    }
}
