//
//  GroupSubscriberItemTVC.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 22/08/2023.
//

import UIKit

class GroupSubscriberItemTVC: UITableViewCell {
    static let nibName = "GroupSubscriberItemTVC"
    static let identifier = "groupSubscriberItemTVC"

    @IBOutlet weak var proPicContainerView: RoundedView!
    @IBOutlet weak var proPicView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var codesLabel: UILabel!
    @IBOutlet weak var seeCodesContainer: RoundedView!
    @IBOutlet weak var seeCodesBtn: UIButton!
    
    @IBAction func seeCodesTapped(_ sender: Any) {
        onSeeCodesTapped?(self)
    }
    
    var viewModel: GroupSubscriberItemViewModel! {
        didSet {
            updateViewContent()
        }
    }
    
    var onSeeCodesTapped: ((GroupSubscriberItemTVC) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateViewContent() {
        seeCodesBtn.setTitle(AppStrings.Subscription.seeCodesText, for: .normal)
        nameLabel.text = viewModel.name
        codesLabel.text = "\(AppStrings.Subscription.codeText): \(viewModel.codes.first ?? "")"  
        codesLabel.isHidden = (viewModel.codes.count <= 0) || viewModel.codes.count > 1
        seeCodesBtn.isHidden = viewModel.codes.count <= 1
        descriptionLabel.isHidden = true
        descriptionLabel.text = ""
        updateProfilePic()
    }
    
    private func updateProfilePic() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.propicLink.isEmpty else {
            proPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.propicLink
        
        proPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .profilePictures, sizeModifier: .fourHundred)
    }
    
}
