//
//  FacebookUser.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/04/2021.
//

import Foundation

class FacebookUser: NSObject {
    var fbId:String?
    var userId: String?
    var fullName: String?
    var fname:String?
    var lname:String?
    var email:String?
    var gender:String?
    var dateOfBirth: String?
    var profilePictureUrl: String?
    var coverPhotoUrl: String?
    var userWebsite: String?
    var userHometowm: String?
    var userCurrentLocation: String?
    var userBio: String?
    var isNewUser: Bool = true
    
    var calculatedFullName: String {
        return (fname ?? "") + " " + (lname ?? "")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
    }
    
    static var shared = FacebookUser()
}
