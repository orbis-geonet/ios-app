//
//  ChatImageSentTVC.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 29/07/2021.
//

import UIKit

class ChatImageSentTVC: UITableViewCell {
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageImageView: UIImageView!
    
    var viewModel: ChatMessageViewModel! {
        didSet {
            updateViewContent()
        }
    }
    var onImageTapped: ((String) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapImageView(_:)))
        messageImageView.isUserInteractionEnabled = true
        messageImageView.addGestureRecognizer(tapGesture)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc private func didTapImageView(_ sender: UIImageView) {
        guard !viewModel.mediaUrl.isEmpty else { return }
        onImageTapped?(viewModel.mediaUrl)
    }
    
    func updateViewContent() {
        dayLabel.isHidden = !viewModel.shouldShowDay
        dayLabel.text = viewModel.dateString
        timeLabel.text = viewModel.timeString
        setImage()
    }

    func setImage() {
        if let imgData = viewModel.pendingImageData {
            messageImageView.image = UIImage(data: imgData)
        }
        else {
            let imageLink = viewModel.mediaUrl
            if imageLink.isNotUrlLink {
                let ref = imageLink.getFirebaseReference(storage: .conversationImages, imageSizeResolution: .sixEighty)
                messageImageView.sd_setImage(with: ref, maxImageSize: UInt64(AppValues.thousandHundrenMbInBytes), placeholderImage: nil, options: [.retryFailed])
            }
            else {
                messageImageView.sd_setImage(with: URL(string: imageLink)!, placeholderImage: nil)
            }
        }
    }
}
