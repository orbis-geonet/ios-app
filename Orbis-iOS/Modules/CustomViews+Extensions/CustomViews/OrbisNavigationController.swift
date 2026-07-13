//
//  OrbisNavigationController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/03/2021.
//

import UIKit

class OrbisNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNavigationBarHidden(true, animated: false)
    }
    
    override func topOffset() -> CGFloat {
        return 0
    }
    
    override func showDragIndicator() -> Bool {
        return false
    }
    
    override func isAutoHandleKeyboardEnabled() -> Bool {
        return false
    }

    override func shouldRespond(toPanModalGestureRecognizer panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        guard self.viewControllers.count == 1 else { return false }
        if let publicNotifVC = self.viewControllers.first as? PublicAccountNotificationListViewController {
            return publicNotifVC.shouldRespond(toPanModalGestureRecognizer: panGestureRecognizer)
        }
        else if let privateNotifVC = self.viewControllers.first as? PrivateAccountNotificationViewController {
            return privateNotifVC.shouldRespond(toPanModalGestureRecognizer: panGestureRecognizer)
        }
        else if let eventDetailsVC = self.viewControllers.first as? EventDetailsViewController {
            return eventDetailsVC.shouldRespond(toPanModalGestureRecognizer: panGestureRecognizer)
        }
        else if let userFollowedPlacesVC = self.viewControllers.first as? SettingsFollowedPlacesListViewController {
            return userFollowedPlacesVC.shouldRespond(toPanModalGestureRecognizer: panGestureRecognizer)
        }
        else if let commentVC = self.viewControllers.first as? CommentsViewController {
            return commentVC.shouldRespond(toPanModalGestureRecognizer: panGestureRecognizer)
        }
        else if let blockListVC = self.viewControllers.first as? SettingsBlockedListViewController {
            return blockListVC.shouldRespond(toPanModalGestureRecognizer: panGestureRecognizer)
        }
        return false
    }
}
