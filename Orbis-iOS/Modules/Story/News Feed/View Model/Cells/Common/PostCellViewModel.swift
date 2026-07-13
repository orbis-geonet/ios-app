//
//  PostCellViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 29/03/2021.
//

import Foundation
import UIKit

class PostCellViewModel {
    var model: OrbisFeedPost!
    
    init(data: OrbisFeedPost) {
        self.model = data
    }
    
    var isTextExpanded: Bool {
        return model.isDescriptionExpanded
    }
    var numberOfLines: Int {
        return isTextExpanded ? 0 : AppValues.postTextMaxLines
    }
    
    var isPendingPost: Bool {
        return model.isPendingPost
    }
    
    var posterFullName: String {
        if let group = model.group {
            return group.name ?? ""
        }
        return model.user?.userDisplayName ?? ""
    }
    
    var posterProPicLink: String {
        if let group = model.group {
            return group.imageName ?? ""
        }
        return model.user?.proPicLink ?? ""
    }
    
    var subPosterFullName: String {
        if let _ = model.group {
            return model.user?.userDisplayName ?? ""
        }
        return ""
    }
    
    var subPosterProPicLink: String {
        if let _ = model.group {
            return model.user?.proPicLink ?? ""
        }
        return ""
    }
    
    var posterBaseColor: UIColor {
        if let group = model.group {
            if let strokeColor = group.strokeColorHexString {
                return UIColor.hexStringToUIColor(hex: strokeColor)
            }
            return group.baseColor
        }
        return model.user?.color ?? .clear
    }
    
    var datePostedString: String {
        return Date.fromString(string: model.timestamp ?? "", with: ISOCommonFormatter.shared)?.dateString(DateFormat.postDateTimestampFormat.rawValue) ?? ""
    }
    
    var locationString: String {
        return model.location
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
    
    var shouldShowBottomUser: Bool {
        return model.showOtherUsers
    }
    
    var hasRichTextContent: Bool {
        return model.richLinkData != nil
    }
    
    var richContent: OrbisRichLinkData? {
        return model.richLinkData
    }
}
