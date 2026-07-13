//
//  DynamicLinkUIManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 28/08/2021.
//

import Foundation
import FirebaseDynamicLinks

class DynamicLinkUIManager {
    static let shared = DynamicLinkUIManager()
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
    var pendingDynamicLink: DynamicLink?
    
    func handleDeeplink(link: DynamicLink) {
        guard var urlString = link.url?.absoluteString else { return }
        urlString = urlString.replacingOccurrences(of: Applinks.orbisWebsiteLink, with: "")
        let urlComponents = urlString.split(separator: "/").map { substr in
            return String(substr)
        }
        guard let linkEntity = urlComponents.first else { return }
        switch linkEntity {
        case "posts":
            guard let postKey = urlComponents.last else { return }
            handlePostShareLinkTap(postKey: postKey, link: link)
            break
        default:
            return // handle other link respectively
        }
    }
    
    private func handlePostShareLinkTap(postKey: String, link: DynamicLink) {
        let postDetailsVC = UIStoryboard.getViewController(inStoryboard: "Post", identifier: "postDetailsVC") as! PostDetailsViewController
        let post = OrbisFeedPost(key: postKey)
        postDetailsVC.postDetailViewModel = PostDetailViewModel(post: post, pageIndex: 0)
        guard let rootNavVC = self.parentNavigationController else {
            pendingDynamicLink = link
            return
        }
        if let _ = rootNavVC.viewControllers.first as? HomeMapViewController {
            rootNavVC.dismiss(animated: false) {
                rootNavVC.popToRootViewController(animated: false)
                rootNavVC.pushViewController(postDetailsVC, animated: true)
            }
        }
        else {
            pendingDynamicLink = link
        }
    }
}
