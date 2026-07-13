//
//  SettingsFollowedPlacesListViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 12/04/2021.
//

import UIKit

class SettingsFollowedPlacesListViewController: OrbisLocalizableViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var resultView: UITableView!
    
    @IBAction func backTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func searchIconTapped(_ sender: Any) {
        searchTextField.becomeFirstResponder()
    }
    
    var viewModel: UserFollowedPlacesViewModel!
    var isLoading = false
    var searchTimer = Timer()
    var onCheckinSelect: ((OrbisPlace) -> Void)?
    
    override func topOffset() -> CGFloat {
        return 0
    }
    
    override func showDragIndicator() -> Bool {
        return false
    }

    override func shouldRespond(toPanModalGestureRecognizer panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        let panGesturePoint = panGestureRecognizer.location(in: self.view)
        if resultView.frame.contains(panGesturePoint) {
            return resultView.contentOffset.y <= 0
        }
        return true
    }
    
    override func isAutoHandleKeyboardEnabled() -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = UserFollowedPlacesViewModel()
        setupTableView()
        updateStaticTexts()
        handleViewModelActionHandlers()
        resetData()
        loadData()
    }
    
    override func updateStaticTexts() {
        titleLabel.text = AppStrings.Group.places
        searchTextField.placeholder = AppStrings.Checkin.checkinSearchPlaceholder
    }
    
    func setupTableView() {
        resultView.dataSource = self
        resultView.delegate = self
        resultView.reloadData()
        
        searchTextField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
    }
    
    func resetData() {
        viewModel.initializePagination()
        isLoading = false
        resultView.reloadData()
    }
    
    func loadData() {
        isLoading = true
        self.showOrbisLoader()
        viewModel.loadFollowedOrbisPlaces()
    }
    
    func loadMore() {
        isLoading = true
        self.showOrbisLoader()
        viewModel.loadMoreFollowedOrbisPlaces()
    }
    
    private func handleViewModelActionHandlers() {
        viewModel.onPlacesFetched = { [weak self] in
            self?.hideOrbisLoader()
            self?.resultView.reloadData()
            self?.isLoading = false
        }
        viewModel.onPlacesFetchedCompletePagination = { [weak self] in
            self?.hideOrbisLoader()
            self?.resultView.reloadData()
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
    
    private func tryUnfollowPlace(place: OrbisPlace) {
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.followUnfollow(place: place) { [weak self] data, err in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.resultView.reloadData()
            }
            self?.hideOrbisLoader()
        }
    }
    
    // MARK:- Text Field Delegate methods
    
    @objc private func textDidChange(_ textField: UITextField) {
        searchTimer.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { [weak self] (timer) in
            self?.resetData()
            self?.viewModel.searchText = textField.text ?? ""
            self?.loadData()
        })
    }
}

extension SettingsFollowedPlacesListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0}
        return viewModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewModel.getPlaceItem(at: indexPath.row)
        let cell = tableView.dequeueReusableCell(withIdentifier: "placeItemCell") as! SettingsFollowedPlaceItemTableViewCell
        cell.viewModel = CheckinPlaceItemViewModel(place: model, isBorderless: true)
        cell.onUnfollowTapped = {
            [weak self] place in
            self?.tryUnfollowPlace(place: place)
        }
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = viewModel.getPlaceItem(at: indexPath.row)
        gotoPlaceDetailView(place: model)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastIndex = viewModel.count - 1
        if indexPath.row == lastIndex && !isLoading && !viewModel.hasItemsLastPageReached {
            loadMore()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15.toCGFloat.relativeToIphone8Width()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear
        return header
    }
    
    private func gotoPlaceDetailView(place: OrbisPlace) {
        let placeDetailVC = UIStoryboard.getViewController(inStoryboard: "Places", identifier: "placeDetailVC") as! PlaceDetailViewController
        placeDetailVC.viewModel = PlaceDetailViewModel(place: place)
        self.navigationController?.pushViewController(placeDetailVC, animated: true)
    }
}
