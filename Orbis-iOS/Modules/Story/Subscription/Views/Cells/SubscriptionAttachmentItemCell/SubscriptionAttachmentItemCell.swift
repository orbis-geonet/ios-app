//
//  SubscriptionAttachmentItemCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 20/08/2023.
//

import UIKit

struct SubscriptionImage {
    var image: UIImage?
    var imageKey: String?
}

class SubscriptionAttachmentItemCell: UICollectionViewCell {
    static let nibName = "SubscriptionAttachmentItemCell"
    static let identifier = "subscriptionAttachmentItemCell"
    
    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var removeBtnContainer: RoundedView!
    
    @IBAction func removeTapped(_ sender: Any) {
        onRemoveTapped?(self)
    }
    
    var model: SubscriptionImage? {
        didSet {
            updateContent()
        }
    }
    var hideRemoveBtn: Bool = false {
        didSet {
            removeBtnContainer.isHidden = hideRemoveBtn
        }
    }
    var onRemoveTapped: ((SubscriptionAttachmentItemCell) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    private func updateContent() {
        if let img = model?.image {
            contentImageView.image = img
        }
        else {
            let imageLink = model?.imageKey ?? ""
            if imageLink.isNotUrlLink {
                let ref = imageLink.getFirebaseReference(storage: .subscriptionImages, imageSizeResolution: .sixEighty)
                contentImageView.sd_setImage(with: ref, maxImageSize: UInt64(AppValues.thousandHundrenMbInBytes), placeholderImage: nil, options: [.retryFailed])
            }
            else {
                contentImageView.sd_setImage(with: URL(string: imageLink)!, placeholderImage: nil)
            }
        }
    }
}
