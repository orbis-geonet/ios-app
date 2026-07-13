//
//  NotificationDeletePopupViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 11/04/2021.
//

import UIKit

class NotificationDeletePopupViewController: PopupViewController {

    
    @IBAction func deleteNotificationTapped(_ sender: Any) {
        self.dismiss(animated: true) {
            [weak self] in
            guard let self = self else { return }
            self.onDeleteTapped?(self.notificationModel)
        }
    }
    
    var notificationModel: OrbisNotification!
    
    var onDeleteTapped: ((OrbisNotification) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}
