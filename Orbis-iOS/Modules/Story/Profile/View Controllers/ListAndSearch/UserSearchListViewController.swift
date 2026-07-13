//
//  UserSearchListViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 03/04/2021.
//

import UIKit

class UserSearchListViewController: OrbisLocalizableViewController {

    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var resultTableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func searchTapped(_ sender: Any) {
        searchTextField.becomeFirstResponder()
    }
    
    var viewModel: UserSearchListViewModel!
    var isLoading = false
    var searchTimer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = UserSearchListViewModel(searchText: searchTextField.text ?? "")
        setupTableView()
        handleViewModelActionHandlers()
        resetData()
        updateStaticTexts()
    }
    
    override func updateStaticTexts() {
        searchTextField.placeholder = AppStrings.Profile.searchUsersPlaceholder
        titleLabel.text = AppStrings.Profile.usersTitle
    }
    
    func setupTableView() {
        resultTableView.register(UINib(nibName: "UserSearchItemTableViewCell", bundle: nil), forCellReuseIdentifier: "userItemCell")
        resultTableView.dataSource = self
        resultTableView.delegate = self
        
        searchTextField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
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
        viewModel.onUsersFetched = { [weak self] in
            self?.hideOrbisLoader()
            self?.resultTableView.reloadData()
            self?.isLoading = false
        }
        viewModel.onUsersFetchedCompletePagination = { [weak self] in
            self?.hideOrbisLoader()
            self?.resultTableView.reloadData()
            self?.isLoading = false
        }
        viewModel.onUsersFetchLateResponse = {
            [weak self] in
            self?.hideOrbisLoader()
        }
        viewModel.onUsersFetchError = { [weak self] (error) in
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
            self?.showOrbisLoader()
            self?.viewModel.loadUsers()
        })
    }
}

extension UserSearchListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0}
        return viewModel.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let loadMoreIndex = viewModel.count - 1
        if indexPath.row == loadMoreIndex && !isLoading && !viewModel.hasItemsLastPageReached {
            self.loadMore()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let userItemCell = tableView.dequeueReusableCell(withIdentifier: "userItemCell") as! UserSearchItemTableViewCell
        userItemCell.viewModel = UserItemViewModel(item: viewModel.getUserItem(at: indexPath.row))
        return userItemCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = viewModel.getUserItem(at: indexPath.row)
        gotoUserProfileView(user: user)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15.toCGFloat.relativeToIphone8Width()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear
        return header
    }
    
    private func gotoUserProfileView(user: OrbisUser) {
        if user.deleted == true  {
            UIUtil.showGlobalToast(message: AppStrings.userHasBeenDeleted)
            return
        }
        let userProfileVC = UIStoryboard.getViewController(inStoryboard: "Profile", identifier: "userProfileVC") as! UserProfileViewController
        userProfileVC.viewModel = ProfileDetailViewModel(user: user, isViewingSelf: UserSessionManager.shared.currentUser?.userKey == user.userKey)
        self.navigationController?.pushViewController(userProfileVC, animated: true)
    }
}

