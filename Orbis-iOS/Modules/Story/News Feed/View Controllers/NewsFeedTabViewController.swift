//
//  NewsFeedTabViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/03/2021.
//

import UIKit
import Pageboy
import Tabman

class NewsFeedTabViewController: TabmanViewController {

    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func addTapped(_ sender: Any) {
        tryOpenCreatePostView()
    }
    @IBAction func navigateBtnTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    fileprivate var viewControllers = [UIViewController]()
    fileprivate var viewControllerIdentites = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.isScrollEnabled = false
        initializeTabViewControllers()
        setupTabBar()
        reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(userDidLogin(_:)), name: NSNotification.Name(AppNotificationKeys.userDidLogin), object: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func userDidLogin(_ notification: NSNotification) {
        initializeTabViewControllers()
        reloadData()
    }
    
    private func initializeTabViewControllers() {
        let newsFeedVC = UIStoryboard.getViewController(inStoryboard: "NewsFeed", identifier: "newsFeedVC") as! NewsFeedViewController
        newsFeedVC.viewModel = MyFeedViewModel(type: .newsFeed)
        
        let nearByVC = UIStoryboard.getViewController(inStoryboard: "NewsFeed", identifier: "newsFeedVC") as! NewsFeedViewController
        nearByVC.viewModel = MyFeedViewModel(type: .nearbyFeed)
        
        let guestFeedVC = UIViewController()
        
        if let _ = UserSessionManager.shared.currentUser {
            viewControllers = [newsFeedVC, nearByVC]
            viewControllerIdentites = [AppStrings.Feed.Tabs.myFeed, AppStrings.Feed.Tabs.nearby]
        }
        else {
            viewControllers = [guestFeedVC, nearByVC]
            viewControllerIdentites = [AppStrings.Feed.Tabs.myFeed, AppStrings.Feed.Tabs.nearby]
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
    
    private func tryOpenCreatePostView() {
        guard UserSessionManager.shared.currentUser != nil else {
            self.gotoAuthView()
            return
        }
        openFeedCreatePostPage()
    }
    
    private func gotoAuthView() {
        if UserSessionManager.shared.hasLoginOnboardingBeenShown {
            let authView = UIStoryboard.getViewController(inStoryboard: "Auth", identifier: "authMainVC") as! AuthMainViewController
            authView.defaultSelectionIndex = 0
            self.navigationController?.pushViewController(authView, animated: true)
        }
        else {
            UserSessionManager.shared.setLoginOnboardingShown()
            let authOptionPickerVC = UIStoryboard.getViewController(inStoryboard: "Auth", identifier: "authOptionPickerVC") as! AuthOptionPickerViewController
            self.navigationController?.pushViewController(authOptionPickerVC, animated: true)
        }
    }
    
    override func bar(_ bar: TMBar, didRequestScrollTo index: Int) {
        if index == 0 && UserSessionManager.shared.currentUser == nil {
            gotoAuthView()
        }
        else {
            super.bar(bar, didRequestScrollTo: index)
        }
    }
    
    private func openFeedCreatePostPage() {
        let createPostVC = UIStoryboard.getViewController(inStoryboard: "Post", identifier: "createPostVC") as! CreatePostViewController
        createPostVC.viewModel = CreatePostViewModel(defaultPublisherGroup: nil, isSelfPublisher: true, allowUserPublisher: true)
        createPostVC.createPostInvoker = CreatePostInvoker.feed
        createPostVC.onCreatePostSuccess = {
            [weak self] data in
            self?.viewControllers.forEach({ vc in
                if let feedVC = vc as? NewsFeedViewController {
                    feedVC.refreshFeed()
                }
            })
            if let feedPost = data as? OrbisFeedPost, let placeKey = feedPost.place?.placeKey, CreatePlaceSharedManager.shared.newlyCreatedListContains(key: placeKey){
                self?.goToMapView(withPost: feedPost)
            }
            else if let placeData = data as? OrbisPlace {
                self?.gotoPlaceDetailView(place: placeData)
            }
        }
        createPostVC.modalPresentationStyle = .overFullScreen
        presentPanModal(createPostVC)
    }
    
    private func goToMapView(withPost post: OrbisFeedPost) {
        guard var place = post.place else { return }
        guard let keyWindow = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first else { return }
        guard let rootNavVC = keyWindow.rootViewController as? UINavigationController else { return }
        place.lastSize = 500
        place.lastCheckInTimestamp = Date().iso8601withFractionalSeconds
        if place.lastSizeChangeTimestamp == nil {
            place.lastSizeChangeTimestamp = place.lastCheckInTimestamp
        }
        if place.dominantGroup == nil {
            place.dominantGroup = post.group
            place.dominantGroupKey = post.group?.groupKey
        }
        if let homeVC = rootNavVC.viewControllers.first as? HomeMapViewController {
            self.navigationController?.popToRootViewController(animated: true)
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
                homeVC.handlePlaceCheckinSuccess(place: place)
            }
        }
    }
    
    private func gotoPlaceDetailView(place: OrbisPlace) {
        let placeDetailVC = UIStoryboard.getViewController(inStoryboard: "Places", identifier: "placeDetailVC") as! PlaceDetailViewController
        placeDetailVC.viewModel = PlaceDetailViewModel(place: place)
        self.navigationController?.pushViewController(placeDetailVC, animated: true)
    }
}

extension NewsFeedTabViewController: TMBarDataSource, PageboyViewControllerDataSource {
    func barItem(for bar: TMBar, at index: Int) -> TMBarItemable {
        let title = viewControllerIdentites[index]
        let barItem = TMBarItem(title: title)
        return barItem
    }
    
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }
    
    func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        guard index >= 0 else { return nil }
        return viewControllers[index]
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        if UserSessionManager.shared.currentUser == nil {
            return .last
        }
        return .last
    }
}
