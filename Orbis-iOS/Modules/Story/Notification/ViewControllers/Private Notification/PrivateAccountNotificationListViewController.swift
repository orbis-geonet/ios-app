//
//  PrivateAccountNotificationListViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 11/04/2021.
//

import UIKit

enum PrivateNotificationListType {
    case news
    case pending
}

class PrivateAccountNotificationListViewController: OrbisLocalizableViewController {
    @IBOutlet weak var listView: UITableView!
    
    var viewModel: NotificationListViewModel!
    var listType: PrivateNotificationListType!
    var selectedRow: IndexPath?
    weak var initDelegate: PrivateNotificationTableViewInitDelegate?
    
    var isNotificationsLoading: Bool = false
    var refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = NotificationListViewModel()
        setupTableView()
        handleViewModelActions()
        resetData()
        loadNotifications()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let name = (listType == .news) ? AppNotificationKeys.privateNewsNotificationSeen : AppNotificationKeys.privatePendingNotificationSeen
        NotificationCenter.default.post(name: NSNotification.Name(name), object: nil)
    }
    
    func setupTableView() {
        listView.register(UINib(nibName: "NotificationNormalTextTableViewCell", bundle: nil), forCellReuseIdentifier: "NotificationNormalTextTableViewCell")
        listView.register(UINib(nibName: "NormalTextWithUserTableViewCell", bundle: nil), forCellReuseIdentifier: "NormalTextWithUserTableViewCell")
        listView.register(UINib(nibName: "NotificationWithActionTableViewCell", bundle: nil), forCellReuseIdentifier: "NotificationWithActionTableViewCell")
        listView.delegate = self
        listView.dataSource = self
        switch listType {
        case .pending:
            initDelegate?.didLoadPendingNotificationView(tableView: listView)
        default:
            initDelegate?.didLoadNewsNotificationView(tableView: listView)
        }
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleCellLongPress(sender:)))
        listView.addGestureRecognizer(longTapGesture)
    }
    
    @objc private func handleCellLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: listView)
            if let indexPath = listView.indexPathForRow(at: touchPoint) {
                self.selectedRow = indexPath
                listView.cellForRow(at: indexPath)?.setSelectedUI()
                let model = viewModel.getNotificationModel(at: indexPath.row)
                guard let _ = UserSessionManager.shared.currentUser else { return }
                showDeleteNotificationView(forModel: model)
            }
        }
    }

    private func handleViewModelActions() {
        
        viewModel.onNotificationsFetched = { [weak self] in
            self?.hideOrbisLoader()
            self?.isNotificationsLoading = false
            DispatchQueue.main.async {
                [weak self] in
                self?.listView.reloadData()
            }
        }
        viewModel.onNotificationsFetchedCompletePagination = { [weak self] in
            self?.hideOrbisLoader()
            self?.isNotificationsLoading = false
            DispatchQueue.main.async {
                [weak self] in
                self?.listView.reloadData()
            }
        }
        viewModel.onNotificationsFetchError = { [weak self] (error) in
            self?.hideOrbisLoader()
            self?.handleError(error: error)
            self?.isNotificationsLoading = false
        }
        viewModel.onNotificationsRead = { [weak self] in
            DispatchQueue.main.async {
                [weak self] in
                self?.listView.reloadData()
            }
        }
    }
    
    func resetData() {
        viewModel.initializePagination()
        isNotificationsLoading = false
        listView.reloadData()
    }
    
    func loadNotifications() {
        isNotificationsLoading = true
        self.showOrbisLoader()
        if listType == .pending {
            viewModel.fetchPendingRequests()
        }
        else {
            viewModel.loadNotifications()
        }
    }
    
    func loadMoreNotifications() {
        isNotificationsLoading = true
        self.showOrbisLoader()
        if listType == .pending {
            viewModel.fetchMorePendingRequests()
        }
        else {
            viewModel.loadMoreNotifications()
        }
    }
    
    private func tryAcceptFollowRequest(forUser user: OrbisUser) {
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.acceptFollowRequest(forUser: user) { [weak self] data, err in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.listView.reloadData()
            }
            self?.hideOrbisLoader()
        }
    }
}

extension PrivateAccountNotificationListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0}
        return viewModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewModel.getNotificationModel(at: indexPath.row)
        let deselectedColor: UIColor = (model.seen == true) ? .white : UIColor(named: AppColors.appOffWhite2.rawValue)!
        if self.listType == .pending {
            let notificationCell = tableView.dequeueReusableCell(withIdentifier: "NotificationWithActionTableViewCell") as! NotificationWithActionTableViewCell
            notificationCell.viewModel = NotificationItemViewModel(notif: model)
            notificationCell.setDeselectedSelectedUI(color: deselectedColor)
            notificationCell.onAcceptFollowRequest = {
                [weak self] user in
                self?.tryAcceptFollowRequest(forUser: user)
            }
            return notificationCell
        }
        else {
            if model.hasUser {
                let notificationCell = tableView.dequeueReusableCell(withIdentifier: "NormalTextWithUserTableViewCell") as! NormalTextWithUserTableViewCell
                notificationCell.viewModel = NotificationItemViewModel(notif: model)
                notificationCell.setDeselectedSelectedUI(color: deselectedColor)
                return notificationCell
            }
            else {
                let notificationCell = tableView.dequeueReusableCell(withIdentifier: "NotificationNormalTextTableViewCell") as! NotificationNormalTextTableViewCell
                notificationCell.viewModel = NotificationItemViewModel(notif: model)
                notificationCell.setDeselectedSelectedUI(color: deselectedColor)
                return notificationCell
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15.toCGFloat.relativeToIphone8Width()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear
        return header
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let loadMoreIndex = viewModel.count - 1
        if indexPath.row == loadMoreIndex && !isNotificationsLoading && !viewModel.hasItemsLastPageReached {
            self.loadMoreNotifications()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigateToNotificationContent(at: indexPath.row)
    }
    
    private func showDeleteNotificationView(forModel model: OrbisNotification) {
        let deleteNotificationVC = UIStoryboard.getViewController(inStoryboard: "Notification", identifier: "deleteNotificationVC") as! NotificationDeletePopupViewController
        deleteNotificationVC.modalPresentationStyle = .overFullScreen
        deleteNotificationVC.shouldDismissViewOnTapOutside = true
        deleteNotificationVC.notificationModel = model
        deleteNotificationVC.dismissDelegate = self
        deleteNotificationVC.onDeleteTapped = { [weak self] notification in
            self?.proceedDeleteNotification(notification: notification)
        }
        self.present(deleteNotificationVC, animated: false, completion: nil)
    }
    
    private func proceedDeleteNotification(notification: OrbisNotification) {
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.deleteNotification(notification: notification) {
            [weak self] data, err in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.listView.reloadData()
            }
            self?.hideOrbisLoader()
        }
    }
    
    private func navigateToNotificationContent(at index: Int) {
        if self.listType == .pending {
            let notification = viewModel.getNotificationModel(at: index)
            switch notification.notifType {
            case .followRequest:
                showProfileView(for: notification)
                break
            default:
                debugPrint("Cannot perform tap on this notification")
                break
            }
            return
        }
        let notification = viewModel.getNotificationModel(at: index)
        switch notification.notifType {
        case .invalid:
            debugPrint("Cannot perform tap on this notification")
            break
        case .checkin:
            showPlacePage(for: notification)
            break
        case .comment:
            showPostPage(for: notification)
            break
        case .follower:
            showProfileView(for: notification)
            break
        case .post:
            showPostPage(for: notification)
            break
        case .reportPost:
            showPostPage(for: notification)
        case .reportGroup:
            showGroupPage(for: notification)
        case .reportUser:
            showProfileView(for: notification)
        case .reportPlace:
            showPlacePage(for: notification)
        default:
            debugPrint("Cannot perform tap on this notification")
            break
        }
    }
    
    private func showProfileView(for notif: OrbisNotification) {
        guard let user = notif.fromUser else { return }
        if user.deleted == true  {
            UIUtil.showGlobalToast(message: AppStrings.userHasBeenDeleted)
            return
        }
        let isViewingSelf = (user.userKey == UserSessionManager.shared.currentUser?.userKey)
        let profileVC = UIStoryboard.getViewController(inStoryboard: "Profile", identifier: "userProfileVC") as! UserProfileViewController
        profileVC.viewModel = ProfileDetailViewModel(user: user, isViewingSelf: isViewingSelf)
        self.navigationController?.pushViewController(profileVC, animated: true)
    }

    private func showPlacePage(for notif: OrbisNotification) {
        guard let place = notif.place else { return }
        let placeDetailVC = UIStoryboard.getViewController(inStoryboard: "Places", identifier: "placeDetailVC") as! PlaceDetailViewController
        placeDetailVC.viewModel = PlaceDetailViewModel(place: place)
        self.navigationController?.pushViewController(placeDetailVC, animated: true)
    }
    
    private func showPostPage(for notif: OrbisNotification) {
        guard let post = notif.post else { return }
        let postDetailsVC = UIStoryboard.getViewController(inStoryboard: "Post", identifier: "postDetailsVC") as! PostDetailsViewController
        postDetailsVC.postDetailViewModel = PostDetailViewModel(post: post, pageIndex: 0)
        self.navigationController?.pushViewController(postDetailsVC, animated: true)
    }
    
    private func showGroupPage(for notif: OrbisNotification) {
        guard let group = notif.group else { return }
        let groupDetailsVC = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "groupDetailVC") as! GroupDetailsViewController
        groupDetailsVC.viewModel = GroupDetailViewModel(group: group)
        self.navigationController?.pushViewController(groupDetailsVC, animated: true)
    }
}

extension PrivateAccountNotificationListViewController: PopupViewDismissDelegate {
    func didDismissPopupView() {
        guard let indexPath = self.selectedRow else { return }
        self.listView.cellForRow(at: indexPath)?.setDeselectedSelectedUI()
        self.listView.deselectRow(at: indexPath, animated: false)
        self.selectedRow = nil
    }
}
