//
//  CreateEventViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 18/04/2021.
//

import UIKit
import KMPlaceholderTextView
import SDWebImage

class CreateEventViewController: OrbisLocalizableViewController {

    @IBOutlet weak var yourEventLabel: UILabel!
    @IBOutlet weak var wouldPublishAsMessageLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var publisherContainerView: RoundedView!
    @IBOutlet weak var publisherProPicView: UIImageView!
    @IBOutlet weak var publisherNameLabel: UILabel!
    @IBOutlet weak var dropDownArrowView: UIView!
    
    @IBOutlet weak var eventTitleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: KMPlaceholderTextView!
    @IBOutlet weak var eventAddressTextField: UITextField!
    @IBOutlet weak var eventDateTextField: UITextField!
    @IBOutlet weak var eventTimeStartTextField: UITextField!
    @IBOutlet weak var eventTimeEndTextField: UITextField!
    @IBOutlet weak var publishBtn: UIButton!
    
    @IBOutlet weak var photoTypeSectionView: UIView!
    @IBOutlet weak var photoTypeIndicatorImageView: UIImageView!
    @IBOutlet weak var photoTypeIndicatorLabel: UILabel!
    @IBOutlet weak var postTypeIndicatorContainer: RoundedView!
    
    @IBOutlet weak var imageTypeContentView: UIView!
    @IBOutlet weak var eventImageView: UIImageView!
    
    @IBAction func backTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func selectPublisherTapped(_ sender: Any) {
        guard !shouldDisableDropDownAction else { return }
        let location = publisherContainerView.convert(publisherContainerView.bounds.origin, to: self.view)
        showDropDownUserList(inLocation: location, tappedViewFrame: publisherContainerView.bounds, leftRightVal: 15.toCGFloat.relativeToIphone8Width())
    }
    @IBAction func createTapped(_ sender: Any) {
        tryCreateEventPost()
    }
    @IBAction func photoTypeBtnTapped(_ sender: Any) {
        openImagePickerView()
    }
    @IBAction func imageTypeViewCloseTapped(_ sender: Any) {
        viewModel.isEventModelPhotoMode = false
        viewModel.postImages = []
        viewModel.postImagesData = []
        updateEventImageAvailabilityUI()
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
        if isDateTimePickerVisible {
            return false
        }
        if mainScrollView.frame.contains(panGesturePoint) {
            return mainScrollView.contentOffset.y <= 0
        }
        return true
    }
    
    var viewModel: CreatePostViewModel!
    var shouldDisableDropDownAction: Bool = false
    var shouldDisablePlaceSelection: Bool = false
    
    var onCreatePostSuccess: ((Any?) -> Void)?
    
    var config: YPImagePickerConfiguration!
    var imagePickerController: YPImagePicker!
    var defaultPostType: OrbisPostType = .eventPost
    var isDateTimePickerVisible = false
    
    weak var dropDownListView: DropDownSearchListView?
    var dateTimePicker = RPicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextFields()
        viewModel.type = defaultPostType
        viewModel.isCheckinPost = false
        updateStaticTexts()
        updatePublisherInView()
        updateEventImageAvailabilityUI()
        if !shouldDisableDropDownAction {
            loadRecommendedGroups()
        }
    }
    
    override func updateStaticTexts() {
        titleLabel.text = AppStrings.Events.Create.title
        wouldPublishAsMessageLabel.text = AppStrings.Post.publishAsIndicator
        yourEventLabel.text = AppStrings.Events.Create.yourEvent
        eventTitleTextField.placeholder = AppStrings.Events.Create.eventTitlePlaceholder
        eventAddressTextField.placeholder = AppStrings.Events.Create.eventAddressPlaceholder
        eventDateTextField.placeholder = AppStrings.Events.Create.eventDatePlaceholder
        eventTimeStartTextField.placeholder = AppStrings.Events.Create.eventTimeStartPlaceholder
        eventTimeEndTextField.placeholder = AppStrings.Events.Create.eventTimeEndPlaceholder
        descriptionTextView.placeholder = AppStrings.Events.Create.eventDescriptionPlaceholder
        photoTypeIndicatorLabel.text = AppStrings.Post.photoType
        publishBtn.setTitle(AppStrings.Events.Create.publishBtnText, for: .normal)
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
    
    private func setupTextFields() {
        eventDateTextField.delegate = self
        eventTimeEndTextField.delegate = self
        eventTimeStartTextField.delegate = self
        
        eventAddressTextField.isEnabled = !shouldDisablePlaceSelection
        viewModel.eventAddress = viewModel.postPlaceName
        eventAddressTextField.text = viewModel.eventAddress
        
        dropDownArrowView.isHidden = shouldDisableDropDownAction
        
        eventTitleTextField.addTarget(self, action: #selector(eventTitleDidChangeValue(_:)), for: .editingChanged)
        eventAddressTextField.addTarget(self, action: #selector(eventAddressTextFieldDidChangeValue(_:)), for: .editingChanged)
        descriptionTextView.delegate = self
    }
    
    @objc private func eventTitleDidChangeValue(_ sender: UITextField) {
        viewModel.eventTitle = eventTitleTextField.text ?? ""
    }
    
    @objc private func eventAddressTextFieldDidChangeValue(_ sender: UITextField) {
        viewModel.eventAddress = eventAddressTextField.text ?? ""
    }
    
    private func updatePublisherInView() {
        publisherNameLabel.text = viewModel.publisherName
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
    
    private func removeDropDownListView() {
        dropDownListView?.removeFromSuperview()
        dropDownListView = nil
        UIView.animate(withDuration: 0.15) {
            [weak self] in
            self?.dropDownArrowView.transform = CGAffineTransform(rotationAngle: 0.toCGFloat.deg2rad)
        } completion: { (true) in
        }
    }
    
    private func showDropDownUserList(inLocation point: CGPoint, tappedViewFrame: CGRect, leftRightVal: CGFloat) {
        removeDropDownListView()
        let userSelectDropDownList = DropDownSearchListView(frame: self.view.bounds)
        userSelectDropDownList.viewModel = DropdownSearchListViewModel(users: viewModel.dropDownUserList, groups: viewModel.recommendedGroups)
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
        userSelectDropDownList.actionBtnContainer.autoresizesSubviews = true
        userSelectDropDownList.actionBtnContainer.layoutIfNeeded()
        userSelectDropDownList.contentView.layoutIfNeeded()
        userSelectDropDownList.actionBtnContainer.isHidden = false
        self.dropDownListView = userSelectDropDownList
        self.dropDownListView?.onOutsideViewTapped = {
            [weak self] in
            self?.removeDropDownListView()
        }
        self.dropDownListView?.onUserSelected = {
            [weak self] (user) in
            self?.removeDropDownListView()
            self?.updateUserSelection(user: user)
        }
        self.dropDownListView?.onGroupSelected = {
            [weak self] (group) in
            self?.removeDropDownListView()
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
    
    func updateEventImageAvailabilityUI() {
        updateImageTypeContentVisibility()
        if viewModel.isEventModelPhotoMode  {
            updateTypeSectionViews(selectedLabel: nil, selectedIcon: nil, unselectedLabels: [photoTypeIndicatorLabel], unselectedIcons: [photoTypeIndicatorImageView])
        }
        else {
            viewModel.postImagesData = []
            viewModel.postImages = []
            updateTypeSectionViews(selectedLabel: photoTypeIndicatorLabel, selectedIcon: photoTypeIndicatorImageView, unselectedLabels: nil, unselectedIcons: nil)
        }
    }
    
    private func updateImageTypeContentVisibility() {
        eventImageView.image = viewModel.postImages.first
        if viewModel.postImagesCount > 0 {
            imageTypeContentView.isHidden = false
            postTypeIndicatorContainer.isHidden = true
        }
        else {
            imageTypeContentView.isHidden = true
            postTypeIndicatorContainer.isHidden = false
        }
    }
    
    private func updateTypeSectionViews(selectedLabel: UILabel?, selectedIcon: UIImageView?, unselectedLabels: [UILabel]?, unselectedIcons: [UIImageView]?) {
        selectedLabel?.textColor = UIColor(named: AppColors.appBlack.rawValue)
        selectedIcon?.tintColor = UIColor(named: AppColors.appBlack.rawValue)
        guard unselectedIcons != nil && unselectedLabels != nil else {return}
        for label in unselectedLabels! {
            label.textColor = UIColor(named: AppColors.appWarmGray2.rawValue)
        }
        for icon in unselectedIcons! {
            icon.tintColor = UIColor(named: AppColors.appWarmGray2.rawValue)
        }
    }
    
    private func showSearchGroupView(withText text: String) {
        let searchGroupVC = UIStoryboard.getViewController(inStoryboard: "Post", identifier: "searchGroupVC") as! SearchGroupViewController
        searchGroupVC.viewModel = GroupListViewModel(searchText: text)
        searchGroupVC.modalPresentationStyle = .overFullScreen
        searchGroupVC.onGroupSelect = {
            group in
        }
        presentPanModal(searchGroupVC)
    }
    
    private func showSearchCheckinView() {
        let searchCheckinVC = UIStoryboard.getViewController(inStoryboard: "Post", identifier: "searchCheckinVC") as! SearchCheckinViewController
        searchCheckinVC.modalPresentationStyle = .overFullScreen
        searchCheckinVC.onCheckinSelect = {
            place in
        }
        presentPanModal(searchCheckinVC)
    }
    
    private func setupImagePickerView() {
        config = YPImagePicker.getAppImageViewConfig(allowMultiSelect: false, allowsCrop: false, onStartScreen: .photo)
        imagePickerController = YPImagePicker(configuration: config)
        imagePickerController.didFinishPicking { [weak self] (items, canceled) in
            guard let strongSelf = self else {
                self?.imagePickerController.dismiss(animated: true, completion: nil)
                return
            }
            guard !canceled else {
                self?.imagePickerController.dismiss(animated: true, completion: nil)
                return
            }
            if items.count > 0 {
                strongSelf.viewModel.isEventModelPhotoMode = true
            }
            var images = [UIImage]()
            var imagesData = [Data]()
            for item in items {
                switch item {
                case .photo(let photo):
                    let data = photo.image.UIImageToDataJPEG2(compressionRatio: 1)!
                    images.append(photo.image.resizeImage(targetSize: CGSize(width: 800, height: 800)))
                    imagesData.append(data)
                default:
                    break
                }
            }
            strongSelf.viewModel.postImages = images
            strongSelf.viewModel.postImagesData = imagesData
            strongSelf.updateEventImageAvailabilityUI()
            self?.imagePickerController.dismiss(animated: true, completion: nil)
        }
    }
    
    func openImagePickerView() {
        setupImagePickerView()
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    private func tryCreateEventPost() {
        if viewModel.type == .eventPost {
            self.showOrbisLoader(disableUserInteraction: true)
            viewModel.tryCreatePost { [weak self] data, err in
                guard let self = self else { return }
                if let error = err {
                    self.handleError(error: error)
                }
                else {
                    self.dismiss(animated: true) {
                        [weak self] in
                        guard let self = self else { return }
                        self.dismiss(animated: true) { [weak self] in
                            self?.onCreatePostSuccess?(data as? OrbisFeedPost)
                        }
                    }
                }
                self.hideOrbisLoader()
            }
        }
        else {
            self.showToastMessage(message: AppErrorStrings.invalidPostType)
        }
    }
}

extension CreateEventViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        viewModel.postDescription = textView.text
    }
}

extension CreateEventViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == eventDateTextField {
            self.view.endEditing(true)
            isDateTimePickerVisible = true
            RPicker.selectDate(title: AppStrings.selectDate, cancelText: AppStrings.cancel.uppercased(), doneText: AppStrings.ok.uppercased(), datePickerMode: .date, selectedDate: viewModel.selectedEventDate ?? Date(), minDate: nil, maxDate: nil, style: .Wheel) { [weak self] (date) in
                let dateStr = date.dateString("MM/dd/YY")
                self?.isDateTimePickerVisible = false
                self?.eventDateTextField.text = dateStr
                self?.viewModel.selectedEventDate = date
                self?.viewModel.eventDate = dateStr
            }
            return false
        }
        if textField == eventTimeStartTextField {
            self.view.endEditing(true)
            guard let selectedDate = viewModel.selectedEventDate else {
                self.showToastMessage(message: AppErrorStrings.selectDateFirst)
                return false
            }
            isDateTimePickerVisible = true
            RPicker.selectDate(title: AppStrings.Events.Create.selectStartTime, cancelText: AppStrings.cancel.uppercased(), doneText: AppStrings.ok.uppercased(), datePickerMode: .time, selectedDate: viewModel.selectedEventStartTime ?? selectedDate, minDate: nil, maxDate: nil, style: .Wheel) { [weak self] (date) in
                if let endDate = self?.viewModel.selectedEventEndTime, date > endDate {
                    self?.showToastMessage(message: "Your event end date will be set to next day.")
                    let newDate = endDate.dateByAddingDay(1)
                    let time = newDate.dateString("HH:mm")
                    self?.isDateTimePickerVisible = false
                    self?.eventTimeEndTextField.text = time
                    self?.viewModel.selectedEventEndTime = newDate
                    self?.viewModel.endTime = time
                }
                else {
                    let time = date.dateString("HH:mm")
                    self?.isDateTimePickerVisible = false
                    self?.eventTimeStartTextField.text = time
                    self?.viewModel.selectedEventStartTime = date
                    self?.viewModel.startTime = time
                }
                
            }
            return false
        }
        if textField == eventTimeEndTextField {
            self.view.endEditing(true)
            guard let _ = viewModel.selectedEventDate else {
                self.showToastMessage(message: AppErrorStrings.selectDateFirst)
                return false
            }
            guard let selectedStartDate = viewModel.selectedEventStartTime else {
                self.showToastMessage(message: AppErrorStrings.selectStartTimeFirst)
                return false
            }
            isDateTimePickerVisible = true
            RPicker.selectDate(title: AppStrings.Events.Create.selectEndTime, cancelText: AppStrings.cancel.uppercased(), doneText: AppStrings.ok.uppercased(), datePickerMode: .time, selectedDate: viewModel.selectedEventEndTime ?? selectedStartDate, minDate: nil, maxDate: nil, style: .Wheel) { [weak self] (date) in
                if date < selectedStartDate {
                    self?.showToastMessage(message: "Your event end date will be set to next day.")
                    let newDate = date.dateByAddingDay(1)
                    let time =  newDate.dateString("HH:mm")
                    self?.isDateTimePickerVisible = false
                    self?.eventTimeEndTextField.text = time
                    self?.viewModel.selectedEventEndTime = newDate
                    self?.viewModel.endTime = time
                }
                else {
                    let time =  date.dateString("HH:mm")
                    self?.isDateTimePickerVisible = false
                    self?.eventTimeEndTextField.text = time
                    self?.viewModel.selectedEventEndTime = date
                    self?.viewModel.endTime = time
                }
            }
            return false
        }
        return true
    }
}
