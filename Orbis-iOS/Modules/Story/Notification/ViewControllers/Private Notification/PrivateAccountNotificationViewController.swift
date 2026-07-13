//
//  PrivateAccountNotificationViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 11/04/2021.
//

import UIKit

protocol PrivateNotificationTableViewInitDelegate: AnyObject {
    func didLoadNewsNotificationView(tableView: UITableView)
    func didLoadPendingNotificationView(tableView: UITableView)
    func didSelectTabIndex(index: Int)
}

class PrivateAccountNotificationViewController: OrbisLocalizableViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBAction func backTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var selectedTabIndex: Int = 0
    var newsNotificationListView: UITableView?
    var pendingNotificationListView: UITableView?
    var defaultSelectedIndex = 0
    
    override func topOffset() -> CGFloat {
        return 0
    }
    
    override func showDragIndicator() -> Bool {
        return false
    }

    override func shouldRespond(toPanModalGestureRecognizer panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        let panGesturePoint = panGestureRecognizer.location(in: self.view)
        if let listView = self.newsNotificationListView, selectedTabIndex == 0 {
            let tableFrame = listView.convert(listView.bounds, to: self.view)
            if tableFrame.contains(panGesturePoint) {
                return listView.contentOffset.y <= 0
            }
        }
        if let listView = self.pendingNotificationListView, selectedTabIndex == 1 {
            let tableFrame = listView.convert(listView.bounds, to: self.view)
            if tableFrame.contains(panGesturePoint) {
                return listView.contentOffset.y <= 0
            }
        }
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateStaticTexts()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        reloadNotificationCount()
    }
    
    override func updateStaticTexts() {
        titleLabel.text = AppStrings.Notification.title
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tabVC = segue.destination as? PrivateAccountNotificationTabViewController {
            tabVC.defaultSelectedPageIndex = self.defaultSelectedIndex
            tabVC.parentNotificationView = self
            tabVC.tableViewDelegate = self
        }
    }

    private func reloadNotificationCount() {
        guard let keyWindow = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive || $0.activationState == .foregroundInactive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first else { return }
        guard let rootNavVC = keyWindow.rootViewController as? UINavigationController else { return  }
        if let homeVC = rootNavVC.viewControllers.first as? HomeMapViewController {
            homeVC.fetchUnreadNotificationsCount()
        }
    }
}

extension PrivateAccountNotificationViewController: PrivateNotificationTableViewInitDelegate {
    func didLoadNewsNotificationView(tableView: UITableView) {
        self.newsNotificationListView = tableView
    }
    
    func didLoadPendingNotificationView(tableView: UITableView) {
        self.pendingNotificationListView = tableView
    }
    
    func didSelectTabIndex(index: Int) {
        self.selectedTabIndex = index
    }
}
