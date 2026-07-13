//
//  ApiConstants.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 23/04/2021.
//

import Foundation

// MARK:- API Link urls and keys

enum ApiLink: String{
    enum auth: String{
        case login = "/login"
        case signup = "/signup"
        case refreshToken = "/refresh"
        case changePassword = "/password"
    }
    enum profile: String {
        case me = "/profile/me"
        case detail = "/profile/%@"
        case chatUserDetail = "/profile/chatusers"
        case feed = "/feed/user/%@"
        case followUnfollow = "/profile/%@/follow"
        case instagramConnect = "/ig/connect"
        case instagramPictures = "/profile/%@/igpictures"
        case appPictures = "/profile/%@/pictures"
        case removeProfileUploadedPhoto = "/profile/me/pictures/%@"
        case postAppPictures = "/profile/me/pictures"
        case deauthorizeInsta = "/igoauth/deauthorize"
        case search = "/profile"
        case followers = "/profile/%@/followers"
        case followings = "/profile/%@/following"
        case memberOfGroups = "/profile/%@/member"
        case adminOfGroups = "/profile/%@/admin"
        case followedGroups = "/profile/%@/groupFollower"
        case fcmToken = "/profile/me/fcmToken"
        case pendingFollowRequests = "/profile/me/followers/pending"
        case acceptFollowRequest = "/profile/followers/%@/accept"
        case removeFollowRequest = "/profile/followers/%@"
        case seenFollowRequest = "/profile/followers/%@/seen"
        case report = "/profile/%@/report"
        case block = "/profile/%@/block"
        case blockedUsers = "/profile/blockedUsers"
        case blockers = "/profile/blockedByUsers"
        // subscriptions
        case userSubscrptions = "/profile/subscriptions"
        case userPurchases = "/profile/purchases"
        case subcribe = "/profile/subscription/%@/subscribe"
        case unsubcribe = "/profile/subscription/%@/unsubscribe"
        case purchase = "/profile/purchase/%@/buy"
    }
    enum group: String {
        case fetchCreate = "/groups"
        case fetchDetails = "/groups/%@"
        case members = "/groups/%@/members"
        case followers = "/groups/%@/followers"
        case admins = "/groups/%@/admins"
        case addAdmin = "/groups/%@/admins/%@"
        case fetchFeed = "/feed/group/%@"
        case rankedGroups = "/groups/rating"
        case recommendedGroups = "/groups/recommended"
        case events = "/groups/%@/events"
        case report = "/groups/%@/report"
        case bannedUsers = "/groups/%@/banned"
        case banUnbanUser = "/groups/%@/banned/%@"
        case removePlaceFromGroup = "/groups/%@/places/%@"
        case hideStories = "/groups/%@/hideStories"
        //subscriptions
        case subscriptionCommisionInfo = "/groups/subscription/info"
        case groupPurchases = "/groups/purchases/%@"
        case groupSubscription = "/groups/subscription/%@"
        case groupSubscriptionDetail = "/groups/subscription/%@/%@"
        case groupSubscribers = "/groups/subscription/%@/subscribers"
        case groupSubscriptionStatistics = "/groups/subscription/%@/%@/statistic"
        case groupPurchaseStatistics = "/groups/purchases/%@/%@/statistic"
        case groupSubscriptionActivate = "/groups/subscription/%@/activate"
        case groupSubscriptionDeactivate = "/groups/subscription/%@/deactivate"
    }
    enum place: String {
        case fetchCreate = "/places"
        case mapPlaces = "/places/map"
        case details = "/places/%@"
        case fetchFeed = "/feed/place/%@"
        case followUnfollow = "/places/%@/follow"
        case events = "/places/%@/events"
        case report = "/places/%@/report"
        case mapCurrentAddress = "/places-info"
        case ratePlace = "/places/rate"
    }
    enum feed: String {

        case newsFeed = "/feed/news"
        case nearbyFeed = "/feed/near" // previously
//        case nearbyFeed = "/feed/city"
//        case newsStories = "/feed/news/stories" previously
        case newsStories = "/feed/near/stories"
//        case nearbyStories = "/feed/near/stories" previously
        //case nearbyStories = "/feed/city/stories"
        case markStorySeen = "/feed/stories/%@/seen"
    
        
        
    }
    enum post: String {
        case fetchCreate = "/posts"
        case details = "/posts/%@"
        case comments = "/posts/%@/comments"
        case commentDetail = "/posts/%@/comments/%@"
        case likePost = "/posts/%@/like"
        case likeComment = "/posts/%@/comments/%@/like"
        case sharePost = "/posts/%@/share"
        case eventAttendees = "/events/%@/attendees"
        case attendEvent = "/events/%@/attend"
        case report = "/posts/%@/report"
    }
    enum notifications: String {
        case get = "/notifications"
        case setNotificationSeen = "/notifications/seen"
        case unreadNotificationCount = "/notifications/unreadcount"
        case deleteNotification = "/notifications/%@"
    }
    enum stripe: String {
        case get = "/stripe"
    }
    case baseDomainDevelopment = "https://backend-staging-dot-orbisv2-production.uc.r.appspot.com"
    case baseDomainProduction = "https://orbisv2-production.uc.r.appspot.com"
}

enum GetApiAddress {
    case auth(ApiLink.auth)
    case profile(ApiLink.profile, [String])
    case group(ApiLink.group, [String])
    case place(ApiLink.place, [String])
    case post(ApiLink.post, [String])
    case feed(ApiLink.feed, [String])
    case stripe(ApiLink.stripe, [String])
    case notifications(ApiLink.notifications, [String])
    var url: String {
        var domainUrl = ApiLink.baseDomainDevelopment.rawValue
        switch AppEnvironmentManager.shared.environment {
        case .staging:
            domainUrl = ApiLink.baseDomainDevelopment.rawValue
            break
        case .production:
            domainUrl = ApiLink.baseDomainProduction.rawValue
            break
        }
        switch self{
        case .auth(let ApilinkAddress):
            return "\(domainUrl)\(ApilinkAddress.rawValue)"
        case .profile(let ApilinkAddress, let values):
            let postFixAddress = String(format: ApilinkAddress.rawValue, arguments: values)
            return "\(domainUrl)\(postFixAddress)"
        case .group(let address, let values):
            let postFixAddress = String(format: address.rawValue, arguments: values)
            return "\(domainUrl)\(postFixAddress)"
        case .place(let address, let values):
            let postFixAddress = String(format: address.rawValue, arguments: values)
            return "\(domainUrl)\(postFixAddress)"
        case .post(let address, let values):
            let postFixAddress = String(format: address.rawValue, arguments: values)
            return "\(domainUrl)\(postFixAddress)"
        case .feed(let address, let values):
            let postFixAddress = String(format: address.rawValue, arguments: values)
            return "\(domainUrl)\(postFixAddress)"
        case .stripe(let address, let values):
            let postFixAddress = String(format: address.rawValue, arguments: values)
            return "\(domainUrl)\(postFixAddress)"
        case .notifications(let address, let values):
            let postFixAddress = String(format: address.rawValue, arguments: values)
            return "\(domainUrl)\(postFixAddress)"
        }
    }
}
