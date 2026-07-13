//
//  GroupItemViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 30/03/2021.
//

import Foundation
import UIKit

class GroupItemViewModel {
    var model: Group!
    
    init(item: Group) {
        model = item
    }
    
    var name: String {
        return model.name ?? ""
    }
    
    var propicLink: String {
        return model.imageName ?? ""
    }
    
    var baseColor: UIColor {
        if let strokeColor = model.strokeColorHexString {
            return UIColor.hexStringToUIColor(hex: strokeColor)
        }
        return model.baseColor
    }
    
    var indicatorImage: UIImage? {
        return model.indicatorIcon
    }
}
