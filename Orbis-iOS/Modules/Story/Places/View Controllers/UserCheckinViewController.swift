//
//  UserCheckinViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 08/04/2021.
//

import UIKit
import IQKeyboardManager

class UserCheckinViewController: OrbisLocalizableViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var checkinResultView: UITableView!
    @IBOutlet weak var createBtn: UIButton!
    
    @IBAction func backTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func searchIconTapped(_ sender: Any) {
        searchTextField.becomeFirstResponder()
    }
    @IBAction func createPlaceTapped(_ sender: Any) {
        self.dismiss(animated: true) {
            [weak self] in
            self?.onCreatePlaceTapped?()
        }
    }
    
    var viewModel: UserPlacesListViewModel!
    var onCheckinSelect: ((OrbisPlace) -> Void)?
    var onCreatePlaceTapped: (() -> Void)?
    var isLoading = false
    var searchTimer = Timer()
    
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
        let panGesturePoint = panGestureRecognizer.location(in: self.view)
        if checkinResultView.frame.contains(panGesturePoint) {
            return checkinResultView.contentOffset.y <= 0
        }
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = UserPlacesListViewModel()
        setupTableView()
        resetData()
        loadData()
        handleViewModelActionHandlers()
        updateStaticTexts()
    }
    
    override func updateStaticTexts() {
        titleLabel.text = AppStrings.Checkin.checkinTitle
        searchTextField.placeholder = AppStrings.Checkin.checkinSearchPlaceholder
        createBtn.setTitle(AppStrings.Places.createPlaceBtnText, for: .normal)
    }
    
    func setupTableView() {
        checkinResultView.dataSource = self
        checkinResultView.delegate = self
        checkinResultView.reloadData()
        searchTextField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
    }
    
    func resetData() {
        viewModel.initializePagination()
        isLoading = false
        checkinResultView.reloadData()
    }
    
    func loadData() {
        isLoading = true
        self.showOrbisLoader()
        viewModel.loadOrbisPlaces()
    }
    
    func loadMore() {
        isLoading = true
        self.showOrbisLoader()
        viewModel.loadMoreOrbisPlaces()
    }
    
    private func handleViewModelActionHandlers() {
        viewModel.onPlacesFetched = { [weak self] in
            self?.hideOrbisLoader()
            self?.checkinResultView.reloadData()
            self?.isLoading = false
        }
        viewModel.onPlacesFetchedCompletePagination = { [weak self] in
            self?.hideOrbisLoader()
            self?.checkinResultView.reloadData()
            self?.isLoading = false
        }
        viewModel.onPlacesFetchLateResponse = {
            [weak self] in
            self?.hideOrbisLoader()
        }
        viewModel.onPlacesFetchError = { [weak self] (error) in
            self?.hideOrbisLoader()
            self?.handleError(error: error)
            self?.isLoading = false
        }
    }
    
    private func openCheckinPostPage(withPlace place: OrbisPlace) {
        let createPostVC = UIStoryboard.getViewController(inStoryboard: "Post", identifier: "createPostVC") as! CreatePostViewController
        let viewModel = CreatePostViewModel(defaultPublisherGroup: place.dominantGroup ?? place.competingGroups?.first)
        viewModel.postPlace = place
        createPostVC.viewModel = viewModel
        createPostVC.defaultPostType = .checkinPost
        createPostVC.createPostInvoker = CreatePostInvoker.place
        createPostVC.shouldDisableDropDownAction = false
        createPostVC.shouldDisablePlaceSelection = true
        createPostVC.onCreatePostSuccess = {
            [weak self] data in
            if let feedPost = data as? OrbisFeedPost, let placeKey = feedPost.place?.placeKey, CreatePlaceSharedManager.shared.newlyCreatedListContains(key: placeKey){
                self?.handleCheckinSuccess(withPost: feedPost)
            }
            else if let placeData = data as? OrbisPlace {
                self?.gotoPlaceDetailView(place: placeData)
            }
            self?.dismiss(animated: true)
        }
        createPostVC.modalPresentationStyle = .overFullScreen
        presentPanModal(createPostVC)
    }
    
    private func gotoPlaceDetailView(place: OrbisPlace) {
        guard let keyWindow = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first else { return }
        guard let rootNavVC = keyWindow.rootViewController as? UINavigationController else { return }
        if let homeVC = rootNavVC.viewControllers.first as? HomeMapViewController {
            homeVC.gotoPlaceDetailView(viewModel: PlaceDetailViewModel(place: place))
        }
    }
    
    private func handleCheckinSuccess(withPost post: OrbisFeedPost) {
        guard var place = post.place else { return }
        guard let keyWindow = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first else { return }
        guard let rootNavVC = keyWindow.rootViewController as? UINavigationController else { return }
        place.lastSize = 500
        place.lastCheckInTimestamp = Date().iso8601withFractionalSeconds
        if place.lastSizeChangeTimestamp == nil {
            place.lastSizeChangeTimestamp = place.lastCheckInTimestamp
        }
        if place.dominantGroup == nil {
            place.dominantGroup = post.group
            place.dominantGroupKey = post.group?.groupKey
        }
        
        if post.checkInPolygonCoordinateKey != nil {
            place.checkInPolygonCoordinateKey = post.checkInPolygonCoordinateKey
        }
        
        if let homeVC = rootNavVC.viewControllers.first as? HomeMapViewController {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
                homeVC.handlePlaceCheckinSuccess(place: place)
            }
        }
    }
    
    // MARK:- Text Field Delegate methods
    @objc private func textDidChange(_ textField: UITextField) {
        searchTimer.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { [weak self] (timer) in
            self?.resetData()
            self?.viewModel.searchText = textField.text ?? ""
            self?.showOrbisLoader()
            self?.viewModel.loadOrbisPlaces()
        })
    }
}

extension UserCheckinViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0}
        return viewModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewModel.getPlaceItem(at: indexPath.row)
        let imageLink = viewModel.getImageLink(at: indexPath.row)
        if imageLink.isEmpty {
            let checkinItemCell = tableView.dequeueReusableCell(withIdentifier: "checkinItemCell") as! SearchedCheckinItemTableViewCell
            checkinItemCell.viewModel = CheckinPlaceItemViewModel(place: model, isBorderless: true)
            return checkinItemCell
        }
        else {
            let checkinItemCell = tableView.dequeueReusableCell(withIdentifier: "checkinItemWithImageCell") as! SearchedCheckinItemTableViewCellWithImage
            checkinItemCell.viewModel = CheckinPlaceItemViewModel(place: model)
            return checkinItemCell
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = viewModel.getPlaceItem(at: indexPath.row)
//        self.dismiss(animated: true) { [weak self] in
//            self?.onCheckinSelect?(model)
//        }
        openCheckinPostPage(withPlace: model)
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
        let loadMoreIndex = viewModel.count - 1
        if indexPath.row == loadMoreIndex && !isLoading && !viewModel.hasItemsLastPageReached {
            self.loadMore()
        }
    }
}
