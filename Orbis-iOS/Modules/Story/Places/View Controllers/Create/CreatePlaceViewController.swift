//
//  CreatePlaceViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 04/04/2021.
//

import UIKit
import HWPanModal
import SDWebImage

class CreatePlaceViewController: OrbisLocalizableViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var publishAsMessageLabel: UILabel!
    @IBOutlet weak var createBtn: UIButton!
    
    @IBOutlet weak var publisherContainerView: RoundedView!
    @IBOutlet weak var publisherProPicView: UIImageView!
    @IBOutlet weak var publisherNameLabel: UILabel!
    @IBOutlet weak var placeTypeCollectionView: UICollectionView!
    @IBOutlet weak var publisherParentView: RoundedView!
    
    @IBOutlet weak var dropDownArrowView: UIView!
    @IBOutlet weak var placeNameTextField: UITextField!
    
    @IBAction func backTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func selectPublisherTapped(_ sender: Any) {
        let location = publisherContainerView.convert(publisherContainerView.bounds.origin, to: self.view)
        showDropDownUserList(inLocation: location, tappedViewFrame: publisherContainerView.bounds, leftRightVal: 15.toCGFloat.relativeToIphone8Width())
    }
    @IBAction func createTapped(_ sender: Any) {
        tryGoToNextScreen()
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
        let panGesturePoint = panGestureRecognizer.location(in: self.view)
        if let listView = self.dropDownListView {
            let tableViewFrame = listView.userListTableView.convert(listView.userListTableView.bounds, to: self.view)
            return !tableViewFrame.contains(panGesturePoint)
        }
        else {
            if placeTypeCollectionView.frame.contains(panGesturePoint) {
                return placeTypeCollectionView.contentOffset.y <= 0
            }
            return true
        }
    }
    
    private struct TypeCollectionViewConfig {
        static let numberOfItemsInRow = 4.toCGFloat
        static let cellSeparation = 8.toCGFloat.relativeToIphone8Width()
        static let leftInset = 15.toCGFloat.relativeToIphone8Width()
    }
    var viewModel: CreatePlaceViewModel!
    
    weak var dropDownListView: DropDownSearchListView?
    
    //var onCreateSuccess: ((OrbisPlace) -> Void)?
    var onCreateSuccess: ((PlaceDetails) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = CreatePlaceViewModel()
        setupCollectionView()
        updatePublisherInView()
        loadRecommendedGroups()
        updateStaticTexts()
    }
    
    override func updateStaticTexts() {
        titleLabel.text = AppStrings.Places.createPlaceTitle
        publishAsMessageLabel.text = AppStrings.Post.publishAsIndicator
        createBtn.setTitle(AppStrings.Places.createPlaceBtnText, for: .normal)
        placeNameTextField.placeholder = AppStrings.Places.placeNamePlaceholder
    }
    
    private func gotoCreatePlaceSelectLocationView(withViewModel model: CreatePlaceViewModel) {
        let createPlaceSelectLocationVC = UIStoryboard.getViewController(inStoryboard: "Places", identifier: "createPlaceSelectLocationVC") as! CreatePlaceSelectLocationVC
        createPlaceSelectLocationVC.viewModel = model
        createPlaceSelectLocationVC.modalPresentationStyle = .overCurrentContext
        createPlaceSelectLocationVC.onCreateSuccess = {
            [weak self] place in
            guard let self = self else { return }
            self.view.alpha = 0
            self.dismiss(animated: true) {
                [weak self] in
                self?.onCreateSuccess?(place)
            }
        }
        presentPanModal(createPlaceSelectLocationVC)
    }

    private func setupCollectionView() {
        placeTypeCollectionView.delegate = self
        placeTypeCollectionView.dataSource = self
        placeTypeCollectionView.reloadData()
        placeNameTextField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
    }
    
    private func updatePublisherInView() {
        publisherNameLabel.text = viewModel.publisherName
        publisherContainerView.borderWidth = viewModel.publisherBorderWidth
        publisherContainerView.borderColor = viewModel.groupBaseColor
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.publisherProPicLink.isEmpty else {
            publisherProPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.publisherProPicLink
        
        publisherProPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: (viewModel.publisher == nil) ? .groupPictures : .profilePictures, sizeModifier: .fourHundred)
    }
    
    private func updateUserSelection(user: OrbisUser) {
        viewModel.groupPublisher = nil
        viewModel.publisher = user
        updatePublisherInView()
    }
    
    private func updateGroupSelection(group: Group) {
        viewModel.publisher = nil
        viewModel.groupPublisher = group
        updatePublisherInView()
    }
    
    private func removePropicActionView() {
        dropDownListView?.removeFromSuperview()
        dropDownListView = nil
        UIView.animate(withDuration: 0.15) {
            [weak self] in
            self?.dropDownArrowView.transform = CGAffineTransform(rotationAngle: 0.toCGFloat.deg2rad)
        } completion: { (true) in
        }
    }
    
    private func loadRecommendedGroups() {
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.loadRecommendedGroups { [weak self] data, err in
            if let error = err {
                self?.handleError(error: error)
            }
            self?.hideOrbisLoader()
        }
    }
    
    private func showDropDownUserList(inLocation point: CGPoint, tappedViewFrame: CGRect, leftRightVal: CGFloat) {
        removePropicActionView()
        let userSelectDropDownList = DropDownSearchListView(frame: self.view.bounds)
        userSelectDropDownList.viewModel = DropdownSearchListViewModel(users: [], groups: viewModel.recommendedGroups)
        userSelectDropDownList.actionBtnContainer.alpha = 0
        self.view.addSubview(userSelectDropDownList)
        userSelectDropDownList.translatesAutoresizingMaskIntoConstraints = false
        userSelectDropDownList.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        userSelectDropDownList.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        userSelectDropDownList.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        userSelectDropDownList.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.view.bringSubviewToFront(userSelectDropDownList)
        let originY = point.y + tappedViewFrame.height - 5.toCGFloat
        userSelectDropDownList.btnTopConstraint.constant = originY
        userSelectDropDownList.btnLeadingConstraint.constant = leftRightVal
        userSelectDropDownList.btnTrailingConstraint.constant = leftRightVal
        userSelectDropDownList.actionBtnContainer.layoutIfNeeded()
        userSelectDropDownList.contentView.layoutIfNeeded()
        userSelectDropDownList.actionBtnContainer.isHidden = false
        self.dropDownListView = userSelectDropDownList
        self.dropDownListView?.onOutsideViewTapped = {
            [weak self] in
            self?.removePropicActionView()
        }
        self.dropDownListView?.onUserSelected = {
            [weak self] (user) in
            self?.removePropicActionView()
            self?.updateUserSelection(user: user)
        }
        self.dropDownListView?.onGroupSelected = {
            [weak self] (group) in
            self?.removePropicActionView()
            self?.updateGroupSelection(group: group)
        }
        self.dropDownListView?.onSearchReturnTap = {
            [weak self] text in
            self?.showSearchGroupView(withText: text)
        }
        UIView.animate(withDuration: 0.15) {
            [weak self] in
            self?.dropDownListView?.actionBtnContainer.alpha = 1
            self?.dropDownArrowView.transform = CGAffineTransform(rotationAngle: 180.toCGFloat.deg2rad)
        } completion: { (true) in
        }
    }
    
    private func showSearchGroupView(withText text: String) {
        let searchGroupVC = UIStoryboard.getViewController(inStoryboard: "Post", identifier: "searchGroupVC") as! SearchGroupViewController
        searchGroupVC.viewModel = GroupListViewModel(searchText: text)
        searchGroupVC.modalPresentationStyle = .overFullScreen
        searchGroupVC.onGroupSelect = {
            [weak self] group in
            self?.updateGroupSelection(group: group)
        }
        presentPanModal(searchGroupVC)
    }
    
    private func tryGoToNextScreen() {
        viewModel.validateFirstScreenFields { [weak self] success, err in
            guard let self = self else { return }
            if let error = err {
                self.handleError(error: error)
            }
            else {
                self.gotoCreatePlaceSelectLocationView(withViewModel: self.viewModel)
            }
        }
    }
    
    // MARK:- Text Field Delegate methods
    
    @objc private func textDidChange(_ textField: UITextField) {
        viewModel.placeName = textField.text ?? ""
    }
}

extension CreatePlaceViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard viewModel != nil else {
            return 0
        }
        return viewModel.typeCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "placeTypeItemCell", for: indexPath) as! PlaceTypeItemCollectionViewCell
        cell.itemImage = viewModel.placeTypes[indexPath.row].correspondingImage()
        cell.updateItemSelection(isSelected: viewModel.selectedTypeIndex == indexPath.row)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = ((collectionView.frame.width - (TypeCollectionViewConfig.leftInset * 2)) - ((TypeCollectionViewConfig.numberOfItemsInRow - 1) * TypeCollectionViewConfig.cellSeparation)) / TypeCollectionViewConfig.numberOfItemsInRow
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.toCGFloat.relativeToIphone8Width(), left: TypeCollectionViewConfig.leftInset, bottom: TypeCollectionViewConfig.leftInset, right: TypeCollectionViewConfig.leftInset)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return TypeCollectionViewConfig.cellSeparation
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return TypeCollectionViewConfig.cellSeparation
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let itemType = viewModel.placeTypes[indexPath.row]
        viewModel.selectedTypeIndex = indexPath.row
        viewModel.type = itemType
        collectionView.reloadData()
    }
}
