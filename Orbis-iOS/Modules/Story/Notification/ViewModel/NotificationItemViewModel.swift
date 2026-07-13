//
//  NotificationItemViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 10/04/2021.
//

import Foundation
import UIKit

class NotificationItemViewModel {
    var model: OrbisNotification!
    
    init(notif: OrbisNotification) {
        self.model = notif
    }
    
    var userProPicLink: String {
        return model.fromUser?.proPicLink ?? ""
    }
    
    private var message: String {
        return model.details ?? ""
    }
    
    private var dateTimeString: String {
        return model.notificationReceivedDateString
    }
    
    private var boldMessages: [String] {
        return model.boldTexts
    }
    
    private var notifMessage: String {
        return message + " \(dateTimeString)"
    }
    
    var attributedMessage: NSMutableAttributedString {
        let dateTimeWord = dateTimeString
        
        let dateTimeWordRange = (notifMessage as NSString).range(of: dateTimeWord)
        
        let attributedString = NSMutableAttributedString(string: notifMessage, attributes: [
            NSAttributedString.Key.font : UIFont(name: "Roboto-Regular", size: CGFloat(16).relativeToIphone8Width())!,
            NSAttributedString.Key.foregroundColor : UIColor(named: AppColors.appBlack.rawValue)!
        ])
        attributedString.setAttributes([
            NSAttributedString.Key.foregroundColor : UIColor(named: AppColors.appPinkishGray.rawValue)!,
            NSAttributedString.Key.font : UIFont(name: "Roboto-Regular", size: CGFloat(16).relativeToIphone8Width())!,
        ], range: dateTimeWordRange)
        
        for word in boldMessages {
            let boldWordRange = (notifMessage as NSString).range(of: word)
            attributedString.setAttributes([
                NSAttributedString.Key.foregroundColor : UIColor(named: AppColors.appBlack.rawValue)!,
                NSAttributedString.Key.font : UIFont(name: "Roboto-Bold", size: CGFloat(16).relativeToIphone8Width())!,
            ], range: boldWordRange)
        }
        return attributedString
    }
}
