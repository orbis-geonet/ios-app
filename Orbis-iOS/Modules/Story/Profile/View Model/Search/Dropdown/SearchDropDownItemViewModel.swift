//
//  SearchDropDownItemViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 04/05/2021.
//
import Foundation
import UIKit

enum SearchDropDownItemType: String {
    case user
    case group
}

class SearchDropDownItemViewModel {
    var userModel: OrbisUser?
    var groupModel: Group?
    var type: SearchDropDownItemType!
    
    init(user: OrbisUser?, group: Group?, type: SearchDropDownItemType!) {
        self.type = type
        userModel = user
        groupModel = group
    }
    
    var name: String {
        return type == .user ? userName : groupName
    }
    
    var propicLink: String {
        return type == .user ? userPropicLink : groupProPicLink
    }
    
    var baseColor: UIColor {
        return type == .user ? userBaseColor : groupBaseColor
    }
    
    private var userName: String {
        return userModel?.userDisplayName ?? ""
    }
    
    private var userPropicLink: String {
        return userModel?.proPicLink ?? ""
    }
    
    private var userBaseColor: UIColor {
        return userModel?.color ?? .clear
    }
    
    private var groupName: String {
        return groupModel?.name ?? ""
    }
    
    private var groupProPicLink: String {
        return groupModel?.imageName ?? ""
    }
    
    private var groupBaseColor: UIColor {
        if let strokeColor = groupModel?.strokeColorHexString {
            return UIColor.hexStringToUIColor(hex: strokeColor)
        }
        return groupModel?.baseColor ?? .clear
    }
}
