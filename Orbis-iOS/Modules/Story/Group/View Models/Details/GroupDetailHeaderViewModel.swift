//
//  GroupDetailHeaderViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 30/03/2021.
//

import Foundation
import UIKit

class GroupDetailHeaderViewModel {
    var model: Group!
    
    init(group: Group) {
        self.model = group
    }
    
    var name: String {
        return model.name ?? ""
    }
    
    var description: String {
        return model.description ?? ""
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
    
    var placesCountString: String {
        return model.placesCount?.formattedWithSeparator ?? "0"
    }
    
    var membersCountString: String {
        return model.membersCount?.formattedWithSeparator ?? "0"
    }
    
    var isMainAdmin: Bool {
        return model.isMainAdmin ?? false
    }
    
    var hasSubscription: Bool {
        return model.hasSubscription ?? false
    }
    
    var isSubscriptionActive: Bool {
        return model.isSubscriptionActivate ?? false
    }
    
    var isMember: Bool {
        return model.isMember ?? false
    }
    
    var isAdmin: Bool {
        return model.isAdmin ?? false
    }
    
    var isSubscriber: Bool {
        return model.isSubscriber ?? false
    }
    
    var isNotInGroup: Bool {
        return !isMember && !isAdmin && !isMainAdmin
    }
    
    var memberShouldSeeSubscription: Bool {
        return (isMember || isAdmin) && !isMainAdmin && isSubscriptionActive
    }
}
