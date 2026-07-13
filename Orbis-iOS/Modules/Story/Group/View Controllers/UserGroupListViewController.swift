//
//  UserGroupListViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 25/07/2021.
//

import UIKit

class UserGroupListViewController: OrbisLocalizableViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var resultTableView: UITableView!
    
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func searchTapped(_ sender: Any) {
        searchTextField.becomeFirstResponder()
    }
    
    var viewModel: UserGroupListViewModel!
    var isLoading = false
    var searchTimer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        handleViewModelActionHandlers()
        resetData()
        loadData()
        updateStaticTexts()
    }
    
    override func updateStaticTexts() {
        titleLabel.text = AppStrings.Group.groups
        searchTextField.placeholder = AppStrings.Group.searchGroupPlaceholder
    }
    
    func setupTableView() {
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
        viewModel.loadGroups()
    }
    
    func loadMore() {
        isLoading = true
        self.showOrbisLoader()
        viewModel.loadMoreGroups()
    }
    
    private func handleViewModelActionHandlers() {
        viewModel.onGroupsFetched = { [weak self] in
            self?.hideOrbisLoader()
            self?.resultTableView.reloadData()
            self?.isLoading = false
        }
        viewModel.onGroupsFetchedCompletePagination = { [weak self] in
            self?.hideOrbisLoader()
            self?.resultTableView.reloadData()
            self?.isLoading = false
        }
        viewModel.onGroupsFetchLateResponse = {
            [weak self] in
            self?.hideOrbisLoader()
        }
        viewModel.onGroupsFetchError = { [weak self] (error) in
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

extension UserGroupListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard isViewLoaded else { return 0 }
        guard viewModel != nil else { return 0}
        return viewModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let groupItemCell = tableView.dequeueReusableCell(withIdentifier: "groupItemCell") as! GroupListItemTableViewCell
        groupItemCell.viewModel = GroupItemViewModel(item: viewModel.getGroupItem(at: indexPath.row))
        return groupItemCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 105.toCGFloat.relativeToIphone8Width()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = .clear
        return footer
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15.toCGFloat.relativeToIphone8Width()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear
        return header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let group = viewModel.getGroupItem(at: indexPath.row)
        gotoGroupDetailView(withModel: group)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let loadMoreIndex = viewModel.count - 1
        if indexPath.row == loadMoreIndex && !isLoading && !viewModel.hasItemsLastPageReached {
            self.loadMore()
        }
    }
    
    private func gotoGroupDetailView(withModel model: Group) {
        let groupDetailsVC = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "groupDetailVC") as! GroupDetailsViewController
        groupDetailsVC.viewModel = GroupDetailViewModel(group: model)
        self.navigationController?.pushViewController(groupDetailsVC, animated: true)
    }
}
