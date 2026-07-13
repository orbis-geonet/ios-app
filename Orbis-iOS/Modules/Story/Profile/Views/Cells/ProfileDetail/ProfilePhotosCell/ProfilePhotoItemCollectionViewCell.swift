//
//  ProfilePhotoItemCollectionViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 02/04/2021.
//

import UIKit
import SDWebImage


class ProfilePhotoItemCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var multiItemIndicatorView: UIImageView!
    
    var viewModel: ProfilePhotoItemViewModel! {
        didSet {
            updateViewContent()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func updateViewContent() {
        photoView.image = nil
        setImage(url: viewModel.imageLink, image: viewModel.image)
        self.contentView.alpha = viewModel.isPendingMedia ? 0.5 : 1
        self.multiItemIndicatorView.isHidden = viewModel.count <= 1
    }
    
    private func setImage(url: String?, image: UIImage?) {
        if let img = image {
            photoView.image = img
        }
        else {
            guard !viewModel.imageLink.isEmpty else {
                return
            }
            let imageLink = url ?? ""
            if imageLink.isNotUrlLink {
                let ref = imageLink.getFirebaseReference(storage: .userProfilePhotos, imageSizeResolution: .sixEighty)
                photoView.sd_setImage(with: ref, maxImageSize: UInt64(AppValues.thousandHundrenMbInBytes), placeholderImage: nil, options: [.retryFailed])
            }
            else {
                photoView.sd_setImage(with: URL(string: imageLink)!, placeholderImage: nil)
            }
        }
    }
}
