//
//  ProfilePhotosViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 01/04/2021.
//

import UIKit

class ProfilePhotosViewController: OrbisLocalizableViewController {

    @IBOutlet weak var emptyListView: UIView!
    @IBOutlet weak var emptyIndicatorIconView: UIImageView!
    @IBOutlet weak var emptyListMessageLabel: UILabel!
    
    @IBOutlet weak var photosContentView: UIView!
    @IBOutlet weak var photosCollectionView: UICollectionView!
    
    weak var parallexScrollDelegate: OrbisParallexScrollDelegate?
    var viewModel: ProfilePhotosViewModel!
    var isInstaPhotoLoading = false
    var isAppPhotoLoading = false
    
    private struct CollectionViewConfig {
        static let separatorWidth: CGFloat = 2
        static let numberOfItemsInRow: CGFloat = 3
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionViewsSetup()
        handleViewModelActions()
        addObservers()
        resetData()
        loadInstagramMedia()
        loadAppMedia()
        updateContentUI()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func updateStaticTexts() {
        emptyListMessageLabel.text = AppStrings.Profile.emptyPhotosMessage
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(didConnectInstagram(_:)), name: NSNotification.Name(AppNotificationKeys.userDidConnectInstagram), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didCompletePendingPost(_:)), name: NSNotification.Name(AppNotificationKeys.UserProfilePhotoUpload.pendingProfileMediaUploadSuccess), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didErrorOccuredInPendingPostCreation(_:)), name: NSNotification.Name(AppNotificationKeys.UserProfilePhotoUpload.pendingProfileMediaUploadFailure), object: nil)
    }
    
    @objc private func didConnectInstagram(_ notification: NSNotification) {
        resetData()
        loadInstagramMedia()
        loadAppMedia()
    }
    
    @objc private func didCompletePendingPost(_ notification: NSNotification) {
        guard let _ = notification.object as? UserProfileMedia else {
            viewModel.addPendingPhotos()
            self.photosCollectionView.reloadData()
            return
        }
        self.resetData()
        loadInstagramMedia()
        loadAppMedia()
    }
    
    @objc private func didErrorOccuredInPendingPostCreation(_ notification: NSNotification) {
        guard let object = notification.object as? (Error, UserProfileMedia) else { return }
        self.handleError(error: object.0)
        self.resetData()
        loadInstagramMedia()
        loadAppMedia()
    }
    
    func collectionViewsSetup() {
        photosCollectionView.register(UINib(nibName: "ProfilePhotoItemCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "photoItem")
        photosCollectionView.dataSource = self
        photosCollectionView.delegate = self
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleCellLongPress(sender:)))
        photosCollectionView.addGestureRecognizer(longTapGesture)
    }
    
    @objc private func handleCellLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            guard viewModel.isViewingSelf else { return }
            let touchPoint = sender.location(in: photosCollectionView)
            if let indexPath = photosCollectionView.indexPathForItem(at: touchPoint) {
                let model = viewModel.getPhotoModel(at: indexPath.row)
                guard let _ = UserSessionManager.shared.currentUser else { return }
                showProfilePhotoLongPressActions(forPhoto: model)
            }
        }
    }
    
    private func showProfilePhotoLongPressActions(forPhoto model: UserProfileMedia) {
        let actionSheetVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let removePhotoAction = UIAlertAction(title: AppStrings.Profile.removeUploadedPhotoTitle, style: .default) { [weak self] action in
            self?.performRemovePhotoFromProfile(model: model)
        }
        let cancelAction = UIAlertAction(title: AppStrings.cancel, style: .destructive, handler: nil)
        actionSheetVC.addAction(removePhotoAction)
        actionSheetVC.addAction(cancelAction)
        self.present(actionSheetVC, animated: true, completion: nil)
    }
    
    private func performRemovePhotoFromProfile(model: UserProfileMedia) {
        guard let pictureKey = model.pictureKey else { return }
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.removePhoto(key: pictureKey) { [weak self] result, error in
            if let err = error {
                self?.handleError(error: err)
            }
            else {
                self?.photosCollectionView.reloadData()
            }
            self?.hideOrbisLoader()
        }
    }
    
    func updateContentUI() {
        guard !isAppPhotoLoading && !isInstaPhotoLoading else {
            return
        }
        photosCollectionView.isHidden = viewModel.photosCount <= 0
        emptyListView.isHidden = viewModel.photosCount > 0
        emptyListMessageLabel.text = viewModel.emptyListText
        emptyIndicatorIconView.image = viewModel.emptyListImage
    }
    
    func resetData() {
        viewModel.initializeInstaMediaPagination()
        viewModel.initializeAppMediaPagination()
        isAppPhotoLoading = false
        isInstaPhotoLoading = false
        photosCollectionView.isHidden = false
        emptyListView.isHidden = true
        photosCollectionView.reloadData()
    }
    
    func loadInstagramMedia() {
        isInstaPhotoLoading = true
        self.parallexScrollDelegate?.showCommonLoader()
        viewModel.loadUserInstagramMedia()
    }
    
    func loadMoreInstagramMedia() {
        isInstaPhotoLoading = true
//        self.parallexScrollDelegate?.showCommonLoader()
        viewModel.loadMoreUserInstagramMedia()
    }
    
    func loadAppMedia() {
        isAppPhotoLoading = true
        self.parallexScrollDelegate?.showCommonLoader()
        viewModel.loadUserAppMedia()
    }
    
    func loadMoreAppMedia() {
        isAppPhotoLoading = true
//        self.parallexScrollDelegate?.showCommonLoader()
        viewModel.loadMoreUserAppMedia()
    }
    
    private func handleViewModelActions() {
        viewModel.onUserInstaMediaFetched = { [weak self] in
            self?.parallexScrollDelegate?.hideCommonLoader()
            DispatchQueue.main.async {
                [weak self] in
                self?.isInstaPhotoLoading = false
                self?.updateContentUI()
                self?.photosCollectionView.reloadData()
            }
        }
        viewModel.onUserInstaMediaFetchedCompletePagination = { [weak self] in
            self?.parallexScrollDelegate?.hideCommonLoader()
            DispatchQueue.main.async {
                [weak self] in
                self?.isInstaPhotoLoading = false
                self?.photosCollectionView.reloadData()
            }
        }
        viewModel.onUserInstaMediaFetchError = { [weak self] (error) in
            self?.parallexScrollDelegate?.hideCommonLoader()
//            DispatchQueue.main.async {
//                [weak self] in
//                self?.handleError(error: error)
//            }
            DispatchQueue.main.async {
                [weak self] in
                self?.isInstaPhotoLoading = false
                self?.updateContentUI()
            }
        }
        
        viewModel.onUserAppMediaFetched = { [weak self] in
            self?.parallexScrollDelegate?.hideCommonLoader()
            DispatchQueue.main.async {
                [weak self] in
                self?.isAppPhotoLoading = false
                self?.updateContentUI()
                self?.photosCollectionView.reloadData()
            }
        }
        viewModel.onUserAppMediaFetchedCompletePagination = { [weak self] in
            self?.parallexScrollDelegate?.hideCommonLoader()
            DispatchQueue.main.async {
                [weak self] in
                self?.isAppPhotoLoading = false
                self?.updateContentUI()
                self?.photosCollectionView.reloadData()
            }
        }
        viewModel.onUserAppMediaFetchError = { [weak self] (error) in
            self?.parallexScrollDelegate?.hideCommonLoader()
            DispatchQueue.main.async {
                [weak self] in
                self?.handleError(error: error)
            }
            DispatchQueue.main.async {
                [weak self] in
                self?.isAppPhotoLoading = false
                self?.updateContentUI()
            }
        }
    }

}

extension ProfilePhotosViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard viewModel != nil else {
            return 0
        }
        return viewModel.photosCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoItem", for: indexPath) as! ProfilePhotoItemCollectionViewCell
        let viewModel = ProfilePhotoItemViewModel(model: viewModel.getPhotoModel(at: indexPath.row))
        cell.viewModel = viewModel
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - ((CollectionViewConfig.numberOfItemsInRow - 1) * CollectionViewConfig.separatorWidth)) / CollectionViewConfig.numberOfItemsInRow
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.toCGFloat.relativeToIphone8Width(), left: 0, bottom: 115.toCGFloat.relativeToIphone8Width(), right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return CollectionViewConfig.separatorWidth
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return CollectionViewConfig.separatorWidth
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ProfilePhotoItemCollectionViewCell else { return }
        let viewModel = ProfilePhotoItemViewModel(model: viewModel.getPhotoModel(at: indexPath.row))
        guard !viewModel.isPendingMedia else { return }
        parallexScrollDelegate?.openFullSizeImage(imageView: cell.photoView, data: viewModel.model)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard viewModel.photosCount > 0 else { return }
        let loadMoreIndex = viewModel.photosCount - 1
        if indexPath.row == loadMoreIndex {
            if !viewModel.hasInstaMediaItemsLastPageReached {
                if !isInstaPhotoLoading {
                    loadMoreInstagramMedia()
                }
            }
            else {
                if !viewModel.hasAppMediaItemsLastPageReached {
                    if !isAppPhotoLoading {
                        loadMoreAppMedia()
                    }
                }
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        parallexScrollDelegate?.childScrollViewDidScroll(scrollView)
    }
}
