//
//  UserProfileDetailsTabViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 01/04/2021.
//

import UIKit
import Pageboy
import Tabman

class UserProfileDetailsTabViewController: OrbisTabmanViewController {
    
    weak var parentProfileView: UserProfileViewController?
    weak var modelDataSource: ProfileViewModelDataSource?
    weak var parallexScrollDelegate: OrbisParallexScrollDelegate?
    
    fileprivate var viewControllers = [UIViewController]()
    fileprivate var viewControllerIdentites = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.isScrollEnabled = false
        self.orbisTabmanScrollDelegate = self
        initializeTabViewControllers()
        setupTabBar()
        reloadData()
        addLanguageUpdateObserver()
    }
    
    private func addLanguageUpdateObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateLanguage), name: NSNotification.Name(rawValue: AppNotificationKeys.userLanguageDidUpdate), object: nil)
    }
    
    @objc private func didUpdateLanguage(_ notification: NSNotification) {
        guard viewControllerIdentites.count > 0 else { return }
        changeTitle(forId: 0, text: AppStrings.Profile.Tabs.photos)
        changeTitle(forId: 1, text: AppStrings.Profile.Tabs.posts)
    }
    
    private func initializeTabViewControllers() {
        guard let viewModel = modelDataSource?.getProfileModel() else { return }
        let profileFeedVC = UIStoryboard.getViewController(inStoryboard: "Profile", identifier: "profileFeedVC") as! ProfileFeedViewController
        profileFeedVC.viewModel = ProfileFeedViewModel(user: viewModel.user, isViewingSelf: viewModel.isViewingSelf)
        profileFeedVC.parallexScrollDelegate = parallexScrollDelegate
        
        let profilePhotosVC = UIStoryboard.getViewController(inStoryboard: "Profile", identifier: "profilePhotosVC") as! ProfilePhotosViewController
        profilePhotosVC.viewModel = ProfilePhotosViewModel(user: viewModel.user, isViewingSelf: viewModel.isViewingSelf)
        profilePhotosVC.parallexScrollDelegate = parallexScrollDelegate
        viewControllers = [profilePhotosVC, profileFeedVC]
        viewControllerIdentites = [AppStrings.Profile.Tabs.photos, AppStrings.Profile.Tabs.posts]
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
}

extension UserProfileDetailsTabViewController: TMBarDataSource, PageboyViewControllerDataSource {
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
        if let index = parallexScrollDelegate?.getCurrentSelectedTabIndex() {
            return PageboyViewController.Page.at(index: index)
        }
        return .first
    }
    
}

extension UserProfileDetailsTabViewController {
    func changeTitle(forId id: Int, text: String) {
        let bar = self.barItem(for: self.bars.first!, at: id)
        let newTitle = text
        self.viewControllerIdentites[id] = newTitle
        bar.title = newTitle
        self.bars.first!.reloadData(at: 0...viewControllerIdentites.count-1, context: .full)
    }
}

extension UserProfileDetailsTabViewController: OrbisTabmanScrollDelegate {
    func orbisPageboyViewController(_ pageboyViewController: PageboyViewController, didScrollToPageAt index: TabmanViewController.PageIndex, direction: PageboyViewController.NavigationDirection, animated: Bool) {
        if let vc = viewControllers[index] as? ProfilePhotosViewController {
            parallexScrollDelegate?.didChangeChildScrollView(scrollView: vc.photosCollectionView)
            parallexScrollDelegate?.profileDidChangeTab(tab: .photos)
        }
        else if let vc = viewControllers[index] as? ProfileFeedViewController {
            parallexScrollDelegate?.didChangeChildScrollView(scrollView: vc.feedTableView)
            parallexScrollDelegate?.profileDidChangeTab(tab: .posts)
        }
        
    }
}
