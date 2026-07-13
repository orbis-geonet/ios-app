//
//  UserProfileManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 06/07/2021.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage

typealias UserSearchResult = (users: OrbisUsers, searchText: String)

class UserProfileManager {
    let profileFeedSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    let profileInstaPictureSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    let profileAppPictureSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    
    func invalidateInstaPicturesFetchSession(completion: @escaping responseBlock) {
        profileInstaPictureSessionManager.invalidateAllSessionRequests(completion: completion)
    }
    
    func invalidateAppPicturesFetchSession(completion: @escaping responseBlock) {
        profileAppPictureSessionManager.invalidateAllSessionRequests(completion: completion)
    }
    
    func getChatUserDetail(forKey key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.chatUserDetail, []).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [networkRequestArrayParametersKey: [key]], method: .post, headers: headers, isContentArrayJSON: true) { (data, err) in
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
                    let users = try decoder.decode(OrbisUsers.self, from: respData)
                    completion(users.first, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func syncProfileDetail(forUser key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.detail, [key]).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .get, headers: headers) { (data, err) in
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
                    let user = try decoder.decode(OrbisUser.self, from: respData)
                    completion(user, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func checkInstagramLinkStatus(completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.instagramConnect, []).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .post, headers: headers) { (data, err) in
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
                    let userStatus = try decoder.decode(OrbisUserInstaConnectResponse.self, from: respData)
                    if let user = UserSessionManager.shared.currentUser {
                        user.hasConnectedInstagram = userStatus.connectedStatus == .connected
                        UserSessionManager.shared.saveUpdatedUserData(user: user) {_,_ in
                            completion(userStatus, nil)
                        }
                    }
                    else {
                        completion(userStatus, nil)
                    }
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func disconnectInstagram(completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.deauthorizeInsta, []).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .post, headers: headers) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                if let user = UserSessionManager.shared.currentUser {
                    user.hasConnectedInstagram = false
                    UserSessionManager.shared.saveUpdatedUserData(user: user) {_,_ in
                        completion(true, nil)
                    }
                }
                completion(true, nil)
            }
        }
    }
    
    func updateUserData(userKey key: String, withParam parameter: [String: Any], completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.me, []).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: parameter, method: .post, headers: header, isContentJSON: true) { (data, err) in
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
                    let user = try decoder.decode(OrbisUser.self, from: respData)
                    completion(user, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func updatePassword(withParam parameter: [String: Any], completion: @escaping responseBlock) {
        let url = GetApiAddress.auth(.changePassword).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: parameter, method: .post, headers: header, isContentJSON: true) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        }
    }
    
    func uploadUserProfileImage(withName name: String, image: UIImage, completion: @escaping responseBlock) {
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.profilePictures.rawValue)
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
            let imageThumbRef = Database.database().reference().child(FirebaseRTDBNode.userProPics.rawValue).child(String(imageName.split(separator: ".").first!))
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
    
    func fetchUserFeed(userKey key: String, from: String, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.feed, ["\(key)"]).url
        var parameters: [String: Any] = [
            GroupNetworkParameterKeys.Fetch.nextPage: from,
            GroupNetworkParameterKeys.Fetch.size: limit
        ]
        if from.isEmpty {
            parameters.removeValue(forKey: GroupNetworkParameterKeys.Fetch.nextPage)
        }
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let header = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .none, accept: .none)
        profileFeedSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: header, parameterDestination: .queryString, completion: { (data, err) in
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
                    let userFeed = try decoder.decode(OrbisFeedPaginatedResponse.self, from: respData)
                    completion(userFeed, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func followUser(userKey key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.followUnfollow, ["\(key)"]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .put, headers: header, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        })
    }
    
    func unfollowUser(key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.followUnfollow, ["\(key)"]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: header, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        })
    }
    
    func fetchInstagramPictures(forUser key: String, page: Int, size: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.instagramPictures, ["\(key)"]).url
        let parameters: [String: Any] = [
            UserProfileDomainParameterKeys.Fetch.page: page,
            UserProfileDomainParameterKeys.Fetch.size: size
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .none, accept: .none)
        profileInstaPictureSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
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
                    let mediaList = try decoder.decode(UserProfileMediaList.self, from: respData)
                    completion(mediaList.filter({$0.mediaType != .video}), nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func fetchOrbisPictures(forUser key: String, page: Int, size: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.appPictures, ["\(key)"]).url
        let parameters: [String: Any] = [
            UserProfileDomainParameterKeys.Fetch.page: page,
            UserProfileDomainParameterKeys.Fetch.size: size
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .none, accept: .none)
        profileAppPictureSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
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
                    let mediaList = try decoder.decode(UserProfileMediaList.self, from: respData)
                    completion(mediaList, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func deleteUserPhoto(key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.removeProfileUploadedPhoto, ["\(key)"]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: header, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        })
    }
    
    func reportUser(key: String, text: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.report, [key]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: ["reportText": text], method: .post, headers: header, isContentJSONString: true) { data, err in
            if let error = err {
                debugPrint("Error reporting profile \(error.localizedDescription)")
                completion(nil, error)
            }
            else {
                completion(true, nil)
            }
        }
    }
    
    func blockUser(key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.block, [key]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .put, headers: header, isContentJSONString: true) { data, err in
            if let error = err {
                debugPrint("Error blocking profile \(error.localizedDescription)")
                completion(nil, error)
            }
            else {
                completion(true, nil)
            }
        }
    }
    
    func unblockUser(key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.profile(.block, [key]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: header, isContentJSONString: true) { data, err in
            if let error = err {
                debugPrint("Error blocking profile \(error.localizedDescription)")
                completion(nil, error)
            }
            else {
                completion(true, nil)
            }
        }
    }
}
