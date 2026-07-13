//
//  NearbyCommunitiesSheetViewController.swift
//  Orbis-iOS
//
//  Created by Zohaib Ahmad on 03/06/2026.
//


import UIKit
import SDWebImage
import CoreLocation


final class NearbyCommunitiesSheetViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    var places: [PolygonPlaceDetails] = []
    var onSelectPlace: ((PolygonPlaceDetails) -> Void)?

    // Server search (Android parity): typing queries /groups by name against the backend instead of
    // filtering the pre-fetched nearby list. Set by the presenter (map camera target).
    var searchLocation: CLLocationCoordinate2D?
    var onSelectGroup: ((Group) -> Void)?
    private var searchedGroups: [Group] = []
    private var isShowingServerResults = false
    private var searchWorkItem: DispatchWorkItem?

    // 2.5 tribe rows (72pt) + bottom buttons area (120pt). Tune to match Android's peek.
    static let peekHeight: CGFloat = 72 * 2.5 + 120

    private var isExpanded = false

    private let titleLabel = UILabel()
        
    @IBOutlet weak var searchContainerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var searchContainerView: UIView!
    
    @IBOutlet weak var tableTopConstraints: NSLayoutConstraint!
    
    @IBOutlet weak var bottomShaderView: GradientView!
    
    @IBOutlet weak var bottomButtonsContainerView: UIStackView!
    
    @IBOutlet weak var centerButtonImage: UIImageView!
    private var isSheetLarge = false
    
    
    var onNewsFeedTap: (() -> Void)?
    var onCenterBottomTap: (() -> Void)?
    var onGroupListTap: (() -> Void)?
    var onPlusButtonTapped: (() -> Void)?
    
    private let searchIconImageView = UIImageView()

    private var filteredPlaces: [PolygonPlaceDetails] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        filteredPlaces = places
        setupUI()
        updateSearchVisibility(isLarge: false, animated: false)
        
        
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        view.layer.cornerRadius = 22
        view.clipsToBounds = true

        setupSearchField()

        tableView.register(NearbyCommunityCell.self, forCellReuseIdentifier: NearbyCommunityCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = .white
        tableView.contentInset.bottom = 120
        tableView.verticalScrollIndicatorInsets.bottom = 120
        bottomShaderView.backgroundColor = .clear
        
        bottomShaderView.isUserInteractionEnabled = false
        bottomButtonsContainerView.isUserInteractionEnabled = true
        view.bringSubviewToFront(bottomShaderView)
        view.bringSubviewToFront(bottomButtonsContainerView)

        view.layoutIfNeeded()
    }
    
    @IBAction func newsFeedTapped(_ sender: Any) {
        // fire the delegate and call method gotoNewsFeedView from home map view controller.
        self.dismiss(animated: true)
        onNewsFeedTap?()
        
    }
    @IBAction func centerBottomButtonTapped(_ sender: Any) {
        // fire the delegate and call goToUserCheckInView from home map view controller.
       
        dismiss(animated: true) { [weak self] in
                guard let self else { return }

                if self.isSheetLarge {
                    self.onPlusButtonTapped?()
                } else {
                    self.onCenterBottomTap?()
                }
            }
    }
    
    @IBAction func goToGroupListTapped(_ sender: Any) {
        // fire the delegate and call performGroupListTapAction
        self.dismiss(animated: true)

//        onGroupListTap?()
    }
    
    private func setupSearchField() {
        searchContainerView.layer.cornerRadius = 4
        searchContainerView.clipsToBounds = true
        searchContainerView.layer.borderWidth = 2
        searchContainerView.layer.borderColor =
            UIColor(named: "appOffWhite2")?.cgColor
        let searchFont = UIFont(name: "Roboto-Regular", size: 18)
            ?? UIFont.systemFont(ofSize: 18, weight: .regular)

        searchTextField.font = searchFont
        searchIconImageView.removeFromSuperview()
        searchTextField.removeFromSuperview()

        searchIconImageView.translatesAutoresizingMaskIntoConstraints = false
        searchIconImageView.image = UIImage(systemName: "magnifyingglass")
        searchIconImageView.tintColor = UIColor(white: 0.45, alpha: 1)
        searchIconImageView.contentMode = .scaleAspectFit

        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.delegate = self
        searchTextField.placeholder = "Search tribe here..."
        searchTextField.font = .systemFont(ofSize: 18, weight: .regular)
        searchTextField.textColor = .black
        searchTextField.tintColor = .black
        searchTextField.borderStyle = .none
        searchTextField.backgroundColor = .clear
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.minimumFontSize = 14
        searchTextField.adjustsFontSizeToFitWidth = false

        
        searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Search tribe here...",
            attributes: [
                .foregroundColor: UIColor(white: 0.65, alpha: 1),
                .font: searchFont
            ]
        )

        searchTextField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)

        searchContainerView.addSubview(searchIconImageView)
        searchContainerView.addSubview(searchTextField)

        NSLayoutConstraint.activate([
            searchIconImageView.leadingAnchor.constraint(equalTo: searchContainerView.leadingAnchor, constant: 18),
            searchIconImageView.centerYAnchor.constraint(equalTo: searchContainerView.centerYAnchor),
            searchIconImageView.widthAnchor.constraint(equalToConstant: 20),
            searchIconImageView.heightAnchor.constraint(equalToConstant: 20),
            searchTextField.leadingAnchor.constraint(equalTo: searchIconImageView.trailingAnchor, constant: 12),
            searchTextField.trailingAnchor.constraint(equalTo: searchContainerView.trailingAnchor, constant: -16),
            searchTextField.topAnchor.constraint(equalTo: searchContainerView.topAnchor),
            searchTextField.bottomAnchor.constraint(equalTo: searchContainerView.bottomAnchor)
        ])
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        view.bringSubviewToFront(bottomShaderView)
        view.bringSubviewToFront(bottomButtonsContainerView)
    }
    private func updateSearchVisibility(isLarge: Bool, animated: Bool = true) {
        isSheetLarge = isLarge
        updateCenterButtonImage(isLarge: isLarge)
        searchContainerHeightConstraint.constant = isLarge ? 45 : 0
        tableTopConstraints.constant = isLarge ? 8 : 0
        searchContainerView.alpha = isLarge ? 1 : 0
        searchContainerView.isHidden = !isLarge
        bottomShaderView.isHidden = isLarge

        if !isLarge {
            searchTextField.resignFirstResponder()
            searchTextField.text = nil
            searchWorkItem?.cancel()
            isShowingServerResults = false
            searchedGroups = []
            filteredPlaces = places
            tableView.reloadData()
        }

        let changes = {
            self.view.layoutIfNeeded()
        }

        animated ? UIView.animate(withDuration: 0.2, animations: changes) : changes()
    }

    @objc private func searchChanged() {
        let text = (searchTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        searchWorkItem?.cancel()

        guard !text.isEmpty else {
            isShowingServerResults = false
            searchedGroups = []
            filteredPlaces = places
            tableView.reloadData()
            return
        }

        // Debounced server query — NOT a local autocomplete over the pre-fetched nearby list.
        let work = DispatchWorkItem { [weak self] in self?.performServerSearch(text: text) }
        searchWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    private func performServerSearch(text: String) {
        let location = searchLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        GroupManager.shared.fetchGroupList(location: location, searchText: text, showMembers: false, page: 0, limit: 25) { [weak self] data, _ in
            DispatchQueue.main.async {
                guard let self, let result = data as? GroupSearchResult else { return }
                // Drop stale responses: only apply results that match what's in the field right now.
                let current = (self.searchTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard result.searchText == current else { return }
                self.searchedGroups = result.groups
                self.isShowingServerResults = true
                self.tableView.reloadData()
            }
        }
    }
    
    private func updateCenterButtonImage(isLarge: Bool) {
        let imageName = isLarge ? "ic_plus_black" : "appLogo"
        centerButtonImage.image = UIImage(named: imageName)
        centerButtonImage.contentMode = .scaleAspectFit
    }
    

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isShowingServerResults ? searchedGroups.count : filteredPlaces.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: NearbyCommunityCell.identifier,
            for: indexPath
        ) as! NearbyCommunityCell

        if isShowingServerResults {
            cell.configure(group: searchedGroups[indexPath.row])
        } else {
            cell.configure(place: filteredPlaces[indexPath.row])
        }
        return cell
    }

    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        72
    }

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        if isShowingServerResults {
            onSelectGroup?(searchedGroups[indexPath.row])
        } else {
            onSelectPlace?(filteredPlaces[indexPath.row])
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if #available(iOS 15.0, *) {
            sheetPresentationController?.animateChanges {
                sheetPresentationController?.selectedDetentIdentifier = .large
            }
        }
    }
}


@available(iOS 15.0, *)
extension NearbyCommunitiesSheetViewController: UISheetPresentationControllerDelegate {

    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(
        _ sheetPresentationController: UISheetPresentationController
    ) {
        let isLarge = sheetPresentationController.selectedDetentIdentifier == .large
        updateSearchVisibility(isLarge: isLarge)
    }
}
