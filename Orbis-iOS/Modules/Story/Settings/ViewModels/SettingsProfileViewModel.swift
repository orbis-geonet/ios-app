//
//  SettingsProfileViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 12/04/2021.
//

import Foundation
import UIKit

class SettingsProfileViewModel {
    var user: OrbisUser!
    var editedUser: OrbisUser!
    var userSelectedImage: UIImage?
    let detailManager = UserProfileManager()
    
    var hasUserConnectedInstagram: Bool?
    
    var onUserDetailUpdateError: ((Error) -> Void)?
    var onUserDetailUpdateSuccess: (() -> Void)?
    
    init(user: OrbisUser) {
        self.user = user
        self.hasUserConnectedInstagram = user.hasConnectedInstagram
        self.editedUser = OrbisUser.copyFrom(user: user)
    }
    
    var hasDataChanged: Bool {
        return editedUser.getChangedProfileData(fromBase: user).count > 0
    }
    
    var userFullName: String {
        set {
            editedUser.name = newValue
        }
        get {
            return editedUser.name ?? ""
        }
    }
    
    var userProPicLink: String {
        return user.proPicLink ?? ""
    }
    
    var userEmail: String {
        return user.email ?? ""
    }
    
    var userPassword: String {
        return "orbisApp"
    }
    
    var userDOB: Date? {
        if let dobStr = editedUser.dateOfBirth {
            return Date.fromString(dateString: dobStr, format: DateFormat.normalDateFormat.rawValue)
        }
        return nil
    }
    
    var dob: String {
        set {
            editedUser.dateOfBirth = newValue
        }
        get {
            return editedUser.dateOfBirth ?? ""
        }
    }
    
    var gender: String {
        set {
            editedUser.gender = newValue.capitalized
        }
        get {
            return editedUser.gender?.capitalized ?? ""
        }
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
                user.hasConnectedInstagram = self?.hasUserConnectedInstagram
                self?.user = user
                UserSessionManager.shared.saveUpdatedUserData(user: user) { data,err in
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: AppNotificationKeys.userDidUpdate), object: nil)
                }
                self?.onUserDetailUpdateSuccess?()
            }
            else {
                self?.onUserDetailUpdateError?(ResponseError.invalidData)
            }
        }
    }
    
    private func validateFields(completion: @escaping responseBlock) {
        if userFullName.isEmpty {
            completion(nil, ValidationErrors.emptyFullName)
        }
        else if dob.isEmpty {
            completion(nil, ValidationErrors.emptyDOB)
        }
        else if gender.isEmpty {
            completion(nil, ValidationErrors.emptyGender)
        }
        else {
            completion(true, nil)
        }
    }
    
    func tryUpdateProfileInfo(completion: @escaping responseBlock) {
        guard hasDataChanged else {
            completion(true, nil)
            return
        }
        validateFields { data, err in
            if let error = err {
                completion(nil, error)
            }
            else {
                self.proceedUpdateProfileInfo(completion: completion)
            }
        }
    }
    
    private func proceedUpdateProfileInfo(completion: @escaping responseBlock) {
        let param = editedUser.getChangedProfileData(fromBase: user)
        guard param.count > 0 else {
            completion(true, nil)
            return
        }
        detailManager.updateUserData(userKey: self.user.userKey!, withParam: param) { [weak self] (data, err) in
            if let error = err {
                self?.onUserDetailUpdateError?(error)
                return
            }
            if let user = data as? OrbisUser {
                user.hasConnectedInstagram = self?.hasUserConnectedInstagram
                self?.user = user
                UserSessionManager.shared.saveUpdatedUserData(user: user) { data,err in
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: AppNotificationKeys.userDidUpdate), object: nil)
                }
                self?.onUserDetailUpdateSuccess?()
            }
            else {
                self?.onUserDetailUpdateError?(ResponseError.invalidData)
            }
        }
    }
    
    func tryChangePassword(oldPass: String, newPass: String, completion: @escaping responseBlock) {
        let param = [
            UserProfileDomainParameterKeys.ChangePassword.email: userEmail,
            UserProfileDomainParameterKeys.ChangePassword.oldPass: oldPass,
            UserProfileDomainParameterKeys.ChangePassword.newPass: newPass
        ]
        detailManager.updatePassword(withParam: param, completion: completion)
    }
}
