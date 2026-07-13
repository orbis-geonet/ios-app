//
//  PrivateProfileLockTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/08/2021.
//

import UIKit

class PrivateProfileLockTableViewCell: UITableViewCell {
    @IBOutlet weak var lockIconView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateStaticTexts()
        addLanguageUpdateObserver()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func addLanguageUpdateObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateLanguage), name: NSNotification.Name(rawValue: AppNotificationKeys.userLanguageDidUpdate), object: nil)
    }
    
    @objc private func didUpdateLanguage(_ notification: NSNotification) {
        updateStaticTexts()
    }

    func updateStaticTexts() {
        titleLabel.text = AppStrings.Profile.privateAccountTitle
        messageLabel.text = AppStrings.Profile.privateAccountMessage
    }
}
