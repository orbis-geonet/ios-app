//
//  FirebaseDatabaseManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 09/05/2021.
//

import Foundation
import FirebaseDatabase
import CodableFirebase
import Firebase

enum FirebaseFirestoreNode: String {
    case conversation
    case chatMessages
    case userActivity
    case appConfig
    case appLinks
}

enum FirebaseRTDBNode: String {
    case groupOwnership
    case placeSizes
    case eventImages = "images/events/images"
    case postImages = "images/posts/images"
    case groupProPics = "images/groupPictures"
    case placeProPics = "images/placePictures"
    case userProPics = "images/profilePictures"
    case userProfilePersonalPictures = "images/user/pictures"
    case conversationPhotos = "images/chat/images"
    case subscriptionImages = "images/groups/subscription/images"
}

typealias GroupOwnershipChildChangedResult = (hash: String, data: GroupOwnershipFirebaseModel)
typealias PlaceSizesChildChangedResult = (hash: String, data: PlaceSizesFirebaseModel)

class FirebaseDatabaseManager {
    var ref: DatabaseReference! = Database.database().reference()
    
    var onGroupOwnershipChildChanged: ((GroupOwnershipChildChangedResult) -> Void)?
    var onPlaceSizeChildChanged: ((PlaceSizesChildChangedResult) -> Void)?
    
    
    func observeGroupOwnershipValueChange(value hash: String, at timestamp: Double) -> UInt {
        return ref.child(FirebaseRTDBNode.groupOwnership.rawValue).child(hash).queryOrdered(byChild: "timestamp").queryStarting(atValue: timestamp).observe(.childChanged) { [weak self] snapshot in
            guard let self = self else { return }
            guard let data = snapshot.value else { return }
            do {
                let model = try FirebaseDecoder().decode(GroupOwnershipFirebaseModel.self, from: data)
                self.onGroupOwnershipChildChanged?((hash: hash, data: model))
            } catch let error {
                print(error)
            }
        }
    }
    
    func observePlaceSizesValueChange(value hash: String, at timestamp: Double) -> UInt {
        return ref.child(FirebaseRTDBNode.placeSizes.rawValue).child(hash).queryOrdered(byChild: "lastSizeChangeTimestamp").queryStarting(atValue: timestamp).observe(.childChanged) { [weak self] snapshot in
            guard let self = self else { return }
            guard let data = snapshot.value else { return }
            do {
                let model = try FirebaseDecoder().decode(PlaceSizesFirebaseModel.self, from: data)
                guard let lastSize = model.lastSize, lastSize > 0 else { return }
                self.onPlaceSizeChildChanged?((hash: hash, data: model))
            } catch let error {
                print(error)
            }
        }
    }
    
    func observeGroupOwnershipChildAdd(value hash: String, at timestamp: Double) -> UInt {
        return ref.child(FirebaseRTDBNode.groupOwnership.rawValue).child(hash).queryOrdered(byChild: "timestamp").queryStarting(atValue: timestamp).observe(.childAdded) { [weak self] snapshot in
            guard let self = self else { return }
            guard let data = snapshot.value else { return }
            do {
                let model = try FirebaseDecoder().decode(GroupOwnershipFirebaseModel.self, from: data)
                self.onGroupOwnershipChildChanged?((hash: hash, data: model))
            } catch let error {
                print(error)
            }
        }
    }
    
    func observePlaceSizeChildAdd(value hash: String, at timestamp: Double) -> UInt {
        return ref.child(FirebaseRTDBNode.placeSizes.rawValue).child(hash).queryOrdered(byChild: "lastSizeChangeTimestamp").queryStarting(atValue: timestamp).observe(.childAdded) { [weak self] snapshot in
            guard let self = self else { return }
            guard let data = snapshot.value else { return }
            do {
                let model = try FirebaseDecoder().decode(PlaceSizesFirebaseModel.self, from: data)
                guard let lastSize = model.lastSize, lastSize > 0 else { return }
                self.onPlaceSizeChildChanged?((hash: hash, data: model))
            } catch let error {
                print(error)
            }
        }
    }
    
    
    func removeAllObservers() {
        ref.removeAllObservers()
    }
    
    func removeObserver(handle: UInt) {
        ref.removeObserver(withHandle: handle)
    }
}
