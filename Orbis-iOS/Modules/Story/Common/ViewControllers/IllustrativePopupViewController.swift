//
//  IllustrativePopupViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 05/01/2023.
//

import UIKit

class IllustrativePopupViewController: PopupViewController {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var understoodBtn: UIButton!
    
    var type: IllustrativePopupType!
    
    @IBAction func understoodTapped(_ sender: Any) {
        self.dismiss(animated: true) {
            [weak self] in
            self?.onUnderstoodTapped?()
        }
    }
    
    @IBAction func backTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var onUnderstoodTapped: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateStaticTexts()
    }

    override func updateStaticTexts() {
        imageView.image = type.illustrationImage
        messageLabel.text = type.description
        understoodBtn.setTitle(type.confirmBtnText, for: .normal)
    }
}

enum IllustrativePopupType: String {
    case adminSubscriptionCreation = "admin_create_subscription_illus"
    case userSubscriptionFeature = "normal_user_subscription_illus"
    
    var illustrationImage: UIImage? {
        return UIImage(named: self.rawValue)
    }
    
    var description: String {
        switch(self) {
        case .adminSubscriptionCreation:
            return AppStrings.Subscription.IllustrativePopup.groupAdminCreateSubscriptionPopupMsg
        case .userSubscriptionFeature:
            return AppStrings.Subscription.IllustrativePopup.userSubscriptionFeaturePopupMsg
        }
    }
    
    var confirmBtnText: String {
        switch(self) {
        case .adminSubscriptionCreation:
            return AppStrings.understood
        case .userSubscriptionFeature:
            return AppStrings.understood
        }
    }
}
