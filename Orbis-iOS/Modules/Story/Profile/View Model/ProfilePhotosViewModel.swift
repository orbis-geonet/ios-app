//
//  ProfilePhotosViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 02/04/2021.
//

import Foundation
import UIKit
import Alamofire

class ProfilePhotosViewModel {
    let manager = UserProfileManager()
    var photos = UserProfileMediaList()
    var user: OrbisUser!
    let isViewingSelf: Bool!
    
    var onUserInstaMediaFetched: (() -> Void)?
    var onUserInstaMediaFetchedCompletePagination: (() -> Void)?
    var onUserInstaMediaFetchError: ((Error) -> Void)?
    
    var onUserAppMediaFetched: (() -> Void)?
    var onUserAppMediaFetchedCompletePagination: (() -> Void)?
    var onUserAppMediaFetchError: ((Error) -> Void)?
    
    private var instaMedia = UserProfileMediaList() {
        didSet {
            photos = OrbisSharedProfilePhotosUploadManager.shared.pendingPhotosUpload + appMedia + instaMedia
        }
    }
    var hasInstaMediaItemsLastPageReached = false
    var instaMediaPage: Int = 0
    
    private var appMedia = UserProfileMediaList() {
        didSet {
            photos = OrbisSharedProfilePhotosUploadManager.shared.pendingPhotosUpload + appMedia + instaMedia
        }
    }
    var hasAppMediaItemsLastPageReached = false
    var appMediaPage: Int = 0
    
    private let offsetVal: Int = 20
    
    init(user: OrbisUser!, isViewingSelf: Bool) {
        self.isViewingSelf = isViewingSelf
        self.user = user
        initializeAppMediaPagination()
        initializeInstaMediaPagination()
    }
    
    var photosCount: Int {
        return photos.count
    }
    
    func getPhotoModel(at index: Int) -> UserProfileMedia {
        return photos[index]
    }
    
    var emptyListText: String {
        return isViewingSelf ? AppStrings.Profile.emptyPhotosMessage : AppStrings.Profile.otherProfileEmptyPhotoMessage
    }
    
    var emptyListImage: UIImage? {
        return isViewingSelf ? UIImage(named: "profile-no-photos-ic") : UIImage(named: "other-profile-no-photos-ic")
    }
    
    func initializeInstaMediaPagination() {
        instaMedia = []
        hasInstaMediaItemsLastPageReached = false
        instaMediaPage = 0
    }
    
    func initializeAppMediaPagination() {
        appMedia = []
        hasAppMediaItemsLastPageReached = false
        appMediaPage = 0
    }
    
    func addPendingPhotos() {
        photos = OrbisSharedProfilePhotosUploadManager.shared.pendingPhotosUpload + appMedia + instaMedia
    }
    
    func loadUserInstagramMedia() {
        manager.invalidateInstaPicturesFetchSession { [weak self] data, err in
            guard let self = self else { return }
            self.manager.fetchInstagramPictures(forUser: self.user.userKey!, page: self.instaMediaPage, size: self.offsetVal) { [weak self] (data, err) in
                guard let self = self else { return }
                    if let error = err {
                        let nsError = error as NSError
                        if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                            return
                        }
                        if let afError = error as? AFError {
                            if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                                return
                            }
                        }
                        self.onUserInstaMediaFetchError?(error)
                        return
                    }
                    else {
                        if let items = data as? UserProfileMediaList {
                            if items.count > 0 {
                                self.instaMedia = items
                                self.onUserInstaMediaFetched?()
                                self.instaMediaPage += 1
                                self.hasInstaMediaItemsLastPageReached = false
                            }
                            else {
                                self.hasInstaMediaItemsLastPageReached = true
                                self.onUserInstaMediaFetchedCompletePagination?()
                            }
                        }
                        else {
                            self.onUserInstaMediaFetchError?(ResponseError.invalidData)
                            return
                        }
                    }
            }
        }
        
    }
    
    func loadMoreUserInstagramMedia() {
        self.manager.fetchInstagramPictures(forUser: self.user.userKey!, page: self.instaMediaPage, size: offsetVal)  { [weak self] (data, err) in
            guard let self = self else { return }
            if let error = err {
                if let afError = error as? AFError {
                    if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                        return
                    }
                }
                let nsError = error as NSError
                if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                    return
                }
                self.onUserInstaMediaFetchError?(error)
                return
            }
            else {
                if let items = data as? UserProfileMediaList {
                    if items.count > 0 {
                        self.instaMedia.append(contentsOf: items)
                        self.onUserInstaMediaFetched?()
                        self.instaMediaPage += 1
                        self.hasInstaMediaItemsLastPageReached = false
                    }
                    else {
                        self.hasInstaMediaItemsLastPageReached = true
                        self.onUserInstaMediaFetchedCompletePagination?()
                    }
                }
                else {
                    self.onUserInstaMediaFetchError?(ResponseError.invalidData)
                    return
                }
            }
        }
    }
    
    func loadUserAppMedia() {
        manager.invalidateAppPicturesFetchSession { [weak self] data, err in
            guard let self = self else { return }
            self.manager.fetchOrbisPictures(forUser: self.user.userKey!, page: self.appMediaPage, size: self.offsetVal) { [weak self] (data, err) in
                guard let self = self else { return }
                    if let error = err {
                        let nsError = error as NSError
                        if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                            return
                        }
                        if let afError = error as? AFError {
                            if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                                return
                            }
                        }
                        self.onUserAppMediaFetchError?(error)
                        return
                    }
                    else {
                        if let items = data as? UserProfileMediaList {
                            if items.count > 0 {
                                self.appMedia = items
                                self.onUserAppMediaFetched?()
                                self.appMediaPage += 1
                                self.hasAppMediaItemsLastPageReached = false
                            }
                            else {
                                self.hasAppMediaItemsLastPageReached = true
                                self.onUserAppMediaFetchedCompletePagination?()
                            }
                        }
                        else {
                            self.onUserAppMediaFetchError?(ResponseError.invalidData)
                            return
                        }
                    }
            }
        }
        
    }
    
    func loadMoreUserAppMedia() {
        self.manager.fetchOrbisPictures(forUser: self.user.userKey!, page: self.appMediaPage, size: offsetVal)  { [weak self] (data, err) in
            guard let self = self else { return }
            if let error = err {
                let nsError = error as NSError
                if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                    return
                }
                if let afError = error as? AFError {
                    if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                        return
                    }
                }
                self.onUserAppMediaFetchError?(error)
                return
            }
            else {
                if let items = data as? UserProfileMediaList {
                    if items.count > 0 {
                        self.appMedia.append(contentsOf: items)
                        self.onUserAppMediaFetched?()
                        self.appMediaPage += 1
                        self.hasAppMediaItemsLastPageReached = false
                    }
                    else {
                        self.hasAppMediaItemsLastPageReached = true
                        self.onUserAppMediaFetchedCompletePagination?()
                    }
                }
                else {
                    self.onUserAppMediaFetchError?(ResponseError.invalidData)
                    return
                }
            }
        }
    }
    
    func removePhoto(key: String, completion: @escaping responseBlock) {
        manager.deleteUserPhoto(key: key) {
            [weak self] data, error in
            guard let self = self else { return }
            if let error = error {
                completion(nil, error)
            }
            else {
                self.appMedia.removeAll(where: {$0.pictureKey == key})
                self.instaMedia.removeAll(where: {$0.pictureKey == key})
                completion(true, nil)
            }
        }
    }
}
