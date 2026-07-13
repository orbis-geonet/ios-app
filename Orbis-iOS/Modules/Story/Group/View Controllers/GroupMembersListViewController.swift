//
//  GroupMembersListViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 03/05/2021.
//

import UIKit

enum GroupMembersListType {
    case membersList
    case newAdminAssign
}

class GroupMembersListViewController: OrbisLocalizableViewController {

    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var resultTableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func searchTapped(_ sender: Any) {
        searchTextField.becomeFirstResponder()
    }
    
    var viewModel: GroupMembersListViewModel!
    var listType: GroupMembersListType! = .membersList
    var isLoading = false
    var searchTimer = Timer()
    var onNewAdminSelection: ((OrbisUser) -> Void)?
    weak var groupAdminListDataSource: GroupAdminsListFetchDataSource?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        handleViewModelActionHandlers()
        resetData()
        loadData()
        updateStaticTexts()
    }
    
    override func updateStaticTexts() {
        titleLabel.text = AppStrings.Group.members
        searchTextField.placeholder = AppStrings.search
    }
    
    func setupTableView() {
        resultTableView.register(UINib(nibName: "UserSearchItemTableViewCell", bundle: nil), forCellReuseIdentifier: "userItemCell")
        resultTableView.dataSource = self
        resultTableView.delegate = self
        resultTableView.reloadData()
        searchTextField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleCellLongPress(sender:)))
        resultTableView.addGestureRecognizer(longTapGesture)
    }
    
    @objc private func handleCellLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: resultTableView)
            if let indexPath = resultTableView.indexPathForRow(at: touchPoint) {
                let model = viewModel.getUser(at: indexPath.row)
                guard let user = UserSessionManager.shared.currentUser else { return }
                guard (user.userKey != model.userKey) else { return }
                showMemberActionView(user: model)
            }
        }
    }
    
    func resetData() {
        viewModel.initializePagination()
        isLoading = false
        resultTableView.reloadData()
    }
    
    func loadData() {
        isLoading = true
        self.showOrbisLoader()
        viewModel.loadUsers()
    }
    
    func loadMore() {
        isLoading = true
        self.showOrbisLoader()
        viewModel.loadMoreUsers()
    }
    
    private func handleViewModelActionHandlers() {
        viewModel.onGroupMembersFetched = { [weak self] in
            self?.hideOrbisLoader()
            self?.resultTableView.reloadData()
            self?.isLoading = false
        }
        viewModel.onGroupMembersFetchedCompletePagination = { [weak self] in
            self?.hideOrbisLoader()
            self?.resultTableView.reloadData()
            self?.isLoading = false
        }
        viewModel.onGroupMembersFetchLateResponse = {
            [weak self] in
            self?.hideOrbisLoader()
        }
        viewModel.onGroupMembersFetchError = { [weak self] (error) in
            self?.hideOrbisLoader()
            self?.handleError(error: error)
            self?.isLoading = false
        }
    }
    
    // MARK:- Text Field Delegate methods
    
    @objc private func textDidChange(_ textField: UITextField) {
        searchTimer.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { [weak self] (timer) in
            self?.resetData()
            self?.viewModel.searchText = textField.text ?? ""
            self?.loadData()
        })
    }
}

extension GroupMembersListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0}
        return viewModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let groupAdmins = self.groupAdminListDataSource?.getAdminsList() ?? []
        let bannedUsers = self.groupAdminListDataSource?.getBannedUsersList() ?? []
        let groupItemCell = tableView.dequeueReusableCell(withIdentifier: "userItemCell") as! UserSearchItemTableViewCell
        let user = viewModel.getUser(at: indexPath.row)
        groupItemCell.viewModel = UserItemViewModel(item: user)
        groupItemCell.setAdminIndicatorVisibility(visible: groupAdmins.contains(where: {$0 == user.userKey}))
        groupItemCell.setBannedIconVisibility(visible: bannedUsers.contains(where: {$0 == user.userKey}))
        return groupItemCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = viewModel.getUser(at: indexPath.row)
        if listType == .membersList {
            gotoUserProfileView(user: user)
        }
        else if listType == .newAdminAssign {
            guard !(self.groupAdminListDataSource?.getAdminsList() ?? []).contains(where: {$0 == user.userKey}) else { return }
            self.showConfirmationAlert(title: AppStrings.ConfirmationPopup.confirmAssign, message: "\(AppStrings.ConfirmationPopup.assignMemberAdminPrefix) \(user.userDisplayName ?? "\(AppStrings.thisUser)") \(AppStrings.ConfirmationPopup.assignMemberAdminPostfix)", okBtnTitle: AppStrings.yes, cancelBtnTitle: AppStrings.no) { [weak self] (success) in
                if success {
                    self?.onNewAdminSelection?(user)
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15.toCGFloat.relativeToIphone8Width()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear
        return header
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let loadMoreIndex = viewModel.count - 1
        if indexPath.row == loadMoreIndex && !isLoading && !viewModel.hasItemsLastPageReached {
            self.loadMore()
        }
    }
    
    private func gotoUserProfileView(user: OrbisUser) {
        if user.deleted == true  {
            UIUtil.showGlobalToast(message: AppStrings.userHasBeenDeleted)
            return
        }
        let userProfileVC = UIStoryboard.getViewController(inStoryboard: "Profile", identifier: "userProfileVC") as! UserProfileViewController
        let isViewingSelf = user.userKey == UserSessionManager.shared.currentUser?.userKey
        userProfileVC.viewModel = ProfileDetailViewModel(user: user, isViewingSelf: isViewingSelf)
        self.navigationController?.pushViewController(userProfileVC, animated: true)
    }
    
    private func showMemberActionView(user: OrbisUser) {
        guard let _ = UserSessionManager.shared.currentUser else {
            return
        }
        guard viewModel.group.isAdmin == true else {
            return
        }
        let groupMemberActionVC = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "groupMemberActionVC") as! GroupMemberActionViewController
        groupMemberActionVC.modalPresentationStyle = .overCurrentContext
        groupMemberActionVC.adminsListFetchDataSource = self
        groupMemberActionVC.shouldAddFullOverlay = true
        groupMemberActionVC.shouldDismissViewOnTapOutside = true
        groupMemberActionVC.group = viewModel.group
        groupMemberActionVC.user = user
        groupMemberActionVC.onMakeRemoveAdminTapped = {
            [weak self] user in
            self?.performMaKeRemoveAdmin(forUser: user)
        }
        groupMemberActionVC.onBanUserTapped = {
            [weak self] user in
            self?.banUnbanUserFromGroup(user: user)
        }
        present(groupMemberActionVC, animated: true, completion: nil)
    }
    
    private func banUnbanUserFromGroup(user: OrbisUser) {
        self.showOrbisLoader(disableUserInteraction: true)
        groupAdminListDataSource?.banUnbanUserFromGroup(user: user, completion: { [weak self] data, err in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.resultTableView.reloadData()
            }
            self?.hideOrbisLoader()
        })
    }
    
    private func performMaKeRemoveAdmin(forUser user: OrbisUser) {
        self.showOrbisLoader(disableUserInteraction: true)
        groupAdminListDataSource?.makeRemoveAdminRequest(forUser: user, completion: { [weak self] data, err in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.resultTableView.reloadData()
            }
            self?.hideOrbisLoader()
        })
    }
}

extension GroupMembersListViewController: GroupAdminsListFetchDataSource {
    func makeRemoveAdminRequest(forUser user: OrbisUser, completion: @escaping responseBlock) {
    }
    
    func banUnbanUserFromGroup(user: OrbisUser, completion: @escaping responseBlock) {
    }
    
    func getAdminsList() -> [String] {
        return self.groupAdminListDataSource?.getAdminsList() ?? []
    }
    
    func getBannedUsersList() -> [String] {
        return self.groupAdminListDataSource?.getBannedUsersList() ?? []
    }
}
