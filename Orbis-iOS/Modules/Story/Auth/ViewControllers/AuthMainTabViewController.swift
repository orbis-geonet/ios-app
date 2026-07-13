//
//  AuthMainTabViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 06/04/2021.
//

import UIKit
import Tabman
import Pageboy

class AuthMainTabViewController: TabmanViewController {

    fileprivate var viewControllers = [UIViewController]()
    fileprivate var viewControllerIdentites = [String]()
    
    var defaultIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.isScrollEnabled = false
        initializeTabViewControllers()
        setupTabBar()
        reloadData()
        self.scrollToPage(PageboyViewController.Page.at(index: defaultIndex), animated: false)
    }
    
    private func initializeTabViewControllers() {
        let loginVC = UIStoryboard.getViewController(inStoryboard: "Auth", identifier: "loginVC") as! LoginViewController
        let signupVC = UIStoryboard.getViewController(inStoryboard: "Auth", identifier: "signupVC") as! SignupViewController
        viewControllers = [loginVC, signupVC]
        viewControllerIdentites = [AppStrings.Authentication.login, AppStrings.Authentication.register]
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

extension AuthMainTabViewController: TMBarDataSource, PageboyViewControllerDataSource {
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
