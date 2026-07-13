//
//  ImagePostImageContentCellCollectionViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 06/05/2021.
//

import UIKit

class ImagePostImageContentCellCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setImage(url: String?, image: UIImage?) {
        if let img = image {
            imageView.image = img
        }
        else {
            let imageLink = url ?? ""
            if imageLink.isNotUrlLink {
                let ref = imageLink.getFirebaseReference(storage: .postImages, imageSizeResolution: .sixEighty)
                imageView.sd_setImage(with: ref, maxImageSize: UInt64(AppValues.thousandHundrenMbInBytes), placeholderImage: nil, options: [.retryFailed])
            }
            else {
                imageView.sd_setImage(with: URL(string: imageLink)!, placeholderImage: nil)
            }
        }
    }

}
