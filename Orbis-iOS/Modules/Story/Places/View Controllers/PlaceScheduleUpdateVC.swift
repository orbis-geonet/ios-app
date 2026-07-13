//
//  PlaceScheduleUpdateVC.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 14/08/2023.
//

import UIKit
import HWPanModal

class PlaceScheduleUpdateVC: OrbisLocalizableViewController {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var viewTitleLabel: UILabel!
    @IBOutlet weak var contentTableView: UITableView!
    @IBOutlet weak var actionBtnContainer: UIView!
    @IBOutlet weak var contentTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var editBtnContainer: RoundedView!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var contentBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBAction func editTapped(_ sender: Any) {
        tryUpdateSchedule()
    }
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    struct Config {
        static var staticContentHeight: CGFloat {
            return 210.toCGFloat.relativeToIphone8Width()
        }
        static var tableViewTopInset: CGFloat {
            return 30.toCGFloat.relativeToIphone8Width()
        }
    }
    
    private var maxTableViewHeight: CGFloat {
        return UIScreen.main.bounds.height - (self.view.safeAreaInsets.top + self.view.safeAreaInsets.bottom) - Config.staticContentHeight - Config.tableViewTopInset
    }
    
    private var minTableViewHeight: CGFloat {
        return 50.toCGFloat.relativeToIphone8Width()
    }
    
    var viewModel: PlaceScheduleUpdateViewModel!
    var onContentUpdated: ((OrbisPlace) -> Void)?
    var isPopupViewActive = false
    
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
    
    private func setupConstraintValues() {
        contentBottomConstraint.constant = self.view.safeAreaInsets.bottom
        self.contentView.layoutIfNeeded()
        
        // reload layout & transition to short
        panModalSetNeedsLayoutUpdate()
        panModalTransitionTo(state: .long)
    }
    
    override func shouldRespond(toPanModalGestureRecognizer panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return !isPopupViewActive
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
    
    override func updateStaticTexts() {
        updateViewComponents()
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
            self?.onContentUpdated?(updatedPlace)
            self?.dismiss(animated: true)
        }
    }
    
    private func setupTableView() {
        contentTableView.register(UINib(nibName: PlaceScheduleEditableItemTVC.nibName, bundle: nil), forCellReuseIdentifier: PlaceScheduleEditableItemTVC.identifier)
        
        contentTableView.dataSource = self
        contentTableView.delegate = self
        
        contentTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        
        errorLabel.isHidden = true
    }
    
    private func updateViewComponents() {
        viewTitleLabel.text = viewModel.viewTitle
        editBtn.setTitle(viewModel.editActionTitle, for: .normal)
        errorLabel.text = viewModel.errorMessage
    }
    
    private func openTimePicker(isCloseTime: Bool, model: OrbisPlaceWorkingHours) {
        isPopupViewActive = true
        RPicker.selectDate(title: AppStrings.Events.Create.selectStartTime, cancelText: AppStrings.cancel.uppercased(), doneText: AppStrings.ok.uppercased(), datePickerMode: .time, selectedDate: Date.fromString(dateString: isCloseTime ? model.endTime : model.startTime, format: DateFormat.eventTimeFormat.rawValue) ?? Date(), minDate: nil, maxDate: nil, style: .Wheel, timeInterval: 15, didSelectDate: {
            [weak self] (date) in
            self?.isPopupViewActive = false
            let time = date.dateString(DateFormat.eventTimeFormat.rawValue)
            self?.updateDayTime(forModel: model, time: time, isClosingTime: isCloseTime)
        }) {
            [weak self] in
            self?.isPopupViewActive = false
        }
        
    }
    
    private func updateDayTime(forModel model: OrbisPlaceWorkingHours, time: String, isClosingTime: Bool) {
        viewModel.updateDayTime(model: model, time: time, isCloseTime: isClosingTime)
        contentTableView.reloadData()
        errorLabel.isHidden = true
        // reload layout & transition to short
        panModalSetNeedsLayoutUpdate()
        panModalTransitionTo(state: .long)
    }
    
    private func tryUpdateSchedule() {
        if checkIfScheduleValid() {
            errorLabel.isHidden = true
            guard !viewModel.isUpdating else { return }
            self.view.isUserInteractionEnabled = false
            self.view.showOrbisLoader(useFullScreen: false)
            viewModel.updatePlaceSchedule()
        } else {
            errorLabel.isHidden = false
        }
    }
    
    private func checkIfScheduleValid() -> Bool {
        return viewModel.checkIfValidScheduleEntries()
    }
}


// MARK: - TableView Delegates

extension PlaceScheduleUpdateVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0 }
        return viewModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PlaceScheduleEditableItemTVC.identifier) as! PlaceScheduleEditableItemTVC
        cell.model = viewModel.getItem(at: indexPath.row)
        cell.onStartTimeTapped = {
            [weak self] model in
            self?.openTimePicker(isCloseTime: false, model: model)
        }
        cell.onEndTimeTapped = {
            [weak self] model in
            self?.openTimePicker(isCloseTime: true, model: model)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
