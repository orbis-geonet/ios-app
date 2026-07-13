//
//  GroupMemberActionViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 01/09/2021.
//

import UIKit

protocol GroupAdminsListFetchDataSource: AnyObject {
    func getAdminsList() -> [String]
    func getBannedUsersList() -> [String]
    func makeRemoveAdminRequest(forUser user: OrbisUser, completion: @escaping responseBlock)
    func banUnbanUserFromGroup(user: OrbisUser, completion: @escaping responseBlock)
}

class GroupMemberActionViewController: PopupViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var makeRemoveAdminView: UIView!
    @IBOutlet weak var makeRemoveAdminLabel: UILabel!
    @IBOutlet weak var banUserView: UIView!
    @IBOutlet weak var banUserLabel: UILabel!
    
    weak var adminsListFetchDataSource: GroupAdminsListFetchDataSource?
    
    @IBAction func makeRemoveAdminTapped(_ sender: Any) {
        self.dismiss(animated: true) {
            [weak self] in
            guard let self = self else { return }
            self.onMakeRemoveAdminTapped?(self.user)
        }
    }
    
    @IBAction func banUserTapped(_ sender: Any) {
        self.dismiss(animated: true) {
            [weak self] in
            guard let self = self else { return }
            self.onBanUserTapped?(self.user)
        }
    }
    
    var onMakeRemoveAdminTapped: ((OrbisUser) -> Void)?
    var onBanUserTapped: ((OrbisUser) -> Void)?
    var user: OrbisUser!
    var group: Group!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    func setupView() {
        titleLabel.text = AppStrings.selectOption
        guard let _ = UserSessionManager.shared.currentUser else {
            dismissView()
            return
        }
        guard group.isAdmin == true else {
            dismissView()
            return
        }
        let adminKeys = adminsListFetchDataSource?.getAdminsList() ?? []
        let bannedKeys = adminsListFetchDataSource?.getBannedUsersList() ?? []
        var adminLabelText = "\(AppStrings.Group.GroupMemberAction.make) \(user.userDisplayName ?? "\(AppStrings.user)") \(AppStrings.Group.GroupMemberAction.admin)"
        if adminKeys.contains(where: {$0 == user.userKey}) {
            adminLabelText = "\(AppStrings.Group.GroupMemberAction.remove) \(user.userDisplayName ?? "\(AppStrings.user)") \(AppStrings.Group.GroupMemberAction.fromAdmin)"
        }
        var banLabelText = "\(AppStrings.Group.GroupMemberAction.ban) \(user.userDisplayName ?? "\(AppStrings.user)")"
        if bannedKeys.contains(where: {$0 == user.userKey}) {
            banLabelText = "\(AppStrings.Group.GroupMemberAction.unban) \(user.userDisplayName ?? "\(AppStrings.user)")"
        }
        banUserLabel.text = banLabelText
        makeRemoveAdminLabel.text = adminLabelText
    }
    
    private func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }
}
