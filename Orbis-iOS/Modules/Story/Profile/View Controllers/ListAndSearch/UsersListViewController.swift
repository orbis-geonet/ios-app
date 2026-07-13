//
//  UsersListViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 25/07/2021.
//

import UIKit

class UsersListViewController: OrbisLocalizableViewController {
    
    @IBOutlet weak var resultTableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    var viewModel: UsersListViewModel!
    var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        updateStaticTexts()
        handleViewModelActionHandlers()
        resetData()
        loadData()
    }
    
    override func updateStaticTexts() {
        titleLabel.text = viewModel.viewTitle
    }
    
    func setupTableView() {
        resultTableView.register(UINib(nibName: "UserSearchItemTableViewCell", bundle: nil), forCellReuseIdentifier: "userItemCell")
        resultTableView.dataSource = self
        resultTableView.delegate = self
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
        viewModel.onUsersFetchError = { [weak self] (error) in
            self?.hideOrbisLoader()
            self?.handleError(error: error)
            self?.isLoading = false
        }
    }
}

extension UsersListViewController: UITableViewDataSource, UITableViewDelegate {
    
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
