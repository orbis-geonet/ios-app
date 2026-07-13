//
//  PushNotificationUIManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 10/08/2021.
//

import Foundation
import UIKit

class PushNotificationUIManager {
    static let shared = PushNotificationUIManager()
    var pendingOpenNotification: OrbisPushNotifObject?
    
    var parentNavigationController: UINavigationController? {
        guard let keyWindow = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive || $0.activationState == .foregroundInactive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first else { return nil }
        guard let rootNavVC = keyWindow.rootViewController as? UINavigationController else { return nil }
        return rootNavVC
    }

    private func showProfileView(for notif: OrbisPushNotifObject) {
        guard let userId = notif.contentKey else { return }
        let user = OrbisUser(key: userId, name: "", proPicLink: "")
        if user.deleted == true  {
            UIUtil.showGlobalToast(message: AppStrings.userHasBeenDeleted)
            return
        }
        let isViewingSelf = (user.userKey == UserSessionManager.shared.currentUser?.userKey)
        let profileVC = UIStoryboard.getViewController(inStoryboard: "Profile", identifier: "userProfileVC") as! UserProfileViewController
        profileVC.viewModel = ProfileDetailViewModel(user: user, isViewingSelf: isViewingSelf)
        guard let rootNavVC = self.parentNavigationController else {
            pendingOpenNotification = notif
            return
        }
        if let _ = rootNavVC.viewControllers.first as? HomeMapViewController {
            rootNavVC.dismiss(animated: false) {
                rootNavVC.popToRootViewController(animated: false)
                rootNavVC.pushViewController(profileVC, animated: true)
            }
        }
        else {
            pendingOpenNotification = notif
        }
    }
    
    private func showChatView(for notif: OrbisPushNotifObject) {
        guard let conversationId = notif.contentKey else { return }
        var conversation = OrbisConversation()
        conversation.id = conversationId
        let conversationVC = UIStoryboard.getViewController(inStoryboard: "Chat", identifier: "conversationVC") as! ConversationViewController
        conversationVC.viewModel = ConversationViewModel(conversation: conversation)
        guard let rootNavVC = self.parentNavigationController else {
            pendingOpenNotification = notif
            return
        }
        if let _ = rootNavVC.viewControllers.first as? HomeMapViewController {
            rootNavVC.dismiss(animated: false) {
                rootNavVC.popToRootViewController(animated: false)
                rootNavVC.pushViewController(conversationVC, animated: true)
            }
        }
        else {
            pendingOpenNotification = notif
        }
    }
    
    private func showPlacePage(for notif: OrbisPushNotifObject) {
        guard let placeKey = notif.contentKey else { return }
        let placeDetailVC = UIStoryboard.getViewController(inStoryboard: "Places", identifier: "placeDetailVC") as! PlaceDetailViewController
        var place = OrbisPlace()
        place.placeKey = placeKey
        placeDetailVC.viewModel = PlaceDetailViewModel(place: place)
        guard let rootNavVC = self.parentNavigationController else {
            pendingOpenNotification = notif
            return
        }
        if let _ = rootNavVC.viewControllers.first as? HomeMapViewController {
            rootNavVC.dismiss(animated: false) {
                rootNavVC.popToRootViewController(animated: false)
                rootNavVC.pushViewController(placeDetailVC, animated: true)
            }
        }
        else {
            pendingOpenNotification = notif
        }
    }
    
    private func showGroupPage(for notif: OrbisPushNotifObject) {
        guard let groupKey = notif.contentKey else { return }
        let groupDetailsVC = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "groupDetailVC") as! GroupDetailsViewController
        groupDetailsVC.viewModel = GroupDetailViewModel(group: Group(key: groupKey))
        guard let rootNavVC = self.parentNavigationController else {
            pendingOpenNotification = notif
            return
        }
        if let _ = rootNavVC.viewControllers.first as? HomeMapViewController {
            rootNavVC.dismiss(animated: false) {
                rootNavVC.popToRootViewController(animated: false)
                rootNavVC.pushViewController(groupDetailsVC, animated: true)
            }
        }
        else {
            pendingOpenNotification = notif
        }
    }
    
    private func showPostPage(for notif: OrbisPushNotifObject) {
        guard let postKey = notif.contentKey else { return }
        let postDetailsVC = UIStoryboard.getViewController(inStoryboard: "Post", identifier: "postDetailsVC") as! PostDetailsViewController
        let post = OrbisFeedPost(key: postKey)
        postDetailsVC.postDetailViewModel = PostDetailViewModel(post: post, pageIndex: 0)
        guard let rootNavVC = self.parentNavigationController else {
            pendingOpenNotification = notif
            return
        }
        if let _ = rootNavVC.viewControllers.first as? HomeMapViewController {
            rootNavVC.dismiss(animated: false) {
                rootNavVC.popToRootViewController(animated: false)
                rootNavVC.pushViewController(postDetailsVC, animated: true)
            }
        }
        else {
            pendingOpenNotification = notif
        }
    }
    
    private func showNotificationPage(for notif: OrbisPushNotifObject) {
        guard let _ = UserSessionManager.shared.currentUser else { return }
        let privateNotificationVC = UIStoryboard.getViewController(inStoryboard: "Notification", identifier: "privateNotificationVC") as! PrivateAccountNotificationViewController
        privateNotificationVC.defaultSelectedIndex = 1
        privateNotificationVC.modalPresentationStyle = .overFullScreen
        guard let rootNavVC = self.parentNavigationController else {
            pendingOpenNotification = notif
            return
        }
        if let homeVC = rootNavVC.viewControllers.first as? HomeMapViewController {
            rootNavVC.dismiss(animated: false) {
                rootNavVC.popToRootViewController(animated: false)
                homeVC.presentPanModal(privateNotificationVC)
            }
        }
        else {
            pendingOpenNotification = notif
        }
        
    }

    func goToNotificationContentView(notif: OrbisPushNotifObject){
        switch notif.notifType {
        case .invalid:
            debugPrint("Cannot perform tap on this notification")
            break
        case .checkin:
            showPlacePage(for: notif)
            break
        case .comment:
            showPostPage(for: notif)
            break
        case .follower:
            showProfileView(for: notif)
            break
        case .message:
            showChatView(for: notif)
            break
        case .post:
            showPostPage(for: notif)
            break
        case .followRequest:
            showNotificationPage(for: notif)
            break
        case .reportPost:
            showPostPage(for: notif)
            break
        case .reportGroup:
            showGroupPage(for: notif)
        case .reportPlace:
            showPlacePage(for: notif)
        case .reportUser:
            showProfileView(for: notif)
        }
    }
}
