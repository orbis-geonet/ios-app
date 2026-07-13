//
//  EventUserItemViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 18/04/2021.
//

import Foundation

class EventUserItemViewModel {
    var model: OrbisUser!
    
    init(user: OrbisUser) {
        self.model = user
    }
    
    var propicLink: String {
        return model.proPicLink ?? ""
    }
    
    var name: String {
        return model.userDisplayName ?? ""
    }
    
}
