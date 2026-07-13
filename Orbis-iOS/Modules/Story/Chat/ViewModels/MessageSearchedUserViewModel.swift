//
//  MessageSearchedUserViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 20/04/2021.
//

import Foundation

class MessageSearchedUserViewModel {
    var user: OrbisUser!
    
    init(user: OrbisUser) {
        self.user = user
    }
    
    var name: String {
        return user.userDisplayName ?? ""
    }
    
    var proPicLink: String {
        return user.proPicLink ?? ""
    }
}
