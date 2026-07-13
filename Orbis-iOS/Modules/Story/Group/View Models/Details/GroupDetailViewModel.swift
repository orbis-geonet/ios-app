//
//  GroupDetailViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 30/03/2021.
//

import Foundation
import UIKit
import Alamofire

class GroupDetailViewModel {
    var model: Group!
    let manager = GroupDetailManager()
    let eventManager = EventDetailManager()
    let mainAdminManager = AdminSubscriptionManager()
    
    private var groupAdmins = OrbisUsers()
    private var bannedUsers = OrbisUsers()
    var groupFeed: OrbisFeedPostResponses = []
    
    var onGroupDetailSyncError: ((Error) -> Void)?
    var onGroupDetailSyncSuccess: (() -> Void)?
    
    var onGroupJoinError: ((Error) -> Void)?
    
    var onGroupLeaveError: ((Error) -> Void)?
    var onGroupLeaveSuccess: (() -> Void)?
    
    var onGroupFollowError: ((Error) -> Void)?
    
    var onGroupUnfollowError: ((Error) -> Void)?
    
    var onGroupDeleteError: ((Error) -> Void)?
    var onGroupDeleteSuccess: (() -> Void)?
    
    var onGroupStoriesUnhideError: ((Error) -> Void)?
    
    var onGroupFeedFetched: (() -> Void)?
    var onGroupFeedFetchedCompletePagination: (() -> Void)?
    var onGroupFeedFetchError: ((Error) -> Void)?
    var onPostUpdated: (() -> Void)?
    
    var isEventsView: Bool = false
    
    var hasItemsLastPageReached = false
    var nextPageToken: String = ""
    private let offsetVal: Int = 50
    
    var onEventFeedFetched: (() -> Void)?
    var onEventFeedFetchedCompletePagination: (() -> Void)?
    var onEventFeedFetchError: ((Error) -> Void)?
    var onEventPostUpdated: (() -> Void)?
    
    var eventPosts = OrbisFeedPosts()
    var hasEventsItemLastPageReached = false
    var eventsPage: Int = 0
    private let eventsPageSize = 20
    
    var hasGroupAdminsLastPageReached = false
    var adminsPage: Int = 0
    private let adminsPageSize = 20
    
    var hasGroupBannedUsersLasPageReached = false
    var bannedUsersPage: Int = 0
    
    var eventPostsCount: Int {
        return eventPosts.count + 2 // +1 for header cell +1 for event header cell
    }
    
    func getEventPostModel(at index: Int) -> OrbisFeedPost {
        return eventPosts[index]
    }
    
    init(group: Group) {
        self.model = group
        initializePagination()
        initializeEventsPagination()
        fetchGroupAdmins()
        fetchBannedUsers()
    }
    
    func initializePagination() {
        groupFeed = OrbisSharedCreatePostManager.shared.pendingPosts.filter({$0.group?.groupKey == self.model.groupKey}).toPostListData
        hasItemsLastPageReached = false
        nextPageToken = ""
    }
    
    func initializeEventsPagination() {
        hasEventsItemLastPageReached = false
        eventPosts = []
        eventsPage = 0
    }
    
    var selfUser: OrbisUser? {
        return UserSessionManager.shared.currentUser
    }
    
    var isLoggedIn: Bool {
        if let user = selfUser, let key = user.userKey, !key.isEmpty {
            return true
        }
        return false
    }
    
    var unhideStoriesBtnText: String {
        return AppStrings.Group.MoreActionTexts.unhideStories
    }

    var activateSubscriptionBtnText: String {
        return AppStrings.Group.MoreActionTexts.activateSubscription
    }
    
    var deactivateSubscriptionBtnText: String {
        return AppStrings.Group.MoreActionTexts.deactivateSubscription
    }
    
    var deleteBtnText: String {
        return AppStrings.Group.MoreActionTexts.delete
    }
    
    var reportBtnText: String {
        return AppStrings.Group.MoreActionTexts.report
    }
    
    var leaveBtnText: String {
        return AppStrings.Group.MoreActionTexts.leave
    }
    
    var followUnfollowText: String {
        return hasFollowed ? AppStrings.Group.MoreActionTexts.unfollow : AppStrings.Group.MoreActionTexts.follow
    }
    
    var adminCount: Int {
        return model.adminsCount ?? 0
    }
    
    private var hasFollowed: Bool {
        let hasFollowed = model.isFollower ?? false
        return hasFollowed
    }
    
    var isStoriesHidden: Bool {
        return model.isStoriesHidden == true
    }
    
    var isBanned: Bool {
        return bannedUsers.contains(where: {$0.userKey == selfUser?.userKey})
    }
    
    var isSuperAdmin: Bool {
        return selfUser?.superAdmin ?? false
    }
    
    var isAdmin: Bool {
        return model.isAdmin ?? false
    }
    
    var isMember: Bool {
        let hasJoined = model.isMember ?? false
        return isAdmin || hasJoined
    }
    
    var isMainAdmin: Bool {
        return model.isMainAdmin ?? false
    }
    
    var hasSubscription: Bool {
        return model.hasSubscription ?? false
    }
    
    var isSubscriptionActive: Bool {
        return model.isSubscriptionActivate ?? false
    }
    
    var isSubscriber: Bool {
        return model.isSubscriber ?? false
    }
    
    var isNotInGroup: Bool {
        return !isMember && !isAdmin && !isMainAdmin
    }
    
    var memberShouldSeeSubscription: Bool {
        return isMember && !isAdmin && !isMainAdmin && isSubscriptionActive
    }
    
    var isFollower: Bool {
        let hasFollowed = model.isFollower ?? false
        return hasFollowed
    }
    
    var isLeaveBtnVisible: Bool {
        guard isMember else {
            return false
        }
        if isAdmin && ((model.membersCount ?? 0) < 1) {
            return false
        }
        return true
    }
    
    var shouldAssignAdminBeforeLeaving: Bool {
        guard isAdmin else {
            return false
        }
        guard adminCount == 1, let membersCount = model.membersCount, membersCount >= 1 else {
            return false
        }
        return true
    }
    
    var hasFeedPosts: Bool {
        if isEventsView {
            return eventPostsCount > 2
        }
        return feedCount > 2
    }
    
    var feedCount: Int {
        return groupFeed.count + 2 // +1 for header cell +1 for event/feed header
    }
    
    func updateSliderPageIndex(at index: Int, value: Int) {
        groupFeed[index].currentSliderPageIndex = value
    }
    
    func getFeedPostModel(at index: Int) -> OrbisFeedPostResponse {
        return groupFeed[index]
    }
    
    func getGroupAdmins() -> [String] {
        return self.groupAdmins.map({$0.userKey!})
    }
    
    func getBannedUsers() -> [String] {
        return self.bannedUsers.map({$0.userKey!})
    }
    
    func syncGroupDataWithServer() {
        manager.syncGroupDetail(forGroup: self.model.groupKey!) { [weak self] (data, err) in
            if let error = err {
                self?.onGroupDetailSyncError?(error)
                return
            }
            if let group = data as? Group {
                self?.model = group
                self?.onGroupDetailSyncSuccess?()
            }
            else {
                self?.onGroupDetailSyncError?(ResponseError.invalidData)
            }
        }
    }
    
    func tryJoinGroup() {
        guard !isMember else {
            onGroupJoinError?(OrbisGroupError.alreadyJoined)
            return
        }
        manager.tryJoinGroup(groupKey: self.model.groupKey!) { [weak self] (data, err) in
            if let error = err {
                self?.onGroupJoinError?(error)
            }
            else {
                self?.syncGroupDataWithServer()
            }
        }
    }
    
    func tryLeaveGroup() {
        guard isMember else {
            onGroupLeaveError?(OrbisGroupError.notAMember)
            return
        }
        manager.tryLeaveGroup(groupKey: self.model.groupKey!) { [weak self] (data, err) in
            if let error = err {
                self?.onGroupLeaveError?(error)
            }
            else {
                self?.onGroupLeaveSuccess?()
            }
        }
    }
    
    func tryAddNewAdminAndLeave(user: OrbisUser) {
        guard isMember else {
            onGroupLeaveError?(OrbisGroupError.notAMember)
            return
        }
        manager.tryAssignNewAdmin(groupKey: self.model.groupKey!, user: user) {  [weak self] (data, err) in
            if let error = err {
                self?.onGroupLeaveError?(error)
            }
            else {
                self?.tryLeaveGroup()
            }
        }
    }
    
    func tryFollowGroup() {
        guard !isFollower else {
            onGroupFollowError?(OrbisGroupError.alreadyFollowed)
            return
        }
        manager.tryFollowGroup(groupKey: self.model.groupKey!) { [weak self] (data, err) in
            if let error = err {
                self?.onGroupFollowError?(error)
            }
            else {
                self?.syncGroupDataWithServer()
            }
        }
    }
    
    func tryUnfollowGroup() {
        guard isFollower else {
            onGroupUnfollowError?(OrbisGroupError.notFollowed)
            return
        }
        manager.tryUnfollowGroup(groupKey: self.model.groupKey!) { [weak self] (data, err) in
            if let error = err {
                self?.onGroupUnfollowError?(error)
            }
            else {
                self?.syncGroupDataWithServer()
            }
        }
    }
    
    func tryDeleteGroup() {
        guard isAdmin else {
            onGroupDeleteError?(OrbisGroupError.notAuthorized)
            return
        }
        manager.tryDeleteGroup(groupKey: self.model.groupKey!) { [weak self] (data, err) in
            if let error = err {
                self?.onGroupDeleteError?(error)
            }
            else {
                self?.onGroupDeleteSuccess?()
            }
        }
    }
    
    func tryUnhideGroupStories() {
        guard isStoriesHidden else {
            onGroupStoriesUnhideError?(OrbisGroupError.alreadyUnhidden)
            return
        }
        manager.unhideStories(fromGroup: self.model.groupKey!) { [weak self] (data, err) in
            if let error = err {
                self?.onGroupStoriesUnhideError?(error)
            }
            else {
                self?.syncGroupDataWithServer()
            }
        }
    }
    
    func tryMakeRemoveAdmin(forUser user: OrbisUser, completion: @escaping responseBlock) {
        if groupAdmins.contains(where: {$0.userKey == user.userKey}) {
            manager.tryRemoveAdmin(fromGroup: model.groupKey!, user: user) { [weak self] data, err in
                if let error = err {
                    completion(nil, error)
                }
                else {
                    self?.groupAdmins.removeAll(where: {$0.userKey == user.userKey})
                    completion(true, nil)
                }
            }
        }
        else {
            manager.tryAssignNewAdmin(groupKey: model.groupKey!, user: user) { [weak self] data, err in
                guard let self = self else { return }
                if let error = err {
                    completion(nil, error)
                }
                else {
                    if !self.groupAdmins.contains(where: {$0.userKey == user.userKey}) {
                        self.groupAdmins.append(user)
                    }
                    completion(true, nil)
                }
            }
        }
    }
    
    private func fetchGroupAdmins() {
        guard !hasGroupAdminsLastPageReached else { return }
        manager.fetchGroupAdmins(forGroup: model.groupKey!, page: adminsPage, limit: adminsPageSize) { [weak self] data, err in
            guard let self = self else { return }
            if let users = data as? OrbisUsers {
                self.hasGroupAdminsLastPageReached = users.count == 0
                users.forEach { user in
                    if !self.groupAdmins.contains(where: {$0.userKey == user.userKey}) {
                        self.groupAdmins.append(user)
                    }
                }
                if users.count > 0 {
                    self.adminsPage += 1
                    self.fetchGroupAdmins()
                }
            }
            else if let error = err {
                debugPrint("Error in fetching group admins \(error.localizedDescription)")
            }
        }
    }
    
    func tryBanUnbanUserFromGroup(forUser user: OrbisUser, completion: @escaping responseBlock) {
        if bannedUsers.contains(where: {$0.userKey == user.userKey}) {
            manager.tryUnbanUser(fromGroup: model.groupKey!, user: user) { [weak self] data, err in
                if let error = err {
                    completion(nil, error)
                }
                else {
                    self?.bannedUsers.removeAll(where: {$0.userKey == user.userKey})
                    completion(true, nil)
                }
            }
        }
        else {
            manager.tryBanUser(fromGroup: model.groupKey!, user: user) { [weak self] data, err in
                guard let self = self else { return }
                if let error = err {
                    completion(nil, error)
                }
                else {
                    if !self.bannedUsers.contains(where: {$0.userKey == user.userKey}) {
                        self.bannedUsers.append(user)
                    }
                    completion(true, nil)
                }
            }
        }
    }
    
    private func fetchBannedUsers(){
        guard !hasGroupBannedUsersLasPageReached else { return }
        manager.fetchGroupBannedUsers(forGroup: model.groupKey!, page: bannedUsersPage, limit: adminsPageSize) { [weak self] data, err in
            guard let self = self else { return }
            if let users = data as? OrbisUsers {
                self.hasGroupBannedUsersLasPageReached = users.count == 0
                users.forEach { user in
                    if !self.bannedUsers.contains(where: {$0.userKey == user.userKey}) {
                        self.bannedUsers.append(user)
                    }
                }
                if users.count > 0 {
                    self.bannedUsersPage += 1
                    self.fetchBannedUsers()
                }
            }
            else if let error = err {
                debugPrint("Error in fetching group banned users \(error.localizedDescription)")
            }
        }
    }
    
    func loadGroupFeed() {
        self.manager.fetchGroupFeed(groupKey: self.model.groupKey!, from: nextPageToken, limit: offsetVal) { [weak self] (data, err) in
            guard let self = self else { return }
            if let error = err {
                let nsError = error as NSError
                if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                    return
                }
                self.onGroupFeedFetchError?(error)
                return
            }
            else {
                if let response = data as? OrbisFeedPaginatedResponse, let items = response.content {
                    if items.count > 0 {
                        self.groupFeed = (OrbisSharedCreatePostManager.shared.pendingPosts.filter({$0.group?.groupKey == self.model.groupKey})).toPostListData + items
                        self.onGroupFeedFetched?()
                        self.nextPageToken = response.nextPage ?? ""
                        self.hasItemsLastPageReached = false
                    }
                    else {
                        self.hasItemsLastPageReached = true
                        self.onGroupFeedFetchedCompletePagination?()
                    }
                }
                else {
                    self.hasItemsLastPageReached = true
                    self.onGroupFeedFetchedCompletePagination?()
                    return
                }
            }
        }
    }
    
    func loadMoreGroupFeed() {
        self.manager.fetchGroupFeed(groupKey: self.model.groupKey!, from: nextPageToken, limit: offsetVal)  { [weak self] (data, err) in
            if let error = err {
                if let afError = error as? AFError {
                    if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                        return
                    }
                }
                self?.onGroupFeedFetchError?(error)
                return
            }
            else {
                if let response = data as? OrbisFeedPaginatedResponse, let items = response.content {
                    if items.count > 0 {
                        self?.groupFeed.append(contentsOf: items)
                        self?.onGroupFeedFetched?()
                        self?.nextPageToken = response.nextPage ?? ""
                        self?.hasItemsLastPageReached = false
                    }
                    else {
                        self?.hasItemsLastPageReached = true
                        self?.onGroupFeedFetchedCompletePagination?()
                    }
                }
                else {
                    self?.hasItemsLastPageReached = true
                    self?.onGroupFeedFetchedCompletePagination?()
                    return
                }
            }
        }
    }
    
    func likeUnlikePost(post: OrbisFeedPost) {
        guard let _ = UserSessionManager.shared.currentUser else { return }
        let hasLiked = post.hasLiked ?? false
        if hasLiked {
            var updatedLikePost = post
            updatedLikePost.hasLiked = false
            updatedLikePost.decrementLike()
            self.updatePost(newPost: updatedLikePost)
            OrbisSharedPostLikeCommentManager.shared.unlikePost(key: post.postKey!) { [weak self] data, err in
                if let post = data as? OrbisFeedPost {
                    self?.updatePost(newPost: post)
                }
            }
        }
        else {
            var updatedLikePost = post
            updatedLikePost.hasLiked = true
            updatedLikePost.incrementLike()
            self.updatePost(newPost: updatedLikePost)
            OrbisSharedPostLikeCommentManager.shared.likePost(key: post.postKey!) { [weak self] data, err in
                if let post = data as? OrbisFeedPost {
                    self?.updatePost(newPost: post)
                }
            }
        }
    }
    
    func reportGroup(withText text: String, completion: @escaping responseBlock) {
        guard let _ = UserSessionManager.shared.currentUser else { return }
        manager.reportGroup(key: self.model.groupKey!, text: text, completion: completion)
    }
    
    func reportPost(post: OrbisFeedPost, withText text: String, completion: @escaping responseBlock) {
        guard let _ = UserSessionManager.shared.currentUser else { return }
        OrbisSharedPostLikeCommentManager.shared.reportPost(post: post, text: text, completion: completion)
    }
    
    func removePost(postKey: String) {
        if let postIndex = self.groupFeed.firstIndex(where: {$0.post?.postKey == postKey}) {
            self.groupFeed.remove(at: postIndex)
        }
        else if let postIndex = self.groupFeed.firstIndex(where: {$0.slider?.contains(where: {$0.postKey == postKey}) ?? false}), var postSlider = self.groupFeed[postIndex].slider, let sliderPostIndex = postSlider.firstIndex(where: {$0.postKey == postKey}) {
            postSlider.remove(at: sliderPostIndex)
            var postObject = self.groupFeed[postIndex]
            postObject.slider = postSlider
            self.groupFeed[postIndex] = postObject
        }
        if let postIndex = self.eventPosts.firstIndex(where: {$0.postKey == postKey})  {
            self.eventPosts.remove(at: postIndex)
        }
        onPostUpdated?()
    }
    
    func updatePost(newPost: OrbisFeedPost, notify: Bool = true) {
        if var postObject = self.groupFeed.first(where: {$0.post?.postKey == newPost.postKey}), let post = postObject.post, let postIndex = self.groupFeed.firstIndex(where: {$0.post?.postKey == post.postKey}) {
            postObject.post = newPost
            self.groupFeed[postIndex] = postObject
            notify ? onPostUpdated?() : ()
        }
        else if let postIndex = self.groupFeed.firstIndex(where: {$0.slider?.contains(where: {$0.postKey == newPost.postKey}) ?? false}), var postSlider = self.groupFeed[postIndex].slider, let sliderPostIndex = postSlider.firstIndex(where: {$0.postKey == newPost.postKey}) {
            postSlider[sliderPostIndex] = newPost
            var postObject = self.groupFeed[postIndex]
            postObject.slider = postSlider
            self.groupFeed[postIndex] = postObject
            notify ? onPostUpdated?() : ()
        }
        if let postIndex = self.eventPosts.firstIndex(where: {$0.postKey == newPost.postKey}) {
            self.eventPosts[postIndex] = newPost
            notify ? onPostUpdated?() : ()
        }
    }
    
    func updateCommentCount(key: String, count: Int) {
        updatePostsCommentCount(key: key, count: count)
    }
    
    private func updatePostsCommentCount(key: String, count: Int) {
        if var postObject = self.groupFeed.first(where: {$0.post?.postKey == key}), var post = postObject.post, let postIndex = self.groupFeed.firstIndex(where: {$0.post?.postKey == post.postKey}) {
            post.commentsCount = count
            postObject.post = post
            self.groupFeed[postIndex] = postObject
        }
        else if let postIndex = self.groupFeed.firstIndex(where: {$0.slider?.contains(where: {$0.postKey == key}) ?? false}), var postSlider = self.groupFeed[postIndex].slider, var sliderPost = postSlider.first(where: {$0.postKey == key}), let sliderPostIndex = postSlider.firstIndex(where: {$0.postKey == key}) {
            sliderPost.commentsCount = count
            postSlider[sliderPostIndex] = sliderPost
            var postObject = self.groupFeed[postIndex]
            postObject.slider = postSlider
            self.groupFeed[postIndex] = postObject
        }
    }
    
    
    func getIndex(for post: OrbisFeedPost) -> Int? {
        if let postObject = self.groupFeed.first(where: {$0.post?.postKey == post.postKey}), let post = postObject.post, let postIndex = self.groupFeed.firstIndex(where: {$0.post?.postKey == post.postKey}) {
            return postIndex
        }
        return nil
    }
    
    func replaceExpandedPost(expandedPost newPost: OrbisFeedPost) {
        if var postObject = self.groupFeed.first(where: {$0.post?.postKey == newPost.postKey}), let post = postObject.post, let postIndex = self.groupFeed.firstIndex(where: {$0.post?.postKey == post.postKey}) {
            postObject.post = newPost
            self.groupFeed[postIndex] = postObject
        }
        else if let postIndex = self.groupFeed.firstIndex(where: {$0.slider?.contains(where: {$0.postKey == newPost.postKey}) ?? false}), var postSlider = self.groupFeed[postIndex].slider, let sliderPostIndex = postSlider.firstIndex(where: {$0.postKey == newPost.postKey}) {
            postSlider[sliderPostIndex] = newPost
            var postObject = self.groupFeed[postIndex]
            postObject.slider = postSlider
            self.groupFeed[postIndex] = postObject
        }
    }
    
    // MARK:- Events
    
    func loadGroupEvents() {
        self.manager.fetchGroupEvents(groupKey: self.model.groupKey!, page: self.eventsPage, limit: self.eventsPageSize) { [weak self] (data, err) in
            guard let self = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                        return
                    }
                    if let afError = error as? AFError {
                        if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                            return
                        }
                    }
                    self.onEventFeedFetchError?(error)
                    return
                }
                else {
                    if let items = data as? OrbisFeedPosts {
                        if items.count > 0 {
                            self.eventPosts = items
                            self.onEventFeedFetched?()
                            self.eventsPage += 1
                            self.hasEventsItemLastPageReached = false
                        }
                        else {
                            self.hasEventsItemLastPageReached = true
                            self.onEventFeedFetchedCompletePagination?()
                        }
                    }
                    else {
                        self.onEventFeedFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
    
    func loadMoreGroupEvents() {
        self.manager.fetchGroupEvents(groupKey: self.model.groupKey!, page: self.eventsPage, limit: self.eventsPageSize) { [weak self] (data, err) in
            guard let self = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                        return
                    }
                    if let afError = error as? AFError {
                        if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                            return
                        }
                    }
                    self.onEventFeedFetchError?(error)
                    return
                }
                else {
                    if let items = data as? OrbisFeedPosts {
                        if items.count > 0 {
                            self.eventPosts.append(contentsOf: items)
                            self.onEventFeedFetched?()
                            self.eventsPage += 1
                            self.hasEventsItemLastPageReached = false
                        }
                        else {
                            self.hasEventsItemLastPageReached = true
                            self.onEventFeedFetchedCompletePagination?()
                        }
                    }
                    else {
                        self.onEventFeedFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
    
    func attendCancelAttendEvent(event: OrbisFeedPost, completion: @escaping responseBlock) {
        if event.attending == true {
            eventManager.cancelAttendEvent(key: event.postKey!) { [weak self] data, err in
                if let error = err {
                    completion(nil, error)
                }
                else {
                    var updatedEvent = event
                    updatedEvent.attending = false
                    self?.updatePost(newPost: updatedEvent)
                    completion(true, nil)
                }
            }
        }
        else {
            eventManager.attendEvent(key: event.postKey!) { [weak self] data, err in
                if let error = err {
                    completion(nil, error)
                }
                else {
                    var updatedEvent = event
                    updatedEvent.attending = true
                    self?.updatePost(newPost: updatedEvent)
                    completion(true, nil)
                }
            }
        }
    }
}

extension GroupDetailViewModel {
    
    func activateSubscription(completion: @escaping responseBlock) {
        guard let groupKey = self.model.groupKey else {
            completion(nil, nil)
            return
        }
        self.mainAdminManager.activateGroupSubscriptions(groupKey: groupKey) { [weak self] result, error in
            if let error = error {
                completion(result, error)
            } else {
                self?.model.isSubscriptionActivate = true
                completion(true, nil)
            }
        }
    }
    
    func deactivateSubscription(completion: @escaping responseBlock) {
        guard let groupKey = self.model.groupKey else {
            completion(nil, nil)
            return
        }
        self.mainAdminManager.deactivateGroupSubscriptions(groupKey: groupKey) { [weak self] result, error in
            if let error = error {
                completion(result, error)
            } else {
                self?.model.isSubscriptionActivate = false
                completion(true, nil)
            }
        }
    }
}
