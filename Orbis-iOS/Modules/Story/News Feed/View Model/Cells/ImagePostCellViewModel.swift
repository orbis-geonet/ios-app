//
//  ImagePostCellViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 29/03/2021.
//

import Foundation
import UIKit

class ImagePostCellViewModel: PostCellViewModel {
    var currentPageIndex: Int = 0 {
        didSet {
            onPageIndexChanged?(currentPageIndex)
        }
    }
    var onPageIndexChanged: ((Int) -> Void)?
    
    init(data: OrbisFeedPost, pageIndex: Int) {
        super.init(data: data)
        self.currentPageIndex = pageIndex
    }
    
    var description: String {
        return model.details ?? ""
    }
    
    var mediaUrls: [String] {
        return model.mediaUrls ?? []
    }
    
    var images: [UIImage] {
        return model.pendingPostImages ?? []
    }
    
    var imageCount: Int {
        return isPendingPost ? images.count : mediaUrls.count
    }
    
    func getImage(at index: Int) -> UIImage {
        return images[index]
    }
    
    func getImageLink(at index: Int) -> String {
        return mediaUrls[index]
    }
}
