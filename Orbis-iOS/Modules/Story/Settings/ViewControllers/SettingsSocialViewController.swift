//
//  SettingsSocialViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 12/04/2021.
//

import UIKit
import SDWebImage


class SettingsSocialViewController: OrbisLocalizableViewController {
    
    @IBOutlet weak var manageMyGroupsLabel: UILabel!
    @IBOutlet weak var placesYouFollowLabel: UILabel!
    @IBOutlet weak var mySubscriptionsLabel: UILabel!
    @IBOutlet weak var blockedListLabel: UILabel!
    @IBOutlet weak var accountPrivacyLabel: UILabel!
    @IBOutlet weak var makeAccountPrivateLabel: UILabel!
    
    @IBOutlet weak var mainScrollView: UIScrollView!
    
    @IBOutlet weak var myGroupDropDownIndicator: UIImageView!
    @IBOutlet weak var myGroupTableView: UITableView!
    @IBOutlet weak var myGroupsTableHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var mySubscriptionsDropDownIndicator: UIImageView!
    @IBOutlet weak var mySubscriptionsTableView: UITableView!
    @IBOutlet weak var mySubscriptionsTableHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var privacySwitch: UISwitch!
    
    @IBAction func myGroupTapped(_ sender: Any) {
        toggleGroupListVisibility()
    }
    @IBAction func followedPlacesTapped(_ sender: Any) {
        showFollowedPlacesView()
    }
    @IBAction func mySubscriptionsTapped(_ sender: Any) {
        toggleMySubscriptionListVisibility()
    }
    @IBAction func privacyChanged(_ sender: Any) {
        performPrivacyChange()
    }
    @IBAction func blockedListTapped(_ sender: Any) {
        showUserBlockListView()
    }
    
    var viewModel: SettingsSocialViewModel!
    var isGroupListHidden = true
    var isMySubscriptionListHidden = true
    var isPrivacyChangePending = false
    var isAdminGroupLoading = false
    var isUserSubscriptionsLoading = false
    var isUserPurchasesLoading = false
    
    var loaderCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        viewModel = SettingsSocialViewModel()
        updateStaticTexts()
        handleViewModelActions()
        updateViewContent()
        resetAdminGroups()
        loadAdminGroups()
        fetchUserSubscriptions()
        fetchUserPurchases()
    }
    
    deinit {
        guard myGroupTableView != nil else { return }
        myGroupTableView.removeObserver(self, forKeyPath: "contentSize")

        guard mySubscriptionsTableView != nil else { return }
        mySubscriptionsTableView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let obj = object as? UITableView {
            if obj == self.myGroupTableView && keyPath == "contentSize" {
                let newHeight = obj.contentSize.height + CGFloat(10).relativeToIphone8Width()
                myGroupsTableHeightConstraint.constant = newHeight
                myGroupTableView.layoutIfNeeded()
                self.mainScrollView.layoutIfNeeded()
            } else if obj == self.mySubscriptionsTableView && keyPath == "contentSize" {
                let newHeight = obj.contentSize.height + CGFloat(10).relativeToIphone8Width()
                mySubscriptionsTableHeightConstraint.constant = newHeight
                mySubscriptionsTableView.layoutIfNeeded()
                self.mainScrollView.layoutIfNeeded()
            }
        }
    }
    
    override func updateStaticTexts() {
        manageMyGroupsLabel.text = AppStrings.Settings.manageMyGroup
        placesYouFollowLabel.text = AppStrings.Settings.placesYouFollow
        mySubscriptionsLabel.text = AppStrings.Settings.mySubscriptions
        accountPrivacyLabel.text = AppStrings.Settings.placesYouFollow
        makeAccountPrivateLabel.text = AppStrings.Settings.makeAccountPrivate
        blockedListLabel.text = AppStrings.Settings.blockedList
    }
    
    private func tryHideLoader() {
        loaderCount -= 1
        if loaderCount < 0 {
            loaderCount = 0
        }
        guard loaderCount == 0 else { return }
        self.hideOrbisLoader()
    }
    
    
    private func resetAdminGroups() {
        viewModel.initializeAdminGroupPagination()
        isAdminGroupLoading = false
        myGroupTableView.reloadData()
    }
    
    private func loadAdminGroups() {
        isAdminGroupLoading = true
        loaderCount += 1
        self.showOrbisLoader()
        viewModel.loadAdminGroups()
    }
    
    private func loadMoreAdminGroups() {
        guard !isAdminGroupLoading else { return }
        isAdminGroupLoading = true
        loaderCount += 1
        self.showOrbisLoader()
        viewModel.loadMoreAdminGroups()
    }
    
    private func fetchUserSubscriptions() {
        isUserSubscriptionsLoading = true
        loaderCount += 1
        self.showOrbisLoader()
        viewModel.fetchUserSubscriptions()
    }
    
    private func fetchUserPurchases() {
        isUserPurchasesLoading = true
        loaderCount += 1
        self.showOrbisLoader()
        viewModel.fetchUserPurchases()
    }
    
    private func handleViewModelActions() {
        viewModel.onUserDetailUpdateError = {
            [weak self] error in
            self?.handleError(error: error)
            self?.isPrivacyChangePending = false
            self?.tryHideLoader()
        }
        viewModel.onUserDetailUpdateSuccess = {
            [weak self] in
            self?.isPrivacyChangePending = false
            self?.tryHideLoader()
        }
        viewModel.onGroupsFetchError = {
            [weak self] error in
            self?.handleError(error: error)
            self?.isAdminGroupLoading = false
            self?.tryHideLoader()
        }
        viewModel.onGroupsFetched = {
            [weak self] in
            self?.isAdminGroupLoading = false
            self?.tryHideLoader()
            self?.myGroupTableView.reloadData()
        }
        viewModel.onGroupsFetchedCompletePagination = {
            [weak self] in
            self?.isAdminGroupLoading = false
            self?.tryHideLoader()
            self?.myGroupTableView.reloadData()
        }
        
        viewModel.onUserSubscriptionsFetched = {
            [weak self] in
            self?.isUserSubscriptionsLoading = false
            self?.tryHideLoader()
            self?.mySubscriptionsTableView.reloadData()
        }
        viewModel.onUserSubscriptionsFetchError = {
            [weak self] error in
            self?.handleError(error: error)
            self?.isUserSubscriptionsLoading = false
            self?.tryHideLoader()
        }
        
        viewModel.onUserPurchasesFetched = {
            [weak self] in
            self?.isUserPurchasesLoading = false
            self?.tryHideLoader()
            self?.mySubscriptionsTableView.reloadData()
        }
        viewModel.onUserPurchasesFetchError = {
            [weak self] error in
            self?.handleError(error: error)
            self?.isUserPurchasesLoading = false
            self?.tryHideLoader()
        }
        
    }
    
    private func setupTableView() {
        myGroupTableView.delegate = self
        myGroupTableView.dataSource = self
        myGroupTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)

        mySubscriptionsTableView.delegate = self
        mySubscriptionsTableView.dataSource = self
        mySubscriptionsTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    private func updateViewContent() {
        privacySwitch.isOn = viewModel.isAccountPrivate
        updateGroupListVisibility()
        myGroupTableView.reloadData()
    }
    
    private func toggleGroupListVisibility() {
        isGroupListHidden = !isGroupListHidden
        updateGroupListVisibility()
    }
    
    private func updateGroupListVisibility() {
        myGroupTableView.isHidden = isGroupListHidden
        mainScrollView.layoutIfNeeded()
        let angle = isGroupListHidden ? 0 : 180
        UIView.animate(withDuration: 0.15) {
            [weak self] in
            self?.myGroupDropDownIndicator.transform = CGAffineTransform(rotationAngle: angle.toCGFloat.deg2rad)
        } completion: { (true) in
        }
    }
    
    private func showFollowedPlacesView() {
        let userFollowedPagesVC = UIStoryboard.getViewController(inStoryboard: "Settings", identifier: "userFollowedPagesVC") as! SettingsFollowedPlacesListViewController
        let navVC = OrbisNavigationController(rootViewController: userFollowedPagesVC)
        navVC.modalPresentationStyle = .overFullScreen
        presentPanModal(navVC)
    }

    private func toggleMySubscriptionListVisibility() {
        isMySubscriptionListHidden = !isMySubscriptionListHidden
        updateMySubscriptionsListVisibility()
    }

    private func updateMySubscriptionsListVisibility() {
        mySubscriptionsTableView.isHidden = isMySubscriptionListHidden
        mainScrollView.layoutIfNeeded()
        let angle = isMySubscriptionListHidden ? 0 : 180
        UIView.animate(withDuration: 0.15) {
            [weak self] in
            self?.mySubscriptionsDropDownIndicator.transform = CGAffineTransform(rotationAngle: angle.toCGFloat.deg2rad)
        } completion: { (true) in
            self.mySubscriptionsTableView.reloadData()
        }
    }
    
    private func showUserBlockListView() {
        let userBlockedListVC = UIStoryboard.getViewController(inStoryboard: "Settings", identifier: "userBlockedListVC") as! SettingsBlockedListViewController
        let navVC = OrbisNavigationController(rootViewController: userBlockedListVC)
        navVC.modalPresentationStyle = .overFullScreen
        presentPanModal(navVC)
    }
    
    private func showPurchasedItemCodesView(at index: Int) {
        let vc = UIStoryboard.getViewController(inStoryboard: "Settings", identifier: "purchaseCodePopupVC") as! PurchaseCodePopupVC
        let model = viewModel.getPurchaseModel(at: index)
        vc.viewModel = PurchaseCodePopupViewModel(model: model)
        vc.modalPresentationStyle = .overFullScreen
        presentPanModal(vc)
    }

    private func performPrivacyChange() {
        guard !isPrivacyChangePending else { return }
        isPrivacyChangePending = true
        loaderCount += 1
        self.showOrbisLoader()
        viewModel.updateAccountPrivateStatus(value: !viewModel.isAccountPrivate)
    }
    
    private func tryCancelSubscription(at index: Int) {
        showConfirmationAlert(title: "", message: AppStrings.Subscription.unsubscribeConfirmationMessage, okBtnTitle: AppStrings.yes, cancelBtnTitle: AppStrings.no) { [weak self] success in
            if success {
                self?.proceedCancelSubscription(at: index)
            }
        }
    }
    
    private func proceedCancelSubscription(at index: Int) {
        guard let key = viewModel.getSubscriptionModel(at: index).subscriptionKey else { return }
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.cancelSubscription(forSubscription: key) { [weak self] result, error in
            self?.hideOrbisLoader()
            if let error = error {
                self?.handleError(error: error)
            } else {
                DispatchQueue.main.async {
                    self?.mySubscriptionsTableView.reloadData()
                }
            }
        }
    }
}

extension SettingsSocialViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == mySubscriptionsTableView {
            return 2
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0 }
        if tableView == mySubscriptionsTableView {
            if isMySubscriptionListHidden {
                return 0
            } else {
                if section == 1 {
                    return viewModel.purchasesCount
                }
                return viewModel.subscriptionsCount
            }
        } else {
            return viewModel.groupCount
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == mySubscriptionsTableView {
            if indexPath.section == 1 {
                let myPurchaseItemCell = tableView.dequeueReusableCell(withIdentifier: "myPurchaseItemCell") as! SettingsMyPurchaseItemTVC
                myPurchaseItemCell.model = viewModel.getPurchaseModel(at: indexPath.row)
                myPurchaseItemCell.onActionBtnTapped = {
                    [weak self] cell in
                    guard let indexPath = tableView.indexPath(for: cell) else { return }
                    self?.showPurchasedItemCodesView(at: indexPath.row)
                }
                return myPurchaseItemCell
            }
            let subscriptionItemCell = tableView.dequeueReusableCell(withIdentifier: "mySubscriptionItemCell") as! SettingsMySubscriptionItemTableViewCell
            subscriptionItemCell.subscriptionModel = viewModel.getSubscriptionModel(at: indexPath.row)
            subscriptionItemCell.onCancelTapped = {
                [weak self] cell in
                guard let indexPath = tableView.indexPath(for: cell) else { return }
                self?.tryCancelSubscription(at: indexPath.row)
            }
            return subscriptionItemCell
        } else {
            let groupItemCell = tableView.dequeueReusableCell(withIdentifier: "groupItemCell") as! SettingsGroupItemTableViewCell
            groupItemCell.viewModel = GroupItemViewModel(item: viewModel.getGroupModel(at: indexPath.row))
            return groupItemCell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 15.toCGFloat.relativeToIphone8Width()
//    }
//
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let header = UIView()
//        header.backgroundColor = .clear
//        return header
//    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView == mySubscriptionsTableView {

        } else {
            let lastIndex = viewModel.groupCount - 1
            if indexPath.row == lastIndex && !isAdminGroupLoading && !viewModel.hasItemsLastPageReached {
                self.loadMoreAdminGroups()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == mySubscriptionsTableView {

        } else {
            let group = viewModel.getGroupModel(at: indexPath.row)
            openEditGroupView(withModel: group)
        }
    }
    
    private func gotoGroupDetailView(withModel model: Group) {
        let groupDetailsVC = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "groupDetailVC") as! GroupDetailsViewController
        groupDetailsVC.viewModel = GroupDetailViewModel(group: model)
        self.navigationController?.pushViewController(groupDetailsVC, animated: true)
    }
    
    private func openEditGroupView(withModel group: Group) {
        let createGroupView = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "createGroupVC") as! CreateGroupViewController
        createGroupView.viewModel = CreateGroupViewModel(group: group)
        createGroupView.onGroupEdit = {
            [weak self] group in
            self?.viewModel.replaceGroup(group: group)
            self?.myGroupTableView.reloadData()
        }
        self.navigationController?.pushViewController(createGroupView, animated: true)
    }
}
