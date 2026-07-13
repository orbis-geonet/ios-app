//
//  SettingsBlockedListViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 08/11/2021.
//

import UIKit

class SettingsBlockedListViewController: OrbisLocalizableViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var resultView: UITableView!
    
    @IBAction func backTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func searchIconTapped(_ sender: Any) {
        searchTextField.becomeFirstResponder()
    }
    
    var viewModel: UserBlockListViewModel!
    var isLoading = false
    var searchTimer = Timer()
    
    override func topOffset() -> CGFloat {
        return 0
    }
    
    override func showDragIndicator() -> Bool {
        return false
    }

    override func shouldRespond(toPanModalGestureRecognizer panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        let panGesturePoint = panGestureRecognizer.location(in: self.view)
        if resultView.frame.contains(panGesturePoint) {
            return resultView.contentOffset.y <= 0
        }
        return true
    }
    
    override func isAutoHandleKeyboardEnabled() -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = UserBlockListViewModel()
        setupTableView()
        updateStaticTexts()
        handleViewModelActionHandlers()
        resetData()
        loadData()
    }
    
    override func updateStaticTexts() {
        titleLabel.text = AppStrings.Settings.blockedList
        searchTextField.placeholder = AppStrings.Profile.searchUsersPlaceholder
    }
    
    func setupTableView() {
        resultView.dataSource = self
        resultView.delegate = self
        
        searchTextField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
    }
    
    func resetData() {
        viewModel.initializePagination()
        isLoading = false
        resultView.reloadData()
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
            self?.resultView.reloadData()
            self?.isLoading = false
        }
        viewModel.onUsersFetchedCompletePagination = { [weak self] in
            self?.hideOrbisLoader()
            self?.resultView.reloadData()
            self?.isLoading = false
        }
        viewModel.onUsersFetchError = { [weak self] (error) in
            self?.hideOrbisLoader()
            self?.handleError(error: error)
            self?.isLoading = false
        }
    }
    
    private func tryUnblockUser(user: OrbisUser) {
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.unblockUser(user: user) { [weak self] data, err in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.resultView.reloadData()
            }
            self?.hideOrbisLoader()
        }
    }
    
    // MARK:- Text Field Delegate methods
    
    @objc private func textDidChange(_ textField: UITextField) {
        searchTimer.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { (timer) in
            // implement search later
        })
    }
}

extension SettingsBlockedListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0}
        return viewModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewModel.getUserItem(at: indexPath.row)
        let cell = tableView.dequeueReusableCell(withIdentifier: "userItemCell") as! SettingBlockedUserItemTableViewCell
        cell.viewModel = UserItemViewModel(item: model)
        cell.onUnblockTapped = {
            [weak self] user in
            self?.tryUnblockUser(user: user)
        }
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastIndex = viewModel.count - 1
        if indexPath.row == lastIndex && !isLoading && !viewModel.hasItemsLastPageReached {
            loadMore()
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
}
