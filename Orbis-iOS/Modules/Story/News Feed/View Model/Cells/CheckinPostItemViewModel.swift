//
//  CheckinPostItemViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 29/03/2021.
//

import Foundation
import UIKit

class CheckingPostItemViewModel {
    var model: OrbisFeedPost!
    
    private lazy var formatter = ISOCommonFormatter.shared
    
    init(data: OrbisFeedPost) {
        model = data
    }
    
    var postUserFullName: String {
        return model.group?.name ?? ""
    }
    
    var postUserProPicLink: String {
        return model.group?.imageName ?? ""
    }
    
    var postUserBaseColor: UIColor {
        if let strokeColor = model.group?.strokeColorHexString {
            return UIColor.hexStringToUIColor(hex: strokeColor)
        }
        return model.group?.baseColor ?? .clear
    }
    
    var datePostedString: String {
        return Date.fromString(string: model.timestamp ?? "", with: formatter)?.dateString(DateFormat.postDateTimestampFormat.rawValue) ?? ""
    }
    
    var locationString: String {
        return ""
    }
    
    var hasLiked: Bool {
        return model.hasLiked ?? false
    }
    
    var likeIconColor: UIColor {
        return hasLiked ? UIColor(named: AppColors.appBlack.rawValue)! : UIColor(named: AppColors.appOffWhite.rawValue)!
    }
    
    var likeCountString: String {
        return "\(model.likeCount)"
    }
    
    var commentCountString: String {
        return "\(model.commentCount)"
    }
    
    var checkinUserName: String {
        return model.user?.userDisplayName ?? ""
    }
    
    var checkinUserProPic: String {
        return model.user?.proPicLink ?? ""
    }
    
    var checkinPlace: String {
        return model.location
    }
    
    var checkinPlaceType: OrbisPlaceType {
        return model.place?.placeType ?? .location
    }
    
    var placeImageName: String {
        return model.place?.imageName ?? ""
    }
}
