//
//  SearchGroupViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 07/04/2021.
//

import UIKit

class SearchGroupViewController: OrbisLocalizableViewController {

    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var groupListView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    
    
    @IBAction func backTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func searchIconTapped(_ sender: Any) {
        searchTextField.becomeFirstResponder()
    }
    
    var onGroupSelect: ((Group) -> Void)?
    
    override func topOffset() -> CGFloat {
        return 0
    }
    
    override func showDragIndicator() -> Bool {
        return false
    }
    
    override func isAutoHandleKeyboardEnabled() -> Bool {
        return false
    }

    override func shouldRespond(toPanModalGestureRecognizer panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        let panGesturePoint = panGestureRecognizer.location(in: self.view)
        if groupListView.frame.contains(panGesturePoint) {
            return groupListView.contentOffset.y <= 0
        }
        return true
    }
    
    var viewModel: GroupListViewModel!
    var isLoading = false
    var searchTimer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchTextField.text = viewModel.searchText
        setupTableView()
        handleViewModelActionHandlers()
        resetData()
        loadData()
        updateStaticTexts()
    }
    
    override func updateStaticTexts() {
        titleLabel.text = AppStrings.search
        searchTextField.placeholder = AppStrings.Group.searchGroupPlaceholder
    }
    
    func setupTableView() {
        groupListView.dataSource = self
        groupListView.delegate = self
        
        searchTextField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
    }
    
    func resetData() {
        viewModel.initializePagination()
        isLoading = false
        groupListView.reloadData()
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
        viewModel.onGroupsRankingFetched = { [weak self] in
            self?.hideOrbisLoader()
            self?.groupListView.reloadData()
            self?.isLoading = false
        }
        viewModel.onGroupsFetched = { [weak self] in
            self?.hideOrbisLoader()
            self?.groupListView.reloadData()
            self?.isLoading = false
        }
        viewModel.onGroupsFetchedCompletePagination = { [weak self] in
            self?.hideOrbisLoader()
            self?.groupListView.reloadData()
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
            self?.showOrbisLoader()
            self?.viewModel.loadGroups()
        })
    }
}

extension SearchGroupViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0}
        return viewModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let groupItemCell = tableView.dequeueReusableCell(withIdentifier: "groupItemCell") as! SearchedGroupItemTableViewCell
        groupItemCell.viewModel = GroupItemViewModel(item: viewModel.getGroupItem(at: indexPath.row))
        return groupItemCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let group = viewModel.getGroupItem(at: indexPath.row)
        self.dismiss(animated: true) { [weak self] in
            self?.onGroupSelect?(group)
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
