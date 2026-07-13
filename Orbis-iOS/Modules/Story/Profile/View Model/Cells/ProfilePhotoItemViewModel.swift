//
//  ProfilePhotoItemViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 02/04/2021.
//

import Foundation
import UIKit

class ProfilePhotoItemViewModel {
    var model: UserProfileMedia!
    
    init(model: UserProfileMedia) {
        self.model = model
    }
    
    var imageLink: String {
        return model.pictureUrl?.first ?? ""
    }
    
    var image: UIImage? {
        if let data = model.pendingImagesData?.first {
            return UIImage(data: data)
        }
        return nil
    }
    
    var isPendingMedia: Bool {
        return model.pendingImagesData?.count ?? 0 > 0
    }
    
    var count: Int {
        if let data = model.pendingImagesData {
            return data.count
        }
        return model.pictureUrl?.count ?? 0
    }
}
