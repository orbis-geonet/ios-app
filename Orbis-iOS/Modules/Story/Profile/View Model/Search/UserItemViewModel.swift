//
//  UserItemViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 03/04/2021.
//

import Foundation
import UIKit

class UserItemViewModel {
    var model: OrbisUser!
    
    init(item: OrbisUser) {
        model = item
    }
    
    var name: String {
        return model.userDisplayName ?? ""
    }
    
    var propicLink: String {
        return model.proPicLink ?? ""
    }
    
    var baseColor: UIColor {
        return model.color
    }
}
