//
//  OnboardingViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 20/04/2021.
//

import UIKit

class OnboardingViewController: OrbisLocalizableViewController {

    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var startBtn: UIButton!
    
    
    @IBAction func startTapped(_ sender: Any) {
        showHomeMainView()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateStaticTexts()
        // Do any additional setup after loading the view.
    }
    
    override func updateStaticTexts() {
        headingLabel.text = AppStrings.Onboarding.onboardingTitle
        messageLabel.text = AppStrings.Onboarding.onboardingMessage
        startBtn.setTitle(AppStrings.Onboarding.start, for: .normal)
    }
    private func showHomeMainView() {
        let homeMainNavVC = UIStoryboard.getViewController(inStoryboard: "Home", identifier: "homeMainVC") as! HomeMapViewController
        self.navigationController?.pushViewController(homeMainNavVC, animated: true)
    }
}
