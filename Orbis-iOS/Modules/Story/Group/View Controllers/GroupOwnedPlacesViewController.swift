//
//  GroupOwnedPlacesViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 14/06/2021.
//

import UIKit

class GroupOwnedPlacesViewController: OrbisLocalizableViewController {

    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var resultTableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func searchTapped(_ sender: Any) {
        searchTextField.becomeFirstResponder()
    }
    
    var viewModel: GroupOwnedPlacesViewModel!
    var isLoading = false
    var searchTimer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        resetData()
        loadData()
        handleViewModelActionHandlers()
        updateStaticTexts()
    }
    
    override func updateStaticTexts() {
        titleLabel.text = AppStrings.Group.ownedPlaces
        searchTextField.placeholder = AppStrings.search
    }
    
    func setupTableView() {
        resultTableView.dataSource = self
        resultTableView.delegate = self
        resultTableView.reloadData()
        searchTextField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleCellLongPress(sender:)))
        resultTableView.addGestureRecognizer(longTapGesture)
    }
    
    @objc private func handleCellLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            guard viewModel.group.isAdmin == true else { return }
            let touchPoint = sender.location(in: resultTableView)
            if let indexPath = resultTableView.indexPathForRow(at: touchPoint) {
                let model = viewModel.getPlaceItem(at: indexPath.row)
                guard let _ = UserSessionManager.shared.currentUser else { return }
                showPlaceAdminLongPressActions(forPlace: model)
            }
        }
    }
    
    private func showPlaceAdminLongPressActions(forPlace model: OrbisPlace) {
        let actionSheetVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let reportAction = UIAlertAction(title: AppStrings.Group.removePlaceFromGroup, style: .default) { [weak self] action in
            self?.performRemovePlaceFromGroup(place: model)
        }
        let cancelAction = UIAlertAction(title: AppStrings.cancel, style: .destructive, handler: nil)
        actionSheetVC.addAction(reportAction)
        actionSheetVC.addAction(cancelAction)
        self.present(actionSheetVC, animated: true, completion: nil)
    }
    
    private func performRemovePlaceFromGroup(place: OrbisPlace) {
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.removePlaceFromGroup(place: place) { [weak self] result, error in
            if let err = error {
                self?.handleError(error: err)
            }
            else {
                self?.resultTableView.reloadData()
            }
            self?.hideOrbisLoader()
        }
    }
    
    func resetData() {
        viewModel.initializePagination()
        isLoading = false
        resultTableView.reloadData()
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
            self?.resultTableView.reloadData()
            self?.isLoading = false
        }
        viewModel.onPlacesFetchedCompletePagination = { [weak self] in
            self?.hideOrbisLoader()
            self?.resultTableView.reloadData()
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
    
    private func gotoPlaceDetailView(viewModel: PlaceDetailViewModel) {
        let placeDetailVC = UIStoryboard.getViewController(inStoryboard: "Places", identifier: "placeDetailVC") as! PlaceDetailViewController
        placeDetailVC.viewModel = viewModel
        self.navigationController?.pushViewController(placeDetailVC, animated: true)
    }
    
    // MARK:- Text Field Delegate methods
    
    @objc private func textDidChange(_ textField: UITextField) {
        searchTimer.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { [weak self] (timer) in
            self?.resetData()
            self?.viewModel.searchText = textField.text ?? ""
            self?.resultTableView.showOrbisLoader()
            self?.viewModel.loadOrbisPlaces()
        })
    }
}

extension GroupOwnedPlacesViewController: UITableViewDataSource, UITableViewDelegate {
    
    private func gotoPlaceDetailView(place: OrbisPlace) {
        let placeDetailVC = UIStoryboard.getViewController(inStoryboard: "Places", identifier: "placeDetailVC") as! PlaceDetailViewController
        placeDetailVC.viewModel = PlaceDetailViewModel(place: place)
        self.navigationController?.pushViewController(placeDetailVC, animated: true)
    }
    
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
            checkinItemCell.discardGroupImage = true
            checkinItemCell.viewModel = CheckinPlaceItemViewModel(place: model)
            return checkinItemCell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // go to place details
        let model = viewModel.getPlaceItem(at: indexPath.row)
        gotoPlaceDetailView(place: model)
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
