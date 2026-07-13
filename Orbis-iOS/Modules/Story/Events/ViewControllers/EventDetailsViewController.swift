//
//  EventDetailsViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 18/04/2021.
//

import UIKit
import SDWebImage


class EventDetailsViewController: OrbisLocalizableViewController {

    @IBOutlet weak var actionBtn: UIButton!
    @IBOutlet weak var confirmedTextLabel: UILabel!
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var eventDateLabel: UILabel!
    @IBOutlet weak var eventTimeLabel: UILabel!
    @IBOutlet weak var eventDescriptionLabel: UILabel!
    @IBOutlet weak var eventAddressLabel: UILabel!
    @IBOutlet weak var eventAddressStackView: UIStackView!
    @IBOutlet weak var eventAddressParentStackView: UIStackView!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var confirmedCountLabel: UILabel!
    @IBOutlet weak var confirmationListView: UICollectionView!
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentScrollView: UIScrollView!
    
    @IBOutlet weak var actionBtnContainer: RoundedView!
    @IBOutlet weak var actionBtnLabel: UILabel!
    
    @IBAction func backTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func confirmTapped(_ sender: Any) {
        toggleHasConfirmed()
    }
    
    let heightOfStaticContents = 150.toCGFloat.relativeToIphone8Width() // height of confirm button, nav bar and margins
    var viewModel: EventDetailsViewModel!
    var onPostUpdated: ((OrbisFeedPost) -> Void)?
    
    override func topOffset() -> CGFloat {
        return 0
    }
    
    override func showDragIndicator() -> Bool {
        return false
    }

    override func shouldRespond(toPanModalGestureRecognizer panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        let panGesturePoint = panGestureRecognizer.location(in: self.view)
        if confirmationListView.frame.contains(panGesturePoint) {
            return false
        }
        if contentScrollView.frame.contains(panGesturePoint) {
            return contentScrollView.contentOffset.y <= 0
        }
        return true
    }
    
    var isConfirmedListLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        contentScrollView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        resetAttendees()
        fetchAttendees()
        handleViewModelActions()
        updateStaticTexts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateViewContent()
    }
    
    deinit {
        contentScrollView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    override func updateStaticTexts() {
        confirmedTextLabel.text = AppStrings.Events.confirmed + ":"
    }
    
    func handleViewModelActions() {
        viewModel.onConfirmedUsersFetched = {
            [weak self] in
            self?.updateConfirmedCountValue()
            self?.confirmationListView.reloadData()
            self?.hideOrbisLoader()
        }
        viewModel.onConfirmedUsersFetchedCompletePagination = {
            [weak self] in
            self?.updateConfirmedCountValue()
            self?.confirmationListView.reloadData()
            self?.hideOrbisLoader()
        }
        viewModel.onConfirmedUsersFetchError = {
            [weak self] error in
            self?.handleError(error: error)
            self?.hideOrbisLoader()
        }
    }
    
    func resetAttendees() {
        viewModel.initializeConfirmedUserPagination()
        confirmationListView.reloadData()
    }
    
    func fetchAttendees() {
        resetAttendees()
        isConfirmedListLoading = true
        self.showOrbisLoader()
        viewModel.loadConfirmedUsers()
    }
    
    func fetchMoreAttendees() {
        isConfirmedListLoading = true
        self.showOrbisLoader()
        viewModel.loadMoreConfirmedUsers()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let obj = object as? UIScrollView {
            if obj == self.contentScrollView && keyPath == "contentSize" {
                var newHeight = obj.contentSize.height
                let maxHeight = self.view.frame.size.height - (self.view.safeAreaInsets.top + self.view.safeAreaInsets.bottom)
                if (newHeight + heightOfStaticContents)  > maxHeight {
                    newHeight = (maxHeight - heightOfStaticContents)
                }
                scrollViewHeightConstraint.constant = newHeight
                contentScrollView.layoutIfNeeded()
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func setupCollectionView() {
        confirmationListView.delegate = self
        confirmationListView.dataSource = self
        
        let addressTapGesture = UITapGestureRecognizer(target: self, action: #selector(addressDidTap(_:)))
        self.eventAddressStackView.isUserInteractionEnabled = true
        eventAddressStackView.addGestureRecognizer(addressTapGesture)
    }
    
    @objc private func addressDidTap(_ sender: UITapGestureRecognizer) {
        guard let place = viewModel.model.place else { return }
        gotoPlaceDetailView(place: place)
    }
    
    private func gotoPlaceDetailView(place: OrbisPlace) {
        let placeDetailVC = UIStoryboard.getViewController(inStoryboard: "Places", identifier: "placeDetailVC") as! PlaceDetailViewController
        placeDetailVC.viewModel = PlaceDetailViewModel(place: place)
        self.navigationController?.pushViewController(placeDetailVC, animated: true)
    }
    
    private func toggleHasConfirmed() {
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.attendCancelAttendEvent { [weak self] data, err in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.confirmationListView.reloadData()
                self?.updateConfirmButtonUI()
                if let self = self {
                    self.onPostUpdated?(self.viewModel.model)
                }
            }
            self?.hideOrbisLoader()
        }
        
    }

    func updateViewContent() {
        eventNameLabel.text = viewModel.eventTitle
        eventDateLabel.text = viewModel.eventDate
        eventTimeLabel.text = viewModel.eventTime
        eventDescriptionLabel.text = viewModel.eventDescription
        eventDescriptionLabel.isHidden = viewModel.eventDescription.isEmpty
        imageView.isHidden = viewModel.eventImageLink.isEmpty
        eventAddressLabel.text = viewModel.eventAddress
        updateLinkedImage()
        updateConfirmButtonUI()
        confirmationListView.reloadData()
    }
    
    private func updateLinkedImage() {
        guard !viewModel.eventImageLink.isEmpty else {
            return
        }
        let imageLink = viewModel.eventImageLink
        if imageLink.isNotUrlLink {
            let ref = imageLink.getFirebaseReference(storage: .eventImages, imageSizeResolution: .sixEighty)
            imageView.sd_setImage(with: ref, maxImageSize: UInt64(AppValues.thousandHundrenMbInBytes), placeholderImage: nil, options: [.retryFailed])
        }
        else {
            imageView.sd_setImage(with: URL(string: imageLink)!, placeholderImage: nil)
        }
    }
    
    private func updateConfirmedCountValue() {
        confirmedCountLabel.text = "\(viewModel.confirmedCount)"
    }
    
    private func updateConfirmButtonUI() {
        let text = viewModel.hasConfirmed ? AppStrings.Events.going : AppStrings.Events.willGo
        let color = viewModel.hasConfirmed ? UIColor(named: AppColors.appPinkishGray.rawValue)! : UIColor(named: AppColors.appBlack.rawValue)!
        let textColor = viewModel.hasConfirmed ? UIColor(named: AppColors.appBlack.rawValue)! : UIColor.white
        self.actionBtnContainer.backgroundColor = color
        self.actionBtnLabel.text = text
        self.actionBtnLabel.textColor = textColor
        updateConfirmedCountValue()
    }

}

extension EventDetailsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard viewModel != nil else {
            return 0
        }
        let count = viewModel.userCount
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "userItemCell", for: indexPath) as! EventUserItemCollectionViewCell
        cell.viewModel = EventUserItemViewModel(user: viewModel.getUser(at: indexPath.row))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = 36.toCGFloat.relativeToIphone8Width()
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = viewModel.getUser(at: indexPath.row)
        gotoUserProfileView(withUser: user)
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 4.toCGFloat.relativeToIphone8Width(), left: 15.toCGFloat.relativeToIphone8Width(), bottom: 4.toCGFloat.relativeToIphone8Width(), right: 15.toCGFloat.relativeToIphone8Width())
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 15.toCGFloat.relativeToIphone8Width()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 15.toCGFloat.relativeToIphone8Width()
    }
}
