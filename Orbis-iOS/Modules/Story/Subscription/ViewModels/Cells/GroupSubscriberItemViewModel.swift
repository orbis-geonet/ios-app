//
//  GroupSubscriberItemViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 22/08/2023.
//

import Foundation

class GroupSubscriberItemViewModel {
    var model: GroupSubscriber!
    
    init(model: GroupSubscriber!) {
        self.model = model
    }
    
    var name: String {
        return model.userDisplayName ?? ""
    }
    
    var propicLink: String {
        return model.proPicLink ?? ""
    }
    
    var codes: [String] {
        return model.codes ?? []
    }
}
