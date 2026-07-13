//
//  ProfileDetailViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 02/04/2021.
//

import Foundation
import UIKit
import Alamofire

class ProfileDetailViewModel {
    var user: OrbisUser!
    var userInstaResponse: OrbisUserInstaConnectResponse?
    let isViewingSelf: Bool!
    var fullSizeMediaData: [AnyObject] = []
    let detailManager = UserProfileManager()
    let messagesManager = OrbisConversationManager()
    
    var onUserBlockedTrue: (() -> Void)?
    var onUserDetailSyncError: ((Error) -> Void)?
    var onUserDetailSyncSuccess: (() -> Void)?
    
    var onUserInstaSyncError: ((Error) -> Void)?
    var onUserInstaSyncSuccess: (() -> Void)?
    
    var onUserDetailUpdateError: ((Error) -> Void)?
    var onUserDetailUpdateSuccess: (() -> Void)?
    
    var isFollowUnfollowProcessing = false
    var isBlockUnblockProcessing = false
    
    init(user: OrbisUser, isViewingSelf: Bool) {
        self.user = user
        fullSizeMediaData = []
        self.isViewingSelf = isViewingSelf
    }
    
    var isAccountPrivate: Bool {
        return user.accountPrivate ?? false
    }
    
    var isRequestPending: Bool {
        return user.pending ?? false
    }
    
    var canInteractWithProfile: Bool {
        if isViewingSelf {
            return true
        }
        if isAccountPrivate {
            return isFollowing
        }
        return true
    }
    
    var isFollowing: Bool {
        return user.following ?? false
    }
    
    var userFullName: String {
        return user.userDisplayName ?? ""
    }
    
    var userProPicLink: String {
        return user.proPicLink ?? ""
    }
    
    var userBaseColor: UIColor {
        return user.color
    }
    
    var userGroupCountVal: Int {
        return user.userGroup
    }
    
    var userFollowersVal: Int {
        return user.totalFollowers ?? 0
    }
    
    var userFollowingsVal: Int {
        return user.totalFollowing ?? 0
    }
    
    var userGroupCount: String {
        return "\(user.userGroup.formattedWithSeparator)"
    }
    
    var userFollowerCount: String {
        return "\((user.totalFollowers ?? 0).formattedWithSeparator)"
    }
    
    var userFollowingCount: String {
        return "\((user.totalFollowing ?? 0).formattedWithSeparator)"
    }
    
    var hasConnectedInstagram: Bool {
        set {
            user.hasConnectedInstagram = newValue
        }
        get {
            return user.hasConnectedInstagram ?? false
        }
    }
    
    var hasFollowed: Bool {
        set {
            user.following = newValue
        }
        get {
            return user.hasFollowed
        }
    }
    
    var isUserBlocked: Bool {
        return !isViewingSelf && self.user.blocked == true
    }
    
    var isUserBlockable: Bool {
        return !isUserBlocked && !isViewingSelf
    }
    
    var blockUserTitle: String {
        return AppStrings.Profile.blockConfirmationTitle + " \(self.userFullName)"
    }
    
    func syncUserDataWithServer() {
        detailManager.syncProfileDetail(forUser: self.user.userKey!) { [weak self] (data, err) in
            if let error = err {
                self?.onUserDetailSyncError?(error)
                return
            }
            if let user = data as? OrbisUser {
                user.hasConnectedInstagram = self?.userInstaResponse?.connectedStatus == .connected
                self?.user = user
                if self?.isViewingSelf == true {
                    UserSessionManager.shared.saveUpdatedUserData(user: user) { data,err in
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: AppNotificationKeys.userDidUpdate), object: nil)
                    }
                }
                self?.onUserDetailSyncSuccess?()
                if self?.isViewingSelf == false && user.blocked == true {
                    self?.onUserBlockedTrue?()
                }
            }
            else {
                self?.onUserDetailSyncError?(ResponseError.invalidData)
            }
        }
    }
    
    func checkInstagramConnectionStatus() {
        detailManager.checkInstagramLinkStatus { [weak self] (data, err) in
            if let error = err {
                self?.onUserInstaSyncError?(error)
                return
            }
            if let instaResponse = data as? OrbisUserInstaConnectResponse {
                self?.user.hasConnectedInstagram = instaResponse.connectedStatus == .connected
                self?.userInstaResponse = instaResponse
                self?.onUserInstaSyncSuccess?()
            }
            else {
                self?.onUserInstaSyncError?(ResponseError.invalidData)
            }
        }
    }
    
    func disconnectInstagram(completion: @escaping responseBlock) {
        detailManager.disconnectInstagram { [weak self] data, err in
            guard let self = self else { return }
            if let error = err {
                completion(nil, error)
                return
            }
            else {
                self.detailManager.checkInstagramLinkStatus { [weak self] (data, err) in
                    if let error = err {
                        completion(nil, error)
                        return
                    }
                    if let instaResponse = data as? OrbisUserInstaConnectResponse {
                        self?.user.hasConnectedInstagram = instaResponse.connectedStatus == .connected
                        self?.userInstaResponse = instaResponse
                        completion(true, nil)
                    }
                    else {
                        completion(nil, ResponseError.invalidData)
                    }
                }
            }
        }
    }
    
    func reportProfile(withText text: String, completion: @escaping responseBlock) {
        guard let _ = UserSessionManager.shared.currentUser else { return }
        detailManager.reportUser(key: self.user.userKey!, text: text, completion: completion)
    }
    
    func uploadUserPicture(image: UIImage) {
        let fileName = UUID().uuidString
        detailManager.uploadUserProfileImage(withName: fileName, image: image) { [weak self] (data, err) in
            if let error = err {
                self?.onUserDetailUpdateError?(error)
                return
            }
            else {
                self?.updateProfilePictureData(imageName: data as! String)
            }
        }
    }
    
    private func updateProfilePictureData(imageName: String) {
        let param: [String: Any] = [UserProfileDomainParameterKeys.Update.imageName: imageName]
        detailManager.updateUserData(userKey: self.user.userKey!, withParam: param) { [weak self] (data, err) in
            if let error = err {
                self?.onUserDetailUpdateError?(error)
                return
            }
            if let user = data as? OrbisUser {
                user.hasConnectedInstagram = self?.userInstaResponse?.connectedStatus == .connected
                self?.user = user
                if self?.isViewingSelf == true {
                    UserSessionManager.shared.saveUpdatedUserData(user: user) { data,err in
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: AppNotificationKeys.userDidUpdate), object: nil)
                    }
                }
                self?.onUserDetailUpdateSuccess?()
            }
            else {
                self?.onUserDetailUpdateError?(ResponseError.invalidData)
            }
        }
    }
    
    func uploadUserProfilePhotos(imagesData: [Data], completion: @escaping responseBlock) {
        guard let selfUser = UserSessionManager.shared.currentUser else { return }
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        let url = GetApiAddress.profile(.postAppPictures, []).url
        let pendingMedia = UserProfileMedia(pictureKey: UUID().uuidString, userKey: selfUser.userKey, pictureUrl: nil, type: "ORBIS", timestamp: nil, imageType: "IMAGE", pendingImagesData: imagesData)
        OrbisSharedProfilePhotosUploadManager.shared.uploadProfileImages(imageMedia: pendingMedia, parameters: [:], url: url, headers: header)
        completion(true, nil)
    }
    
    func followUnfollow(completion: @escaping responseBlock) {
        self.isFollowUnfollowProcessing = true
        if self.user.hasFollowed {
            detailManager.unfollowUser(key: self.user.userKey!) { [weak self] data, err in
                self?.isFollowUnfollowProcessing = false
                if err == nil {
                    self?.user.updateUserFollowers(isIncrement: false)
                    self?.user.following = false
                }
                completion(data, err)
            }
        }
        else {
            detailManager.followUser(userKey: self.user.userKey!) { [weak self] data, err in
                self?.isFollowUnfollowProcessing = false
                if err == nil {
                    if self?.user.accountPrivate == true {
                        self?.user.following = false
                        self?.user.pending = true
                    }
                    else {
                        self?.user.updateUserFollowers(isIncrement: true)
                        self?.user.following = true
                    }
                }
                completion(data, err)
            }
        }
    }
    
    func blockUnblock(completion: @escaping responseBlock) {
        guard !self.isViewingSelf else {
            completion(false, nil)
            return
        }
        self.isBlockUnblockProcessing = true
        if self.user.blocked == true {
            detailManager.unblockUser(key: self.user.userKey!) { [weak self] data, err in
                self?.isBlockUnblockProcessing = false
                if err == nil {
                    self?.user.blocked = false
                }
                completion(data, err)
            }
        }
        else {
            detailManager.blockUser(key: self.user.userKey!) { [weak self] data, err in
                self?.isBlockUnblockProcessing = false
                if err == nil {
                    self?.user.blocked = true
                }
                completion(data, err)
            }
        }
    }
    
    func fetchUnreadMessagesCount(completion: @escaping responseBlock) {
        messagesManager.fetchUnreadMessagesCount(completion: completion)
    }
    
    func getCreatedConversation(of selfUser: OrbisUser, withUser user: OrbisUser, completion: @escaping responseBlock) {
        messagesManager.createConversation(ofUser: selfUser, withUser: user, completion: completion)
    }
}
