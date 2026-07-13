//
//  SearchCheckinViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 07/04/2021.
//

import UIKit

class SearchCheckinViewController: OrbisLocalizableViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var checkinResultView: UITableView!
    
    @IBAction func backTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func searchIconTapped(_ sender: Any) {
        searchTextField.becomeFirstResponder()
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
        if checkinResultView.frame.contains(panGesturePoint) {
            return checkinResultView.contentOffset.y <= 0
        }
        return true
    }
    
    var viewModel: SearchCheckinListViewModel!
    var onCheckinSelect: ((OrbisPlace) -> Void)?
    var onCreatePlaceTapped: (() -> Void)?
    var isLoading = false
    var searchTimer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = SearchCheckinListViewModel()
        setupTableView()
        resetData()
        loadData()
        handleViewModelActionHandlers()
        updateStaticTexts()
    }
    
    override func updateStaticTexts() {
        titleLabel.text = AppStrings.Checkin.checkinTitle
        searchTextField.placeholder = AppStrings.Checkin.checkinSearchPlaceholder
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

extension SearchCheckinViewController: UITableViewDataSource, UITableViewDelegate {
    
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
        self.dismiss(animated: true) { [weak self] in
            self?.onCheckinSelect?(model)
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
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let loadMoreIndex = viewModel.count - 1
        if indexPath.row == loadMoreIndex && !isLoading && !viewModel.hasItemsLastPageReached {
            self.loadMore()
        }
    }
}
