//
//  PostCommentItemViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 18/04/2021.
//

import Foundation
import UIKit

class PostCommentItemViewModel {
    var model: PostComment!
    
    init(comment: PostComment) {
        self.model = comment
    }
    
    var hasMore: Bool {
        return model.hasMoreReplies
    }
    
    var repliesCount: Int {
        return replies.count
    }
    
    var replies: PostComments {
        return model.replies ?? []
    }
    
    var comment: String {
        return model.text
    }
    
    var userName: String {
        return model.user?.userDisplayName ?? ""
    }
    
    var userProPicLink: String {
        return model.user?.proPicLink ?? ""
    }
    
    var likesCount: String {
        return "\(model.likesCount ?? 0)"
    }
    
    var hasLiked: Bool {
        return model.hasLiked ?? false
    }
    
    var likeIconColor: UIColor {
        return hasLiked ? UIColor(named: AppColors.appBlack.rawValue)! : UIColor(named: AppColors.appOffWhite.rawValue)!
    }
    
    var datePosted: String {
        return model.commentPostedDateString
    }
}
