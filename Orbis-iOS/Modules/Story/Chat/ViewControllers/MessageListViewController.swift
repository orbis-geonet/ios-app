//
//  MessageListViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 20/04/2021.
//

import UIKit


class MessageListViewController: OrbisLocalizableViewController {

    @IBOutlet weak var userProPicView: UIImageView!
    @IBOutlet weak var userProPicContainerView: RoundedView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var usersTableView: UITableView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func searchTapped(_ sender: Any) {
        searchTextField.becomeFirstResponder()
    }
    
    var isMessagesLoading = false
    var isUserSearching = false
    var viewModel: MessageListViewModel!
    var searchTimer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        viewModel = MessageListViewModel()
        handleViewModelActionHandlers()
        updateViewScene()
        searchTextField.addTarget(self, action: #selector(searchTextDidChange(_:)), for: .editingChanged)
        updateProfilePic()
        resetData()
        loadConversationsData()
        updateStaticTexts()
    }
    
    override func updateStaticTexts() {
        titleLabel.text = AppStrings.Messaging.messagesTitle
        searchTextField.placeholder = AppStrings.search
    }
    
    @objc private func searchTextDidChange(_ sender: UITextField) {
        searchTimer.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { [weak self] (timer) in
            self?.resetSearchData()
            self?.viewModel.searchText = self?.searchTextField.text ?? ""
            self?.updateViewScene()
            self?.searchUsers()
        })
    }
    
    private func handleViewModelActionHandlers() {
        viewModel.onConversationsFetched = { [weak self] in
            self?.hideOrbisLoader()
            self?.updateViewScene()
            self?.tableView.reloadData()
            self?.isMessagesLoading = false
        }
        viewModel.onConversationsFetchedCompletePagination = { [weak self] in
            self?.hideOrbisLoader()
            self?.updateViewScene()
            self?.tableView.reloadData()
            self?.isMessagesLoading = false
        }
        viewModel.onConversationsFetchError = { [weak self] (error) in
            self?.hideOrbisLoader()
            self?.handleError(error: error)
            self?.isMessagesLoading = false
        }
        
        viewModel.onUsersFetched = { [weak self] in
            self?.hideOrbisLoader()
            self?.updateViewScene()
            self?.usersTableView.reloadData()
            self?.isUserSearching = false
        }
        viewModel.onUsersFetchedCompletePagination = { [weak self] in
            self?.hideOrbisLoader()
            self?.updateViewScene()
            self?.usersTableView.reloadData()
            self?.isUserSearching = false
        }
        viewModel.onUsersFetchLateResponse = {
            [weak self] in
            self?.hideOrbisLoader()
            self?.isUserSearching = false
        }
        viewModel.onUsersFetchError = { [weak self] (error) in
            self?.hideOrbisLoader()
            self?.handleError(error: error)
            self?.isUserSearching = false
        }
        
        viewModel.onConversationItemUpdated = { [weak self] position in
            self?.tableView.reloadData()
        }
        
        viewModel.onNewConversationAdded = { [weak self] position in
            self?.tableView.setContentOffset(.zero, animated: true)
            self?.tableView.reloadData()
        }
    }
    
    func resetData() {
        viewModel.initializePagination()
        isMessagesLoading = false
        tableView.reloadData()
    }
    
    func loadConversationsData() {
        isMessagesLoading = true
        self.showOrbisLoader()
        viewModel.fetchConversations()
    }
    
    func loadMoreConversations() {
        isMessagesLoading = true
        self.showOrbisLoader()
        viewModel.fetchMoreConversations()
    }
    
    func resetSearchData() {
        viewModel.initializeUserSearchPagination()
        isUserSearching = false
        tableView.reloadData()
    }
    
    func searchUsers() {
        isUserSearching = true
        self.showOrbisLoader()
        viewModel.loadUsers()
    }
    
    func searchMore() {
        isUserSearching = true
        self.showOrbisLoader()
        viewModel.loadMoreUsers()
    }
    
    private func updateViewScene() {
        titleLabel.text = viewModel.isSearchView ? AppStrings.results : AppStrings.Messaging.messagesTitle
        userProPicContainerView.isHidden = viewModel.isSearchView
        usersTableView.isHidden = !viewModel.isSearchView
        tableView.isHidden = viewModel.isSearchView
    }
    
    private func updateProfilePic() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.selfProPicLink.isEmpty else {
            userProPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.selfProPicLink
        userProPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .profilePictures, sizeModifier: .fourHundred)
        
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        usersTableView.delegate = self
        usersTableView.dataSource = self
        
        let selfUserTapAction = UITapGestureRecognizer(target: self, action: #selector(selfUserHeadTapped(_:)))
        userProPicContainerView.isUserInteractionEnabled = true
        userProPicContainerView.addGestureRecognizer(selfUserTapAction)
    }
    
    @objc private func selfUserHeadTapped(_ sender: Any) {
        gotoUserProfileView(withUser: viewModel.user)
    }
}

extension MessageListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0}
        if tableView == self.usersTableView {
            return viewModel.usersCount
        }
        return viewModel.conversationsCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.usersTableView {
            guard viewModel.usersCount > 0 else { return UITableViewCell(frame: .zero)}
            let cell = tableView.dequeueReusableCell(withIdentifier: "userItemCell") as! MessageUserSearchItemTableViewCell
            cell.viewModel = MessageSearchedUserViewModel(user: viewModel.getUser(at: indexPath.row))
            return cell
        }
        else {
            guard viewModel.conversationsCount > 0 else { return UITableViewCell(frame: .zero)}
            let cell = tableView.dequeueReusableCell(withIdentifier: "messageItemCell") as! ConversationItemTableViewCell
            cell.viewModel = ConversationListItemViewModel(conversation: viewModel.getConversation(at: indexPath.row))
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15.toCGFloat.relativeToIphone8Width()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear
        return header
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView == usersTableView {
            let loadMoreIndex = viewModel.usersCount - 1
            if indexPath.row == loadMoreIndex && !isUserSearching && !viewModel.hasUsersItemsLastPageReached {
                self.searchMore()
            }
        }
        else {
            let loadMoreIndex = viewModel.conversationsCount - 1
            if indexPath.row == loadMoreIndex && !isMessagesLoading && !viewModel.hasItemsLastPageReached {
                self.loadMoreConversations()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == usersTableView {
            let user = viewModel.getUser(at: indexPath.row)
            createConversationIfNeeded(withUser: user)
        }
        else {
            let conversation = viewModel.getConversation(at: indexPath.row)
            gotoConversationView(with: conversation)
        }
    }
    
    private func createConversationIfNeeded(withUser user: OrbisUser) {
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.getCreatedConversation(withUser: user) { [weak self] data, err in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                if let conversation = data as? OrbisConversation {
                    self?.gotoConversationView(with: conversation)
                }
            }
            self?.hideOrbisLoader()
        }
    }
    
    func gotoConversationView(with object: OrbisConversation) {
        let conversationVC = UIStoryboard.getViewController(inStoryboard: "Chat", identifier: "conversationVC") as! ConversationViewController
        conversationVC.viewModel = ConversationViewModel(conversation: object)
        self.navigationController?.pushViewController(conversationVC, animated: true)
    }
    
    private func gotoUserProfileView(withUser user: OrbisUser) {
        if user.deleted == true  {
            UIUtil.showGlobalToast(message: AppStrings.userHasBeenDeleted)
            return
        }
        let isViewingSelf = (user.userKey == UserSessionManager.shared.currentUser?.userKey)
        let profileVC = UIStoryboard.getViewController(inStoryboard: "Profile", identifier: "userProfileVC") as! UserProfileViewController
        profileVC.viewModel = ProfileDetailViewModel(user: user, isViewingSelf: isViewingSelf)
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
}
