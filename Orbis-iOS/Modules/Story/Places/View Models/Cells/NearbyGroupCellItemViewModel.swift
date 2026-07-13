//
//  NearbyGroupCellItemViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 03/04/2021.
//

import Foundation
import UIKit

class NearbyGroupCellItemViewModel {
    let group: Group!
    
    init(group: Group) {
        self.group = group
    }
    
    var name: String {
        return group.name ?? ""
    }
    
    var propicLink: String {
        return group.imageName ?? ""
    }
    
    var baseColor: UIColor {
        if let strokeColor = group.strokeColorHexString {
            return UIColor.hexStringToUIColor(hex: strokeColor)
        }
        return group.baseColor
    }
}
