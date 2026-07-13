//
//  MessageListViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 20/04/2021.
//

import Foundation
import FirebaseFirestore
import Alamofire
import CodableFirebase

class MessageListViewModel {
    let manager = OrbisConversationManager()
    var conversations: OrbisConversationList = [] {
        didSet {
            conversations.removeAll(where: {$0.lastMessage == nil})
        }
    }
    var user: OrbisUser! {
        return UserSessionManager.shared.currentUser!
    }
    
    var conversationRef: CollectionReference! = Firestore.firestore().collection(FirebaseFirestoreNode.conversation.rawValue)
    
    var hasItemsLastPageReached = false
    var lastSnapshot: DocumentSnapshot?
    private let offsetVal: Int = 10
    
    var onConversationsFetched: (() -> Void)?
    var onConversationsFetchedCompletePagination: (() -> Void)?
    var onConversationsFetchError: ((Error) -> Void)?
    
    var onConversationItemUpdated: ((Int) -> Void)?
    var onNewConversationAdded: ((Int) -> Void)?
    
    var conversationListChangeListener: ListenerRegistration?
    var hasInitialDataLoaded = false
    
    init() {
        searchedUsers = []
        initializePagination()
        initializeUserSearchPagination()
        observerNewAndUpdateConversations()
    }
    
    deinit {
        conversationListChangeListener?.remove()
    }
    
    func initializePagination() {
        conversations = []
        hasItemsLastPageReached = false
        lastSnapshot = nil
    }
    
    func initializeUserSearchPagination() {
        searchedUsers = []
        hasUsersItemsLastPageReached = false
        usersListPageNumber = 0
        searchText = ""
    }
    
    private func observerNewAndUpdateConversations() {
        conversationListChangeListener = conversationRef
            .whereField(OrbisConversationParameterKeys.Conversation.participants, arrayContains: user.userKey!)
            .addSnapshotListener({ [weak self] snapshotData, err in
                if let snapshot = snapshotData, !snapshot.metadata.isFromCache {
                    if self?.hasInitialDataLoaded == false {
                        self?.hasInitialDataLoaded = true
                    }
                    else {
                        snapshot.documentChanges.forEach { [weak self] change in
                            self?.handleConversationUpdates(change: change)
                        }
                    }
                }
            })
    }
    
    private func handleConversationUpdates(change: DocumentChange) {
        let profileManager = UserProfileManager()
        switch change.type {
        case .added:
            let document = change.document
            guard var convo = try? FirestoreDecoder().decode(OrbisConversation.self, from: document.data()), convo.lastMessage != nil else { return }
            if let index = conversations.firstIndex(where: {$0.id == document.documentID}) {
                conversations[index].lastMessage = convo.lastMessage
                conversations[index].timestamp = convo.timestamp
                self.conversations.sort(by: {$0.timestamp! > $1.timestamp!})
                self.onConversationItemUpdated?(index)
                return
            }
            convo.id = document.documentID
            if let particpantId = convo.participants?.first(where: {$0 != user.userKey!}) {
                profileManager.syncProfileDetail(forUser: particpantId) { [weak self] data, err in
                    guard let self = self else { return }
                    if let user = data as? OrbisUser {
                        convo.updateParticipantUsers(users: [self.user, user])
                    }
                    else {
                        convo.updateParticipantUsers(users: [self.user, OrbisUser(key: UUID().uuidString, name: "Orbis User", proPicLink: nil)])
                        print("Error in fetching profile")
                    }
                    self.conversations.insert(convo, at: 0)
                    self.conversations.sort(by: {$0.timestamp! > $1.timestamp!})
                    self.onNewConversationAdded?(0)
                }
            }
            else {
                convo.updateParticipantUsers(users: [self.user, OrbisUser(key: UUID().uuidString, name: "Orbis User", proPicLink: nil)])
                conversations.insert(convo, at: 0)
                self.onNewConversationAdded?(0)
            }
            
        case .modified:
            let document = change.document
            guard var convo = try? FirestoreDecoder().decode(OrbisConversation.self, from: document.data()) else { return }
            if let index = conversations.firstIndex(where: {$0.id == document.documentID}) {
                conversations[index].lastMessage = convo.lastMessage
                conversations[index].timestamp = convo.timestamp
                self.conversations.sort(by: {$0.timestamp! > $1.timestamp!})
                self.onConversationItemUpdated?(index)
                return
            }
            convo.id = document.documentID
            if let particpantId = convo.participants?.first(where: {$0 != user.userKey!}) {
                profileManager.syncProfileDetail(forUser: particpantId) { [weak self] data, err in
                    guard let self = self else { return }
                    if let user = data as? OrbisUser {
                        convo.updateParticipantUsers(users: [self.user, user])
                    }
                    else {
                        convo.updateParticipantUsers(users: [self.user, OrbisUser(key: UUID().uuidString, name: "Orbis User", proPicLink: nil)])
                        print("Error in fetching profile")
                    }
                    self.conversations.insert(convo, at: 0)
                    self.conversations.sort(by: {$0.timestamp! > $1.timestamp!})
                    self.onNewConversationAdded?(0)
                }
            }
            else {
                convo.updateParticipantUsers(users: [self.user, OrbisUser(key: UUID().uuidString, name: "Orbis User", proPicLink: nil)])
                conversations.insert(convo, at: 0)
                conversations.sort(by: {$0.timestamp! > $1.timestamp!})
                self.onNewConversationAdded?(0)
            }
            
        default:
            return
        }
    }
    
    var isSearchView: Bool {
        return !searchText.isEmpty
    }
    
    var conversationsCount: Int {
        return conversations.count
    }
    
    var usersCount: Int {
        return searchedUsers.count
    }
    
    func getConversation(at index: Int) -> OrbisConversation {
        return conversations[index]
    }
    
    func getUser(at index: Int) -> OrbisUser {
        return searchedUsers[index]
    }
    
    var selfProPicLink: String {
        return user.proPicLink ?? ""
    }
    
    func fetchConversations() {
        initializePagination()
        manager.fetchUserConversationList(forUser: user.userKey!, lastSnapshot: lastSnapshot, limit: offsetVal) { [ weak self] data, err in
            guard let self = self else { return }
            if let error = err {
                self.onConversationsFetchError?(error)
                return
            }
            if let items = data as? ConversationListResponse {
                if items.conversations.count > 0 {
                    self.conversations = items.conversations
                    self.lastSnapshot = items.documents.last
                    self.hasItemsLastPageReached = false
                    self.onConversationsFetched?()
                }
                else {
                    self.hasItemsLastPageReached = true
                    self.onConversationsFetchedCompletePagination?()
                }
                
            }
            else {
                self.onConversationsFetchError?(ResponseError.invalidData)
            }
        }
    }
    
    func fetchMoreConversations() {
        manager.fetchUserConversationList(forUser: user.userKey!, lastSnapshot: lastSnapshot, limit: offsetVal) { [ weak self] data, err in
            guard let self = self else { return }
            if let error = err {
                self.onConversationsFetchError?(error)
                return
            }
            if let items = data as? ConversationListResponse {
                if items.conversations.count > 0 {
                    items.conversations.forEach { conversation in
                        if let index = self.conversations.firstIndex(where: {$0.id == conversation.id}) {
                            self.conversations[index] = conversation
                        }
                        else {
                            self.conversations.append(conversation)
                        }
                    }
                    self.lastSnapshot = items.documents.last
                    self.hasItemsLastPageReached = false
                    self.onConversationsFetched?()
                }
                else {
                    self.hasItemsLastPageReached = true
                    self.onConversationsFetchedCompletePagination?()
                }
            }
            else {
                self.onConversationsFetchError?(ResponseError.invalidData)
            }
        }
    }
    
    func getCreatedConversation(withUser user: OrbisUser, completion: @escaping responseBlock) {
        manager.createConversation(ofUser: self.user, withUser: user, completion: completion)
    }
    
    // MARK:- Users search
    
    let searchManager = UserSearchManager()
    var searchedUsers: OrbisUsers = []
    var searchText: String = ""
    
    var hasUsersItemsLastPageReached = false
    var usersListPageNumber: Int = 0
    
    var onUsersFetched: (() -> Void)?
    var onUsersFetchLateResponse: (() -> Void)?
    var onUsersFetchedCompletePagination: (() -> Void)?
    var onUsersFetchError: ((Error) -> Void)?
    
    func loadUsers() {
        guard !searchText.isEmpty else {
            initializeUserSearchPagination()
            self.onUsersFetched?()
            return
        }
        searchManager.invalidateSearchProfileSession { [weak self] (_, _) in
            guard let self = self else { return }
            self.searchManager.searchProfile(searchText: self.searchText, page: self.usersListPageNumber, limit: self.offsetVal) { [weak self] (data, err) in
                    guard let strongSelf2 = self else { return }
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
                        self?.onUsersFetchError?(error)
                        return
                    }
                    else {
                        if let items = data as? UserSearchResult {
                            if items.searchText != self?.searchText {
                                self?.onUsersFetchLateResponse?()
                                return
                            }
                            if items.users.count > 0 {
                                self?.searchedUsers = items.users
                                self?.onUsersFetched?()
                                self?.usersListPageNumber = strongSelf2.usersListPageNumber + 1
                                self?.hasUsersItemsLastPageReached = false
                            }
                            else {
                                self?.hasUsersItemsLastPageReached = true
                                self?.onUsersFetchedCompletePagination?()
                            }
                        }
                        else {
                            self?.onUsersFetchError?(ResponseError.invalidData)
                            return
                        }
                    }
            }
        }
    }
    
    func loadMoreUsers() {
        self.searchManager.searchProfile(searchText: self.searchText, page: self.usersListPageNumber, limit: self.offsetVal) { [weak self] (data, err) in
                guard let strongSelf2 = self else { return }
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
                    self?.onUsersFetchError?(error)
                    return
                }
                else {
                    if let items = data as? UserSearchResult {
                        if items.searchText != self?.searchText {
                            self?.onUsersFetchLateResponse?()
                            return
                        }
                        if items.users.count > 0 {
                            self?.searchedUsers.append(contentsOf: items.users)
                            self?.onUsersFetched?()
                            self?.usersListPageNumber = strongSelf2.usersListPageNumber + 1
                            self?.hasUsersItemsLastPageReached = false
                        }
                        else {
                            self?.hasUsersItemsLastPageReached = true
                            self?.onUsersFetchedCompletePagination?()
                        }
                    }
                    else {
                        self?.onUsersFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
}
