//
//  PlaceRatePopupVC.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 12/08/2023.
//

import UIKit
import Cosmos
import HWPanModal

class PlaceRatePopupVC: OrbisLocalizableViewController {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var viewTitleLabel: UILabel!
    @IBOutlet weak var ratingMessageLabel: UILabel!
    @IBOutlet weak var actionBtnContainer: UIView!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var contentBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var ratingView: CosmosView!
    
    @IBAction func saveTapped(_ sender: Any) {
        tryRatePlace()
    }
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    var viewModel: PlaceRatePopupViewModel!
    var onPlaceRated: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupStarRating()
        setupConstraintValues()
        updateStaticTexts()
        handleViewModelActions()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        setupConstraintValues()
    }
    
    private func setupStarRating() {
        ratingView.settings.updateOnTouch = true
        ratingView.settings.fillMode = .full
        ratingView.settings.starSize = 40.toCGFloat.relativeToIphone8Width()
        ratingView.settings.starMargin = 15.toCGFloat.relativeToIphone8Width()
        
        ratingView.rating = viewModel.userRating
    }
    
    private func setupConstraintValues() {
        contentBottomConstraint.constant = self.view.safeAreaInsets.bottom
        self.contentView.layoutIfNeeded()
        
        // reload layout & transition to short
        panModalSetNeedsLayoutUpdate()
        panModalTransitionTo(state: .long)
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
    
    override func updateStaticTexts() {
        viewTitleLabel.text = AppStrings.Places.reviewTitle
        ratingMessageLabel.text = AppStrings.Places.ratingMessage
        saveBtn.setTitle(AppStrings.save, for: .normal)
    }

}

// MARK: - View Model Actions

extension PlaceRatePopupVC {
    
    private func handleViewModelActions() {
        viewModel.onPlaceRateError = {
            [weak self] error in
            self?.view.isUserInteractionEnabled = true
            self?.handleError(error: error)
            self?.hideOrbisLoader()
        }
        viewModel.onPlaceRateSuccess = {
            [weak self] in
            self?.view.isUserInteractionEnabled = true
            self?.hideOrbisLoader()
            self?.onPlaceRated?()
            self?.dismiss(animated: true)
        }
    }
    
    private func tryRatePlace() {
        guard ratingView.rating >= 1 else {
            showToastMessage(message: AppErrorStrings.invalidRating)
            return
        }
        guard !viewModel.isLoading else { return }
        self.view.isUserInteractionEnabled = false
        self.view.showOrbisLoader(useFullScreen: false)
        viewModel.ratePlace(withRating: Int(ratingView.rating))
    }
}
