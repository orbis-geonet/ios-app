//
//  CheckinPlaceItemViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 07/04/2021.
//

import Foundation
import UIKit

class CheckinPlaceItemViewModel {
    var model: OrbisPlace!
    var isBorderless: Bool!
    
    init(place: OrbisPlace, isBorderless: Bool = false) {
        self.model = place
        self.isBorderless = isBorderless
    }
    
    var placeName: String {
        return model.name ?? ""
    }
    
    var borderColor: UIColor {
        if let strokeColor = model.placeDominantGroup?.strokeColorHexString {
            return UIColor.hexStringToUIColor(hex: strokeColor)
        }
        return model.placeDominantGroup?.baseColor ?? .clear
    }
    
    var placeTypeBorderColor: UIColor {
        if isBorderless {
            return .clear
        }
        if let strokeColor = model.placeDominantGroup?.strokeColorHexString {
            return UIColor.hexStringToUIColor(hex: strokeColor)
        }
        return .clear
    }
    
    var placeTypeImage: UIImage {
        return model.placeType.correspondingCircularImage()
    }
    
    var placeProPicLink: String {
        return model.imageName ?? ""
    }
    
    var placeDominantGroupImageLink: String {
        return model.placeDominantGroup?.imageName ?? ""
    }
}
