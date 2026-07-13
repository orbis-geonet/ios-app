//
//  CreateGroupViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 30/03/2021.
//

import Foundation
import UIKit
import CoreLocation

class CreateGroupViewModel {
    var group: Group!
    let manager = CreateGroupManager()
    let colors = [
        UIColor(named: AppColors.appOrangeYellow.rawValue)!,
        UIColor(named: AppColors.appPink.rawValue)!,
        UIColor(named: AppColors.appPurple.rawValue)!,
        UIColor(named: AppColors.appBlue.rawValue)!,
        UIColor(named: AppColors.appRobinsEgg.rawValue)!,
        UIColor(named: AppColors.appLightGreen.rawValue)!,
        UIColor(named: AppColors.appNeonYellow.rawValue)!,
    ]
    let originalGroup: Group!
    
    var userLocation: CLLocationCoordinate2D! {
        return UserSessionManager.shared.userCurrentLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
    
    var colorCount: Int {
        return colors.count
    }
    
    var selectedColorIndex: Int? = nil {
        didSet {
            self.baseColor = getColor(at: selectedColorIndex!)
        }
    }
    
    var isEditMode = false
    
    init() {
        selectedColorIndex = nil
        selectedImage = nil
        group = Group(name: "", propicLink: "", baseColor: .clear, indicatorIconName: "", description: "", places: 0, members: 0)
        self.group.groupKey = ""
        self.originalGroup = Group.copyFrom(group: group)
    }
    
    init(group: Group) {
        selectedColorIndex = group.colorIndex
        selectedImage = nil
        isEditMode = true
        self.group = group
        if let strokeColor = group.strokeColorHexString {
            self.group.baseColor = UIColor.hexStringToUIColor(hex: strokeColor)
        }
        self.originalGroup = Group.copyFrom(group: self.group)
    }
    
    func getColor(at index: Int) -> UIColor {
        return colors[index]
    }
    
    let staticLinkText = "https//orbis.social/g/"
    var saveText: String {
        return isEditMode ? AppStrings.save : AppStrings.Group.Create.createGroup
    }
    
    var hasEditChanged: Bool {
        if let _ = selectedImage {
            return true
        }
        if let index = selectedColorIndex, index != originalGroup.colorIndex {
            return true
        }
        return (originalGroup.name != group.name) || (originalGroup.description != group.description)
    }
    
    var name: String {
        get {
            return group.name ?? ""
        }
        set {
            group.name = newValue
        }
    }
    
    var description: String {
        get {
            return group.description ?? ""
        }
        set {
            group.description = newValue
        }
    }
    
    var baseColor: UIColor? {
        get {
            return (group.baseColor == UIColor.clear) ? nil : group.baseColor
        }
        set {
            group.baseColor = newValue ?? .clear
        }
    }
    
    var selectedImage: UIImage? = nil
    
    var toCreateParams: [String: Any] {
        var params = [String: Any]()
        params[GroupNetworkParameterKeys.Create.name] = self.name
        params[GroupNetworkParameterKeys.Create.description] = self.description
        params[GroupNetworkParameterKeys.Create.strokeColorHex] = self.baseColor?.toHexString()
        params[GroupNetworkParameterKeys.Create.colorIndex] = self.selectedColorIndex
        let locationParam = [
            GroupNetworkParameterKeys.Create.longitude: userLocation.longitude,
            GroupNetworkParameterKeys.Create.latitude: userLocation.latitude
        ]
        params[GroupNetworkParameterKeys.Create.location] = locationParam
        return params
    }
    
    var toEditParams: [String: Any] {
        var params = [String: Any]()
        params[GroupNetworkParameterKeys.Create.name] = self.name
        params[GroupNetworkParameterKeys.Create.description] = self.description
        params[GroupNetworkParameterKeys.Create.strokeColorHex] = self.baseColor?.toHexString()
        params[GroupNetworkParameterKeys.Create.colorIndex] = self.selectedColorIndex
        return params
    }
    
    func validateFields(completion: @escaping responseBlock) {
        if !name.isValidField {
            completion(nil, ValidationErrors.emptyGroupName)
            return
        }
        if !description.isValidField {
            completion(nil, ValidationErrors.emptyGroupDescription)
            return
        }
        if !isEditMode {
            if self.selectedImage == nil {
                completion(nil, ValidationErrors.emptyGroupImage)
                return
            }
            if self.baseColor == nil || self.baseColor == .clear {
                completion(nil, ValidationErrors.emptyGroupBaseColor)
                return
            }
        }
        completion(true, nil)
    }
    
    func tryCreateGroup(completion: @escaping responseBlock) {
        if isEditMode {
            guard hasEditChanged else {
                completion(nil, ValidationErrors.nothingChanged)
                return
            }
            var editParam = toEditParams
            if let img = selectedImage {
                let fileName = UUID().uuidString
                manager.uploadGroupImage(withName: fileName, image: img) { [weak self] (data, err) in
                    guard let self = self else { return }
                    if let error = err {
                        completion(nil, error)
                        return
                    }
                    else {
                        editParam[GroupNetworkParameterKeys.Create.imageName] = data as! String
                        self.manager.editGroup(key: self.group.groupKey!, param: editParam, completion: completion)
                    }
                }
            }
            else {
                manager.editGroup(key: self.group.groupKey!, param: editParam, completion: completion)
            }
        }
        else {
            var createParam = toCreateParams
            if let img = selectedImage {
                let fileName = UUID().uuidString
                manager.uploadGroupImage(withName: fileName, image: img) { [weak self] (data, err) in
                    if let error = err {
                        completion(nil, error)
                        return
                    }
                    else {
                        createParam[GroupNetworkParameterKeys.Create.imageName] = data as! String
                        self?.manager.createGroup(param: createParam, completion: completion)
                    }
                }
            }
            else {
                manager.createGroup(param: createParam, completion: completion)
            }
        }
        
    }
}
