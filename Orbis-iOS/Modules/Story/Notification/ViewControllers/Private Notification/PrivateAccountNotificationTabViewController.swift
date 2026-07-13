//
//  PrivateAccountNotificationTabViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 11/04/2021.
//

import UIKit
import Tabman
import Pageboy

class PrivateAccountNotificationTabViewController: OrbisTabmanViewController {
    
    weak var parentNotificationView: PrivateAccountNotificationViewController?
    
    fileprivate var viewControllers = [UIViewController]()
    fileprivate var viewControllerIdentites = [String]()
    let notifManager = OrbisNotificationManager()
    weak var tableViewDelegate: PrivateNotificationTableViewInitDelegate?
    
    var newsBadgeView: RoundedView!
    var newsBadgeLabel: UILabel!
    var pendingBadgeView: RoundedView!
    var pendingBadgeLabel: UILabel!
    var defaultSelectedPageIndex: Int = 0
    
    var isUserLoggedIn: Bool {
        return UserSessionManager.shared.currentUser != nil
    }
    var isFetchingUnreadNotifications = false
    
    private struct BadgeConfig {
        static let size = 20.toCGFloat.relativeToIphone8Width()
        static let fontSize = 10.toCGFloat.relativeToIphone8Width()
        static let separation = 20.toCGFloat.relativeToIphone8Width()
        static let verticalSeparation = -3.toCGFloat.relativeToIphone8Width()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.isScrollEnabled = false
        initializeTabViewControllers()
        addObservers()
        addLanguageUpdateObserver()
        setupTabBar()
        reloadData()
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(didSeenNewsNotification(_:)), name: NSNotification.Name(AppNotificationKeys.privateNewsNotificationSeen), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didSeenPendingNotification(_:)), name: NSNotification.Name(AppNotificationKeys.privatePendingNotificationSeen), object: nil)
    }
    
    private func addLanguageUpdateObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateLanguage), name: NSNotification.Name(rawValue: AppNotificationKeys.userLanguageDidUpdate), object: nil)
    }
    
    @objc private func didUpdateLanguage(_ notification: NSNotification) {
        guard viewControllerIdentites.count > 0 else { return }
        changeTitle(forId: 0, text: AppStrings.Notification.Tabs.news)
        changeTitle(forId: 1, text: AppStrings.Notification.Tabs.pending)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func fetchUnreadNotificationsCount() {
        guard isUserLoggedIn else { return }
        guard !isFetchingUnreadNotifications else { return }
        isFetchingUnreadNotifications = true
        notifManager.getUnreadNotificationsCount { [weak self] data, err in
            if let count = data as? OrbisNotificationCount {
                UserSessionManager.shared.userNotificationCount = count
            }
            self?.isFetchingUnreadNotifications = false
        }
    }
    
    @objc private func didSeenNewsNotification(_ sender: NSNotification) {
        newsBadgeView.isHidden = true
    }
    
    @objc private func didSeenPendingNotification(_ sender: NSNotification) {
        pendingBadgeView.isHidden = true
    }
    
    private func initializeBadgeViews()  {
        newsBadgeView = RoundedView()
        newsBadgeView.isUserInteractionEnabled = false
        newsBadgeView.translatesAutoresizingMaskIntoConstraints = false
        newsBadgeView.heightAnchor.constraint(equalToConstant: BadgeConfig.size).isActive = true
        newsBadgeView.widthAnchor.constraint(equalToConstant: BadgeConfig.size).isActive = true
        newsBadgeView.isCircular = true
        newsBadgeView.clipsToBounds = true
        newsBadgeView.backgroundColor = UIColor(named: AppColors.appOrange.rawValue)
        newsBadgeView.isHidden = true
        newsBadgeLabel = UILabel()
        newsBadgeLabel.textAlignment = .center
        newsBadgeLabel.font = UIFont(name: "Roboto-Bold", size: BadgeConfig.fontSize)!
        newsBadgeLabel.text = ""
        newsBadgeLabel.textColor = UIColor.init(named: AppColors.appBlack.rawValue)
        newsBadgeView.addSubview(newsBadgeLabel)
        newsBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        newsBadgeLabel.leadingAnchor.constraint(equalTo: newsBadgeView.leadingAnchor).isActive = true
        newsBadgeLabel.trailingAnchor.constraint(equalTo: newsBadgeView.trailingAnchor).isActive = true
        newsBadgeLabel.topAnchor.constraint(equalTo: newsBadgeView.topAnchor).isActive = true
        newsBadgeLabel.bottomAnchor.constraint(equalTo: newsBadgeView.bottomAnchor).isActive = true
        
        pendingBadgeView = RoundedView()
        pendingBadgeView.isUserInteractionEnabled = false
        pendingBadgeView.translatesAutoresizingMaskIntoConstraints = false
        pendingBadgeView.heightAnchor.constraint(equalToConstant: BadgeConfig.size).isActive = true
        pendingBadgeView.widthAnchor.constraint(equalToConstant: BadgeConfig.size).isActive = true
        pendingBadgeView.isCircular = true
        pendingBadgeView.clipsToBounds = true
        pendingBadgeView.backgroundColor = UIColor(named: AppColors.appOrange.rawValue)
        pendingBadgeLabel = UILabel()
        pendingBadgeLabel.textAlignment = .center
        pendingBadgeLabel.font = UIFont(name: "Roboto-Bold", size: BadgeConfig.fontSize)!
        pendingBadgeLabel.text = ""
        pendingBadgeLabel.textColor = UIColor.init(named: AppColors.appBlack.rawValue)
        pendingBadgeView.addSubview(pendingBadgeLabel)
        pendingBadgeView.isHidden = true
        if let pendingReqCount = UserSessionManager.shared.userNotificationCount?.pendingRequests {
            pendingBadgeView.isHidden = pendingReqCount <= 0
            pendingBadgeLabel.text = "\(pendingReqCount)"
        }
        pendingBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        pendingBadgeLabel.leadingAnchor.constraint(equalTo: pendingBadgeView.leadingAnchor).isActive = true
        pendingBadgeLabel.trailingAnchor.constraint(equalTo: pendingBadgeView.trailingAnchor).isActive = true
        pendingBadgeLabel.topAnchor.constraint(equalTo: pendingBadgeView.topAnchor).isActive = true
        pendingBadgeLabel.bottomAnchor.constraint(equalTo: pendingBadgeView.bottomAnchor).isActive = true
        
    }
    
    private func initializeTabViewControllers() {
        let newsNotificationVC = UIStoryboard.getViewController(inStoryboard: "Notification", identifier: "privateNotificationListVC") as! PrivateAccountNotificationListViewController
        newsNotificationVC.listType = .news
        newsNotificationVC.initDelegate = parentNotificationView
        
        let pendingNotificationVC = UIStoryboard.getViewController(inStoryboard: "Notification", identifier: "privateNotificationListVC") as! PrivateAccountNotificationListViewController
        pendingNotificationVC.listType = .pending
        pendingNotificationVC.initDelegate = parentNotificationView
        
        viewControllers = [newsNotificationVC, pendingNotificationVC]
        viewControllerIdentites = [AppStrings.Notification.Tabs.news, AppStrings.Notification.Tabs.pending]
    }
    
    private func setupTabBar() {
        initializeBadgeViews()
        let bar = OrbisTMBarButton()
        bar.layout.contentMode = .fit
        bar.indicator.weight = .light
        bar.indicator.tintColor = UIColor(named: AppColors.appBlack.rawValue)
        bar.indicator.cornerStyle = .eliptical
        bar.layout.view.backgroundColor = .white
        bar.layout.transitionStyle = .snap
        bar.backgroundView.style = .flat(color: UIColor.white)
        bar.buttons.customize { [weak self ](button) in
            guard let self = self else { return }
            button.font = UIFont(name: "Roboto-Black", size: CGFloat(16).relativeToIphone8Width())!
            button.tintColor = UIColor(named: AppColors.appWarmGray2.rawValue)
            button.selectedTintColor = UIColor(named: AppColors.appBlack.rawValue)
            if button.text == AppStrings.Notification.Tabs.news {
                let textWidth = button.text!.findTextWidth(font: button.font)
                button.addSubview(self.newsBadgeView)
                self.newsBadgeView.centerYAnchor.constraint(equalTo: button.centerYAnchor, constant: BadgeConfig.verticalSeparation).isActive = true
                self.newsBadgeView.centerXAnchor.constraint(equalTo: button.centerXAnchor, constant: (textWidth / 2) + BadgeConfig.separation).isActive = true
            }
            else if button.text == AppStrings.Notification.Tabs.pending {
                let textWidth = button.text!.findTextWidth(font: button.font)
                button.addSubview(self.pendingBadgeView)
                self.pendingBadgeView.centerYAnchor.constraint(equalTo: button.centerYAnchor, constant: BadgeConfig.verticalSeparation).isActive = true
                self.pendingBadgeView.centerXAnchor.constraint(equalTo: button.centerXAnchor, constant: (textWidth / 2) + BadgeConfig.separation).isActive = true
            }
            
        }
        addBar(bar, dataSource: self, at: .top)
    }
}

extension PrivateAccountNotificationTabViewController {
    func changeTitle(forId id: Int, text: String) {
        let bar = self.barItem(for: self.bars.first!, at: id)
        let newTitle = text
        self.viewControllerIdentites[id] = newTitle
        bar.title = newTitle
        self.bars.first!.reloadData(at: 0...viewControllerIdentites.count-1, context: .full)
    }
}

extension PrivateAccountNotificationTabViewController: TMBarDataSource, PageboyViewControllerDataSource {
    func barItem(for bar: TMBar, at index: Int) -> TMBarItemable {
        let title = viewControllerIdentites[index]
        let barItem = TMBarItem(title: title)
        return barItem
    }
    
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }
    
    func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        tableViewDelegate?.didSelectTabIndex(index: index)
        return viewControllers[index]
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return PageboyViewController.Page.at(index: self.defaultSelectedPageIndex)
    }
    
}
