//
//  CreateGroupManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 28/04/2021.
//

import Foundation
import FirebaseStorage
import SDWebImage
import FirebaseDatabase

class CreateGroupManager {
    
    func createGroup(param: [String: Any], completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.fetchCreate, []).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: param, method: .post, headers: headers, isContentJSON: true) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, ResponseError.invalidData)
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let group = try decoder.decode(Group.self, from: respData)
                    completion(group, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func editGroup(key: String, param: [String: Any], completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.fetchDetails, [key]).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: param, method: .put, headers: headers, isContentJSON: true) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, ResponseError.invalidData)
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let group = try decoder.decode(Group.self, from: respData)
                    completion(group, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func uploadGroupImage(withName name: String, image: UIImage, completion: @escaping responseBlock) {
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.groupPictures.rawValue)
        let imageData = image.sd_imageData()!
        let imageName = name + imageData.fileExtension
        let fileRef = storageRef.child(imageName)
        // Create file metadata including the content type
        let metadata = StorageMetadata()
        metadata.contentType = imageData.mimeType
        let _ = fileRef.putData(imageData, metadata: metadata) { metadata, err in
            if let error = err {
                completion(nil, error)
                return
            }
            guard let _ = metadata else {
                completion(nil, ResponseError.invalidData)
                return
            }
            let imageThumbRef = Database.database().reference().child(FirebaseRTDBNode.groupProPics.rawValue).child(String(imageName.split(separator: ".").first!))
            self.observeThumbnailGeneration(forRef: imageThumbRef, imageName: imageName, completion: completion)
        }
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
}
