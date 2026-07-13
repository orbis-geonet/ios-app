//
//  TwitterUser.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/04/2021.
//

import Foundation

class TwitterUser {
    var userId: String?
    var fullName: String?
    var fname:String?
    var lname:String?
    var email:String?
    var gender:String?
    var dateOfBirth: String?
    var profilePictureUrl: String?
    var isNewUser: Bool = true
    
    var calculatedFullName: String {
        return (fname ?? "") + " " + (lname ?? "")
    }
    
    init() {
        self.fullName = nil
        self.email = nil
        self.profilePictureUrl = nil
    }
    
    init(fromDict dict: [String: Any]) {
        self.fullName = dict["name"] as? String
        self.email = dict["email"] as? String
        self.profilePictureUrl = (dict["profile_image_url_https"] as? String) ?? (dict["profile_image_url"] as? String)
        self.profilePictureUrl = self.profilePictureUrl?.replacingOccurrences(of: "_normal", with: "")
    }
}
