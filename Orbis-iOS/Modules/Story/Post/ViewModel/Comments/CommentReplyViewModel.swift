//
//  CommentReplyViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 18/04/2021.
//

import Foundation
import UIKit

class CommentReplyViewModel {
    var model: PostComment!
    
    init(reply: PostComment) {
        self.model = reply
    }
    
    private var comment: String {
        return model.text
    }
    
    var userName: String {
        return model.user?.userDisplayName ?? ""
    }
    
    var commentAttributed: NSAttributedString {
        let commentAttached = userName + " " + comment
        
        let userName = (commentAttached as NSString).range(of: self.userName)
        
        let attributedString = NSMutableAttributedString(string: commentAttached, attributes: [
            NSAttributedString.Key.font : UIFont(name: "Roboto-Regular", size: CGFloat(16).relativeToIphone8Width())!,
            NSAttributedString.Key.foregroundColor : UIColor(named: AppColors.appWarmGray2.rawValue)!
        ])
        attributedString.setAttributes([
            NSAttributedString.Key.foregroundColor : UIColor(named: AppColors.appBlack.rawValue)!,
            NSAttributedString.Key.font : UIFont(name: "Roboto-Bold", size: CGFloat(16).relativeToIphone8Width())!,
        ], range: userName)
        return attributedString
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
