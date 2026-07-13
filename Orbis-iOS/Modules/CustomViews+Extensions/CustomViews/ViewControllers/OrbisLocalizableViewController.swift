//
//  OrbisLocalizableViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 29/09/2021.
//

import UIKit

class OrbisLocalizableViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addLanguageUpdateObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func addLanguageUpdateObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateLanguage), name: NSNotification.Name(rawValue: AppNotificationKeys.userLanguageDidUpdate), object: nil)
    }
    
    @objc private func didUpdateLanguage(_ notification: NSNotification) {
        updateStaticTexts()
    }
    
    func updateStaticTexts() {
    }
}
