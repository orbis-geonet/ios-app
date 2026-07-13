//
//  SettingsTabViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 12/04/2021.
//

import UIKit
import Tabman
import Pageboy

class SettingsTabViewController: OrbisTabmanViewController {
    
    fileprivate var viewControllers = [UIViewController]()
    fileprivate var viewControllerIdentites = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.isScrollEnabled = false
        initializeTabViewControllers()
        addLanguageUpdateObserver()
        setupTabBar()
        reloadData()
    }
    
    private func initializeTabViewControllers() {
        let settingsProfileVC = UIStoryboard.getViewController(inStoryboard: "Settings", identifier: "settingsProfileVC") as! SettingsProfileViewController
        
        let settingsSocialVC = UIStoryboard.getViewController(inStoryboard: "Settings", identifier: "settingsSocialVC") as! SettingsSocialViewController
        
        let settingsPreferencesVC = UIStoryboard.getViewController(inStoryboard: "Settings", identifier: "settingsPreferencesVC") as! SettingsPreferencesViewController
        
        viewControllers = [settingsProfileVC, settingsSocialVC, settingsPreferencesVC]
        viewControllerIdentites = [AppStrings.Settings.Tabs.profile, AppStrings.Settings.Tabs.social, AppStrings.Settings.Tabs.preferences]
    }
    
    private func addLanguageUpdateObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateLanguage), name: NSNotification.Name(rawValue: AppNotificationKeys.userLanguageDidUpdate), object: nil)
    }
    
    @objc private func didUpdateLanguage(_ notification: NSNotification) {
        guard viewControllerIdentites.count > 0 else { return }
        changeTitle(forId: 0, text: AppStrings.Settings.Tabs.profile)
        changeTitle(forId: 1, text: AppStrings.Settings.Tabs.social)
        changeTitle(forId: 2, text: AppStrings.Settings.Tabs.preferences)
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

extension SettingsTabViewController {
    func changeTitle(forId id: Int, text: String) {
        let bar = self.barItem(for: self.bars.first!, at: id)
        let newTitle = text
        self.viewControllerIdentites[id] = newTitle
        bar.title = newTitle
        self.bars.first!.reloadData(at: 0...viewControllerIdentites.count-1, context: .full)
    }
}

extension SettingsTabViewController: TMBarDataSource, PageboyViewControllerDataSource {
    
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
