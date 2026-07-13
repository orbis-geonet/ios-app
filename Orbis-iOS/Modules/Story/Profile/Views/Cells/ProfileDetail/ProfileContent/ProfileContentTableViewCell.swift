//
//  ProfileContentTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 01/04/2021.
//

import UIKit

class ProfileContentTableViewCell: UITableViewCell {

    weak var parallexScrollDelegate: OrbisParallexScrollDelegate?
    weak var modelDataSource: ProfileViewModelDataSource?
    var profileContentTabVC: UserProfileDetailsTabViewController!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func addTabContentView() {
        profileContentTabVC = UserProfileDetailsTabViewController()
        profileContentTabVC.parallexScrollDelegate = parallexScrollDelegate
        profileContentTabVC.modelDataSource = modelDataSource
        let tabView = profileContentTabVC.view!
        self.contentView.addSubview(tabView)
        tabView.translatesAutoresizingMaskIntoConstraints = false
        tabView.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        tabView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        tabView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        tabView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
