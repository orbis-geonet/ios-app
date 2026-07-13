//
//  SubscriptionMembersViewController.swift
//  Orbis-iOS
//
//  Created by Vikas Sharma on 05/11/22.
//

import UIKit

class SubscriptionMembersViewController: OrbisLocalizableViewController {

    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var resultTableView: UITableView!

    var viewModel: SubscriptionMembersViewModel!
    var isLoading = false
    var searchTimer = Timer()
    
    weak var navDelegate: SubscriptionActivityPageNavigationDelegate?
    var ignoreRefreshData = false

    override func viewDidLoad() {
        super.viewDidLoad()
        handleViewModelActionHandlers()
        setupTableView()
        updateStaticTexts()
        resetData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !ignoreRefreshData else {
            ignoreRefreshData = false
            return
        }
        loadData()
    }

    override func updateStaticTexts() {
        searchTextField.placeholder = AppStrings.search
    }
    
    private func configureViewComponents() {
        if let tabManVC = self.tabmanParent as? SubscriptionActivityTabViewController {
            tabManVC.onFirstFetchComplete = {
                [weak self] in
                if tabManVC.currentIndex == 0 {
                    self?.loadData()
                }
            }
        }
    }

    func setupTableView() {
        resultTableView.register(UINib(nibName: GroupSubscriberItemTVC.nibName, bundle: nil), forCellReuseIdentifier: GroupSubscriberItemTVC.identifier)
        resultTableView.dataSource = self
        resultTableView.delegate = self
        resultTableView.reloadData()
        searchTextField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
    }

    func resetData() {
        viewModel.initializePagination()
        isLoading = false
        resultTableView.reloadData()
    }

    func loadData() {
        viewModel.subscription = navDelegate?.getCurrentSelectedSubscriptionModel()
        isLoading = true
        self.showOrbisLoader()
        viewModel.loadSubscribers()
    }

    func loadMore() {
        isLoading = true
        self.showOrbisLoader()
        viewModel.loadMoreSubscribers()
    }

    private func handleViewModelActionHandlers() {
        viewModel.onSubscribersFetched = { [weak self] in
            self?.hideOrbisLoader()
            self?.resultTableView.reloadData()
            self?.isLoading = false
        }
        viewModel.onSubscribersFetchedCompletePagination = { [weak self] in
            self?.hideOrbisLoader()
            self?.resultTableView.reloadData()
            self?.isLoading = false
        }
        viewModel.onSubscribersFetchLateResponse = {
            [weak self] in
            self?.hideOrbisLoader()
        }
        viewModel.onSubscribersFetchError = { [weak self] (error) in
            self?.hideOrbisLoader()
            self?.handleError(error: error)
            self?.isLoading = false
        }
    }
    
    private func showPurchasedItemCodesView(at index: Int) {
        guard index < viewModel.count else { return }
        let vc = UIStoryboard.getViewController(inStoryboard: "Settings", identifier: "purchaseCodePopupVC") as! PurchaseCodePopupVC
        let model = viewModel.getUser(at: index)
        var purchaseModel = UserPurchaseModel()
        purchaseModel.codes = model.codes
        vc.viewModel = PurchaseCodePopupViewModel(model: purchaseModel)
        vc.modalPresentationStyle = .overFullScreen
        ignoreRefreshData = true
        presentPanModal(vc)
    }

    // MARK:- Text Field Delegate methods

    @objc private func textDidChange(_ textField: UITextField) {
        searchTimer.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { [weak self] (timer) in
            self?.viewModel.searchText = textField.text ?? ""
            self?.resultTableView.reloadData()
        })
    }
}

extension SubscriptionMembersViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0 }
        return viewModel.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < viewModel.count else { return UITableViewCell() }
        
        let groupItemCell = tableView.dequeueReusableCell(withIdentifier: GroupSubscriberItemTVC.identifier) as! GroupSubscriberItemTVC
        let user = viewModel.getUser(at: indexPath.row)
        groupItemCell.viewModel = GroupSubscriberItemViewModel(model: user)
        groupItemCell.onSeeCodesTapped = {
            [weak self] cell in
            guard let indexPath = tableView.indexPath(for: cell) else { return }
            self?.showPurchasedItemCodesView(at: indexPath.row)
        }
        return groupItemCell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < viewModel.count else { return }
        let user = viewModel.getUser(at: indexPath.row)
        gotoUserProfileView(user: user.toUser)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 5.toCGFloat.relativeToIphone8Width()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear
        return header
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard viewModel.searchText.isEmpty else { return }
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
}
