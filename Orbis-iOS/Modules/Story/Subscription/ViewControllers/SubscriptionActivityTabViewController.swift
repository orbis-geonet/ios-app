//
//  SubscriptionActivityTabViewController.swift
//  Orbis-iOS
//
//  Created by Vikas Sharma on 05/11/22.
//

import UIKit
import Tabman
import Pageboy

protocol SubscriptionActivityPageNavigationDelegate: AnyObject {
    func gotoPage(at index: Int) -> Bool
    func getCurrentIndex() -> Int
    func getMaxIndex() -> Int
    func getCurrentSelectedSubscriptionModel() -> GroupSubscriptionModel?
}

class SubscriptionActivityTabViewController: OrbisTabmanViewController {

    fileprivate var viewControllers = [UIViewController]()
    fileprivate var viewControllerIdentites = [String]()
    
    var viewModel: SubscriptionActivityViewModel!
    var isLoading = false
    
    var onFirstFetchComplete: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.isScrollEnabled = false
        initializeTabViewControllers()
        addLanguageUpdateObserver()
        setupTabBar()
        handleViewModelActionHandlers()
        reloadData()
        resetData()
        loadData()
    }

    private func initializeTabViewControllers() {
        let subscriptionManagementVC = UIStoryboard.getViewController(inStoryboard: "Subscription", identifier: "subscriptionManagementVC") as! SubscriptionManagementViewController
        subscriptionManagementVC.navDelegate = self
        subscriptionManagementVC.viewModel = SubscriptionManagementViewModel(group: viewModel.groupModel)

        let subscriptionMembersVC = UIStoryboard.getViewController(inStoryboard: "Subscription", identifier: "subscriptionMembersVC") as! SubscriptionMembersViewController
        subscriptionMembersVC.navDelegate = self
        subscriptionMembersVC.viewModel = SubscriptionMembersViewModel(group: viewModel.groupModel)

        viewControllers = [subscriptionManagementVC, subscriptionMembersVC]
        viewControllerIdentites = [AppStrings.Subscription.Activity.Tabs.management, AppStrings.Subscription.Activity.Tabs.clients]
    }

    private func addLanguageUpdateObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateLanguage), name: NSNotification.Name(rawValue: AppNotificationKeys.userLanguageDidUpdate), object: nil)
    }

    @objc private func didUpdateLanguage(_ notification: NSNotification) {
        guard viewControllerIdentites.count > 0 else { return }
        changeTitle(forId: 0, text: AppStrings.Subscription.Activity.Tabs.management)
        changeTitle(forId: 1, text: AppStrings.Subscription.Activity.Tabs.clients)
    }
    
    private func handleViewModelActionHandlers() {
        viewModel.onGroupSubscriptionsFetched = { [weak self] firstLoad in
            self?.hideOrbisLoader()
            self?.isLoading = false
            if(firstLoad) {
                self?.onFirstFetchComplete?()
            }
        }
        viewModel.onGroupSubscriptionsFetchedCompletePagination = { [weak self] in
            self?.hideOrbisLoader()
            self?.isLoading = false
        }
        viewModel.onGroupSubscriptionsFetchError = { [weak self] (error) in
            self?.hideOrbisLoader()
            self?.handleError(error: error)
            self?.isLoading = false
        }
    }

    private func setupTabBar() {
        let bar = OrbisTMBarButton()
        bar.layout.contentMode = .fit
        bar.indicator.weight = .light
        bar.indicator.tintColor = UIColor(named: AppColors.appBlack.rawValue)
        bar.indicator.cornerStyle = .eliptical
        bar.layout.view.backgroundColor = .white
        bar.layout.transitionStyle = .snap
        bar.backgroundView.style = .flat(color: UIColor.white)
        bar.buttons.customize { (button) in
            button.font = UIFont(name: "Roboto-Black", size: CGFloat(16).relativeToIphone8Width())!
            button.tintColor = UIColor(named: AppColors.appWarmGray2.rawValue)
            button.selectedTintColor = UIColor(named: AppColors.appBlack.rawValue)
        }
        addBar(bar, dataSource: self, at: .top)
    }
    
    // MARK: - View Action Methods
    
    func resetData() {
        viewModel.initializePagination()
        isLoading = false
    }
    
    func loadData() {
        isLoading = true
        self.showOrbisLoader()
        viewModel.loadGroupSubscriptions()
    }
    
    func loadMore() {
        isLoading = true
        viewModel.loadMoreGroupSubscriptions()
    }
}

extension SubscriptionActivityTabViewController {
    func changeTitle(forId id: Int, text: String) {
        let bar = self.barItem(for: self.bars.first!, at: id)
        let newTitle = text
        self.viewControllerIdentites[id] = newTitle
        bar.title = newTitle
        self.bars.first!.reloadData(at: 0...viewControllerIdentites.count-1, context: .full)
    }
}

extension SubscriptionActivityTabViewController: TMBarDataSource, PageboyViewControllerDataSource {

    func barItem(for bar: TMBar, at index: Int) -> TMBarItemable {
        let title = viewControllerIdentites[index]
        let barItem = TMBarItem(title: title)
        return barItem
    }

    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }

    func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        return viewControllers[index]
    }

    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return .first
    }
}

extension SubscriptionActivityTabViewController: SubscriptionActivityPageNavigationDelegate {
    func gotoPage(at index: Int) -> Bool {
        guard index >= 0 && index < viewModel.count else { return false }
        viewModel.currenctSelectedSubscriptionIndex = index
        if(index == viewModel.count - 1) && !isLoading {
            loadMore()
        }
        return true
    }
    
    func getCurrentSelectedSubscriptionModel() -> GroupSubscriptionModel? {
        guard viewModel.count > 0 else { return nil }
        return viewModel.subscriptions[viewModel.currenctSelectedSubscriptionIndex]
    }
    
    func getCurrentIndex() -> Int {
        return viewModel.currenctSelectedSubscriptionIndex
    }
    
    func getMaxIndex() -> Int {
        return viewModel.count - 1
    }
}
