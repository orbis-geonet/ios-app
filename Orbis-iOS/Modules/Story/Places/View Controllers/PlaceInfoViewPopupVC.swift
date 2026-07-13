//
//  PlaceInfoViewPopupVC.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 11/08/2023.
//

import UIKit
import HWPanModal
import MapKit

class PlaceInfoViewPopupVC: OrbisLocalizableViewController {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var viewTitleLabel: UILabel!
    @IBOutlet weak var contentTableView: UITableView!
    @IBOutlet weak var actionBtnContainer: UIView!
    @IBOutlet weak var contentTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewBtnContainer: RoundedView!
    @IBOutlet weak var viewBtn: UIButton!
    @IBOutlet weak var editBtnContainer: RoundedView!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var contentBottomConstraint: NSLayoutConstraint!
    
    @IBAction func editTapped(_ sender: Any) {
        openEditScreen()
    }
    @IBAction func viewTapped(_ sender: Any) {
        performViewAction()
    }
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    struct Config {
        static var staticContentHeight: CGFloat {
            return 170.toCGFloat.relativeToIphone8Width()
        }
        static var tableViewTopInset: CGFloat {
            return 30.toCGFloat.relativeToIphone8Width()
        }
    }
    
    private var maxTableViewHeight: CGFloat {
        return (UIScreen.main.bounds.height) - (self.view.safeAreaInsets.top + self.view.safeAreaInsets.bottom) - Config.staticContentHeight - Config.tableViewTopInset
    }
    
    private var minTableViewHeight: CGFloat {
        return 50.toCGFloat.relativeToIphone8Width()
    }
    
    var viewModel: PlaceInfoPopupViewModel!
    var onContentUpdated: ((OrbisPlace) -> Void)?
    
    deinit {
        contentTableView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        handleViewModelActions()
        setupConstraintValues()
        setupTableView()
        updateViewComponents()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        setupConstraintValues()
    }
    
    override func updateStaticTexts() {
        updateViewComponents()
    }
    
    private func setupConstraintValues() {
        contentBottomConstraint.constant = self.view.safeAreaInsets.bottom
        self.contentView.layoutIfNeeded()
        
        // reload layout & transition to short
        panModalSetNeedsLayoutUpdate()
        panModalTransitionTo(state: .long)
    }
    
    override func hw_gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    override func showDragIndicator() -> Bool {
        return false
    }
    
    override func shortFormHeight() -> PanModalHeight {
        return PanModalHeight(type: .content, height: contentView.frame.height)
    }
    
    override func longFormHeight() -> PanModalHeight {
        return PanModalHeight(type: .content, height: contentView.frame.height)
    }
    
    // MARK: Initialization Methods
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let obj = object as? UITableView {
            if obj == self.contentTableView && keyPath == "contentSize" {
                var newHeight = obj.contentSize.height
                if newHeight > maxTableViewHeight {
                    newHeight = maxTableViewHeight
                }
                if newHeight < minTableViewHeight {
                    newHeight = minTableViewHeight
                }
                
                contentTableViewHeightConstraint.constant = newHeight
                contentTableView.layoutIfNeeded()
                self.view.layoutIfNeeded()
                
                // reload layout & transition to short
                panModalSetNeedsLayoutUpdate()
                panModalTransitionTo(state: .long)
            }
        }
    }
    
    private func handleViewModelActions() {
        viewModel.onPlaceDetailUpdateError = {
            [weak self] error in
            self?.view.isUserInteractionEnabled = true
            self?.handleError(error: error)
            self?.hideOrbisLoader()
        }
        viewModel.onPlaceDetailUpdateSuccess = {
            [weak self] updatedPlace in
            self?.view.isUserInteractionEnabled = true
            self?.hideOrbisLoader()
            self?.contentTableView.reloadData()
            self?.updateViewComponents()
            self?.onContentUpdated?(updatedPlace)
        }
    }
    
    private func setupTableView() {
        contentTableView.register(UINib(nibName: PlaceInfoTextTVC.nibName, bundle: nil), forCellReuseIdentifier: PlaceInfoTextTVC.identifier)
        contentTableView.register(UINib(nibName: PlaceScheduleItemTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: PlaceScheduleItemTableViewCell.identifier)
        
        contentTableView.dataSource = self
        contentTableView.delegate = self
        
        contentTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    private func updateViewComponents() {
        viewTitleLabel.text = viewModel.viewTitle
        viewBtn.setTitle(viewModel.viewActionTitle, for: .normal)
        editBtn.setTitle(viewModel.editActionTitle, for: .normal)
        viewBtnContainer.isHidden = viewModel.isViewActionHidden
        editBtnContainer.isHidden = viewModel.isEditActionHidden
        actionBtnContainer.isHidden = viewModel.isEditActionHidden && viewModel.isViewActionHidden
    }
    
    private func openEditScreen() {
        if viewModel.viewType == .schedule {
            showEditSchedulePopup()
        } else {
            showEditContentPopup()
        }
    }
    
    private func showEditSchedulePopup() {
        let vc = UIStoryboard.getViewController(inStoryboard: "Places", identifier: "placeScheduleEditVC") as! PlaceScheduleUpdateVC
        vc.modalPresentationStyle = .overFullScreen
        vc.viewModel = PlaceScheduleUpdateViewModel(model: viewModel.place)
        vc.onContentUpdated = {
            [weak self] updatedModel in
            self?.viewModel.place = updatedModel
            self?.contentTableView.reloadData()
            self?.onContentUpdated?(updatedModel)
        }
        presentPanModal(vc)
        
    }
    
    private func showEditContentPopup() {
        let editContentPopupVC = UIStoryboard.getViewController(inStoryboard: "Common", identifier: "textEditPopupVC") as! TextEditPopupViewController
        editContentPopupVC.modalPresentationStyle = .overFullScreen
        editContentPopupVC.shouldAddFullOverlay = true
        editContentPopupVC.shouldDismissViewOnTapOutside = false
        editContentPopupVC.shouldProceedWithUnchanged = false
        editContentPopupVC.contentType = viewModel.viewEditContentType
        editContentPopupVC.contentTitle = viewModel.viewTitle
        editContentPopupVC.saveBtnTitle = AppStrings.save
        editContentPopupVC.textViewPlaceholder = viewModel.viewContentPlaceholder
        switch viewModel.viewType {
        case .telephone:
            editContentPopupVC.textViewKeyboardType = .phonePad
        case .website:
            editContentPopupVC.textViewKeyboardType = .URL
        default:
            editContentPopupVC.textViewKeyboardType = .default
        }
        editContentPopupVC.contentText = viewModel.getContentItem(at: 0)
        editContentPopupVC.onSave = {
            [weak self] text in
            self?.tryUpdateContentValue(text: text)
        }
        present(editContentPopupVC, animated: true, completion: nil)
    }
    
    private func performViewAction() {
        switch viewModel.viewType {
        case .address:
            openPlaceAddressOnExternalMap()
        case .telephone:
            guard let phone = viewModel.place.phone else { return }
            let numberUrl = URL(string: "tel://\(phone)")!
            if UIApplication.shared.canOpenURL(numberUrl) {
                UIApplication.shared.open(numberUrl)
            }
        case .website:
            guard let website = viewModel.place.website, let url = URL(string: website.toProperURLString) else { return }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        default:
            return
        }
    }
    
    
    private func openPlaceAddressOnExternalMap() {
        guard let placeLocation = viewModel.place.coordinates, let placeLat = placeLocation.latitude, let placeLong = placeLocation.longitude, let placeAddress = viewModel.place.address else { return }
        let queryStr = "?q=\(placeAddress.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "")&center=\(placeLat),\(placeLong)"
        if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://\(queryStr)")!)) {
            if let url = URL(string: "comgooglemaps-x-callback://\(queryStr)") {
                UIApplication.shared.open(url, options: [:])
            }
            else {
                let url = URL(string:"comgooglemaps://\(queryStr)")!
                UIApplication.shared.open(url, options: [:])
            }
        }
        else {
            let url = URL(string:"http://maps.apple.com/?q=\(placeAddress.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "")&sll=\(placeLat),\(placeLong)")!
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    private func tryUpdateContentValue(text: String) {
        guard !viewModel.isUpdating else { return }
        self.view.isUserInteractionEnabled = false
        self.view.showOrbisLoader(useFullScreen: false)
        viewModel.updatePlaceInfo(withContent: text)
    }
}

// MARK: - TableView Delegates

extension PlaceInfoViewPopupVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0 }
        return viewModel.contentItemCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.viewType {
        case .schedule:
            guard let model = viewModel.getDaySchedule(at: indexPath.row) else { return UITableViewCell() }
            let cell = tableView.dequeueReusableCell(withIdentifier: PlaceScheduleItemTableViewCell.identifier) as! PlaceScheduleItemTableViewCell
            cell.model = model
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: PlaceInfoTextTVC.identifier) as! PlaceInfoTextTVC
            cell.contentText = viewModel.getContentItem(at: indexPath.row)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch viewModel.viewType {
        case .address, .telephone, .website:
            // copy text to clipboard
            let pasteboard = UIPasteboard.general
            guard let cell = tableView.cellForRow(at: indexPath) as? PlaceInfoTextTVC, let contentText = cell.contentTextLabel.text, !contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            pasteboard.string = contentText
            showToastMessage(message: AppStrings.textCopied)
        default:
            return
        }
    }
}
