//
//  GoogleUser.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/04/2021.
//

import Foundation

class GoogleUser {
    var googleId:String?
    var fullName: String?
    var fname:String?
    var lname:String?
    var email:String?
    var gender:String?
    var dateOfBirth: String?
    var profilePictureUrl: String?
    var token: String?
    var idToken: String?
    var isNewUser: Bool = true
    
    var calculatedFullName: String {
        return (fname ?? "") + " " + (lname ?? "")
    }
    
    static var shared = GoogleUser()
}
