//
//  SearchBarManager.swift
//  Orbis-iOS
//
//  Created by Kamran on 24/10/2024.
//


import UIKit

protocol SearchBarManagerDelegate: AnyObject {
    func didSelectCity(_ city: City)
}


class SearchBarManager: NSObject, UISearchBarDelegate {
    
    private var searchResults: [City] = []
    private var allCities: [City] = []
    private var resultsTableView: UITableView!
    var searchBar: UISearchBar!
    var searchBarView: UIView!
    
    private let collapsedContentStack = UIStackView()
    private let collapsedSearchIcon = UIImageView()
    private let collapsedTitleLabel = UILabel()
    
    private var searchBarInitialWidthConstraint: NSLayoutConstraint!
    private var searchBarExpandedWidthConstraint: NSLayoutConstraint?
    
    private var searchBarViewTopConstraint: NSLayoutConstraint!
    private var searchBarViewCenterXConstraint: NSLayoutConstraint!
    private var currentAddressSvTopConstraint: NSLayoutConstraint!
    
    private var searchBarLeadingConstraint: NSLayoutConstraint!
    private var searchBarTrailingConstraint: NSLayoutConstraint!
    private var searchBarCenterXConstraint: NSLayoutConstraint!
    private var searchBarCenterYConstraint: NSLayoutConstraint!
    

    private var searchBarViewWidthConstraint: NSLayoutConstraint?
    private var searchBarInitialLeadingConstraint: NSLayoutConstraint!
    private var searchBarInitialTrailingConstraint: NSLayoutConstraint!
    private var searchBarExpandedLeadingConstraint: NSLayoutConstraint!
    private var searchBarExpandedTrailingConstraint: NSLayoutConstraint!
    
    private var tableViewBottomConstraint: NSLayoutConstraint!
    private var searchBarPlaceHolder: String = "Choose a city"
    var searchBarImage : UIImageView!
    private var isPermissionDenied:Bool = false
    private var mainView:UIView!
    private weak var currentAddressSv: UIStackView!
    private weak var leftsliderView: UIView!
    private weak var rightsliderView: UIView!
    
    var searchBarHistoryText = ""

    weak var delegate: SearchBarManagerDelegate?
    
    private var sharedPreferences = UserDefaults.standard

    
    init(permission:Bool, parentView:UIView, currentAddressV:UIStackView, leftView:UIView, rightView:UIView) {
        super.init()
        
        
        self.isPermissionDenied = permission
        self.mainView = parentView
        self.currentAddressSv = currentAddressV
        self.leftsliderView = leftView
        self.rightsliderView = rightView
        
        setupSearchBar()
        loadCities()
        
        // Add keyboard observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        self.currentAddressSv.isHidden = true
        self.searchBarView.isHidden = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    
    func permissionSetup(permission : Bool)  {
        
        self.isPermissionDenied = permission
        collapseSearchBar()
    }
    
    
    private func permissionAllowedConstraints() {
        NSLayoutConstraint.deactivate([
            searchBarCenterXConstraint,
            searchBarCenterYConstraint,
        ])
        
        NSLayoutConstraint.activate([
            searchBarViewTopConstraint,
            searchBarViewCenterXConstraint,
            currentAddressSvTopConstraint
        ])
    }
    
    private func permissionDeniedConstraints() {
        NSLayoutConstraint.deactivate([
            searchBarViewTopConstraint,
            searchBarViewCenterXConstraint,
            currentAddressSvTopConstraint
        ])
        
        NSLayoutConstraint.activate([
            searchBarCenterXConstraint,
            searchBarCenterYConstraint,
        ])
    }
    
    
    
    
    private func setupSearchBar() {
        
        guard searchBar == nil else {
            return
        }
        
        searchBar = CustomSearchBar()
        searchBar.delegate = self
        searchBar.placeholder = searchBarPlaceHolder
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.searchTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Make UISearchBar transparent
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = .clear
        searchBar.barTintColor = .clear
        searchBar.isTranslucent = true

        searchBar.searchTextField.backgroundColor = UIColor.white.withAlphaComponent(0.02)
        let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
        
        textFieldInsideSearchBar?.leftView = UIImageView(
            image: UIImage(named: "search")
        )
        
        textFieldInsideSearchBar?.borderStyle = .none
        textFieldInsideSearchBar?.backgroundColor = .clear
        textFieldInsideSearchBar?.textColor = UIColor.black
        textFieldInsideSearchBar?.font = UIFont.systemFont(ofSize: 14)
        textFieldInsideSearchBar?.attributedPlaceholder = NSAttributedString(
            string: searchBarPlaceHolder,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]
        )
        
        searchBar.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: 20
        )
        
        // Liquid glass outer view
        searchBarView = LiquidGlassView()
        searchBarView.translatesAutoresizingMaskIntoConstraints = false
        
        if let glassView = searchBarView as? LiquidGlassView {
            glassView.cornerRadius = 24
        }
        
//        searchBarImage = UIImageView()
//        searchBarImage.image = UIImage(named: "pencil")
//        searchBarImage.contentMode = .scaleAspectFit
//        searchBarImage.translatesAutoresizingMaskIntoConstraints = false

        mainView.addSubview(searchBarView)
        
        
        
        
        searchBarView.addSubview(searchBar)
        
        
        collapsedContentStack.axis = .horizontal
        collapsedContentStack.alignment = .center
        
//        collapsedContentStack.spacing = 16
//        collapsedContentStack.isUserInteractionEnabled = false
//        collapsedContentStack.translatesAutoresizingMaskIntoConstraints = false
//        collapsedContentStack.isHidden = true
//        collapsedSearchIcon.image = UIImage(named: "search")
//        collapsedSearchIcon.contentMode = .scaleAspectFit
//        collapsedSearchIcon.translatesAutoresizingMaskIntoConstraints = false
//        collapsedTitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
//        collapsedTitleLabel.textColor = .black
//        collapsedTitleLabel.textAlignment = .center
//        collapsedContentStack.addArrangedSubview(collapsedSearchIcon)
//        collapsedContentStack.addArrangedSubview(collapsedTitleLabel)
//        searchBarView.addSubview(collapsedContentStack)
//
//        NSLayoutConstraint.activate([
//            collapsedContentStack.centerXAnchor.constraint(equalTo: searchBarView.centerXAnchor),
//            collapsedContentStack.centerYAnchor.constraint(equalTo: searchBarView.centerYAnchor),
//
//            collapsedSearchIcon.widthAnchor.constraint(equalToConstant: 24),
//            collapsedSearchIcon.heightAnchor.constraint(equalToConstant: 24)
//        ])
        
        
        
        
        collapsedContentStack.axis = .horizontal
        collapsedContentStack.alignment = .center
        collapsedContentStack.spacing = 8
        collapsedContentStack.isUserInteractionEnabled = false
        collapsedContentStack.translatesAutoresizingMaskIntoConstraints = false
        collapsedContentStack.isHidden = true

        collapsedSearchIcon.image = UIImage(named: "search")
        collapsedSearchIcon.contentMode = .scaleAspectFit
        collapsedSearchIcon.translatesAutoresizingMaskIntoConstraints = false

        // Use exactly the same font and color as the search bar
        collapsedTitleLabel.font = searchBar.searchTextField.font
        collapsedTitleLabel.textColor = searchBar.searchTextField.textColor
        collapsedTitleLabel.textAlignment = .center

        collapsedContentStack.addArrangedSubview(collapsedSearchIcon)
        collapsedContentStack.addArrangedSubview(collapsedTitleLabel)

        searchBarView.addSubview(collapsedContentStack)

        let iconSize = searchBar.searchTextField.font?.lineHeight ?? 18

        NSLayoutConstraint.activate([
            collapsedContentStack.centerXAnchor.constraint(equalTo: searchBarView.centerXAnchor),
            collapsedContentStack.centerYAnchor.constraint(equalTo: searchBarView.centerYAnchor),

            collapsedSearchIcon.widthAnchor.constraint(equalToConstant: iconSize),
            collapsedSearchIcon.heightAnchor.constraint(equalToConstant: iconSize)
        ])
        
        searchBarCenterXConstraint = searchBarView.centerXAnchor.constraint(equalTo: self.mainView.centerXAnchor)
        searchBarCenterYConstraint = searchBarView.centerYAnchor.constraint(equalTo: self.mainView.centerYAnchor)
        
        // 65 sat too low over the map; the subcity label is anchored to the bar's bottom edge
        // (currentAddressSvTopConstraint below), so it rides up with the bar automatically.
        searchBarViewTopConstraint = self.searchBarView.topAnchor.constraint(
            equalTo: self.mainView.safeAreaLayoutGuide.topAnchor,
            constant: 45
        )
        
        searchBarViewCenterXConstraint = self.searchBarView.centerXAnchor.constraint(
            equalTo: self.mainView.centerXAnchor
        )
        
        currentAddressSvTopConstraint = self.currentAddressSv.topAnchor.constraint(
            equalTo: self.searchBarView.bottomAnchor,
            constant: 8
        )

        if isPermissionDenied {
            searchBarCenterXConstraint.isActive = true
            searchBarCenterYConstraint.isActive = true
        } else {
            searchBarViewTopConstraint.isActive = true
            searchBarViewCenterXConstraint.isActive = true
            currentAddressSvTopConstraint.isActive = true
        }
        
        searchBarInitialLeadingConstraint = searchBarView.widthAnchor.constraint(equalToConstant: 160)
        searchBarInitialWidthConstraint = searchBarView.widthAnchor.constraint(equalToConstant: 160)
 
        
        NSLayoutConstraint.activate([
            searchBarInitialLeadingConstraint,
            searchBarView.heightAnchor.constraint(equalToConstant: 48),

            searchBar.topAnchor.constraint(equalTo: searchBarView.topAnchor),
            searchBar.bottomAnchor.constraint(equalTo: searchBarView.bottomAnchor),
            searchBar.leadingAnchor.constraint(equalTo: searchBarView.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: searchBarView.trailingAnchor),

            searchBar.searchTextField.leadingAnchor.constraint(equalTo: searchBarView.leadingAnchor, constant: 0),
            searchBar.searchTextField.trailingAnchor.constraint(equalTo: searchBarView.trailingAnchor, constant: -8),
            searchBar.searchTextField.centerYAnchor.constraint(equalTo: searchBarView.centerYAnchor)
            
        ])
        
        searchBarExpandedLeadingConstraint = searchBarView.leadingAnchor.constraint(
            equalTo: leftsliderView.trailingAnchor,
            constant: 20
        )
        
        searchBarExpandedTrailingConstraint = searchBarView.trailingAnchor.constraint(
            equalTo: rightsliderView.leadingAnchor,
            constant: -20
        )
        
        setupResultsTableView()
    }
    
//    private func setCollapsedStyle(_ isCollapsed: Bool) {
//        let text = searchBar.text?.isEmpty == false ? searchBar.text! : searchBarPlaceHolder
//        collapsedTitleLabel.font = searchBar.searchTextField.font
//        collapsedTitleLabel.text = text
//        collapsedContentStack.isHidden = !isCollapsed
//
//        searchBar.searchTextField.textColor = isCollapsed ? .clear : .black
//        searchBar.searchTextField.tintColor = isCollapsed ? .clear : .black
//        searchBar.searchTextField.leftView = isCollapsed ? nil : UIImageView(image: UIImage(named: "search"))
//        searchBar.searchTextField.leftViewMode = isCollapsed ? .never : .always
//    }
    
    private func setCollapsedStyle(_ isCollapsed: Bool) {
        let text = searchBar.text?.isEmpty == false ? searchBar.text! : searchBarPlaceHolder

        collapsedTitleLabel.font = searchBar.searchTextField.font
        collapsedTitleLabel.text = text
        collapsedContentStack.isHidden = !isCollapsed

        let textField = searchBar.searchTextField

        textField.textColor = isCollapsed ? .clear : .black
        textField.tintColor = isCollapsed ? .clear : .black

        if isCollapsed {
            // Hide the search field's own placeholder
            textField.attributedPlaceholder = NSAttributedString(string: "")
            searchBar.placeholder = ""

            textField.leftView = nil
            textField.leftViewMode = .never
        } else {
            // Restore placeholder
            searchBar.placeholder = "Type a city"
            textField.attributedPlaceholder = NSAttributedString(
                string: "Type a city",
                attributes: [
                    .foregroundColor: UIColor.black
                ]
            )

            textField.leftView = UIImageView(image: UIImage(named: "search"))
            textField.leftViewMode = .always
        }
    }
    
    // MARK: - UISearchBarDelegate Methods
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    let filteredCities = self?.filterCities(searchText: searchText)
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }

                        if self.searchBar.isFirstResponder {
                            self.searchResults = filteredCities ?? []
                            self.resultsTableView.isHidden = self.searchResults.isEmpty
                            self.mainView.bringSubviewToFront(self.resultsTableView)
                            self.resultsTableView.reloadData()
                        }
                    }
                }
            //}
       
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        // Check if resultsTableView is visible
        if !resultsTableView.isHidden {
            print("Table view is visible. Checking for active touch.")
            // Use the tap gesture's last touch location to determine focus
            if let gestureRecognizers = resultsTableView.gestureRecognizers {
                for gesture in gestureRecognizers {
                    if let tapGesture = gesture as? UITapGestureRecognizer,
                       tapGesture.state == .recognized {
                        print("A table view cell was tapped.")
                        return false // Do not resign focus if a cell is tapped
                    }
                }
            }
        }
        
        // Allow editing to end for other cases
        print("Search bar should end editing.")
        return true
    }
    
    @objc private func didTapTableView(_ gesture: UITapGestureRecognizer) {
        let touchPoint = gesture.location(in: resultsTableView)
        if let indexPath = resultsTableView.indexPathForRow(at: touchPoint) {
            print("Tapped on table view cell at \(indexPath)")
            // Handle the selection logic here if needed
            
            let selectedCity = searchResults[indexPath.row]
            searchBar.text = searchResults[indexPath.row].name
            searchBarHistoryText = searchResults[indexPath.row].name
            
            // Notify the delegate (HomeMapViewController) that a city has been selected
            delegate?.didSelectCity(selectedCity)
//            self.searchBarImage.image = UIImage(named: "pencil")
            self.updateSearchBarViewWidth(withText: searchResults[indexPath.row].name)
            resultsTableView.isHidden = true
            searchBar.resignFirstResponder()
        }
    }

    
    
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchResults.removeAll()
        self.resultsTableView.reloadData()
        expandSearchBar()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if !resultsTableView.isHidden {
            // Specify the delay (e.g., 0.3 seconds)
                //let delayInSeconds = 0.3

                // Use DispatchQueue to call the function after the delay
                //DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
                    self.collapseSearchBar()
                //}
        }else{
            collapseSearchBar()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // Expand the search bar width
    private func expandSearchBar() {
        // Activate the expanded width constraint
        
        // Expand the search bar
        UIView.animate(withDuration: 0.3) {
            NSLayoutConstraint.deactivate([self.searchBarInitialLeadingConstraint, //self.searchBarInitialTrailingConstraint
                                          ])
            
            self.permissionAllowedConstraints()
            
            NSLayoutConstraint.activate([self.searchBarExpandedLeadingConstraint, self.searchBarExpandedTrailingConstraint])
            
            
//            self.searchBarImage.image = UIImage(named: "arrow")
//            self.searchBar.placeholder = "Type a city"
            self.setCollapsedStyle(false)
            
            
            self.searchBar.text = ""
            self.mainView.layoutIfNeeded()
        }
        
    }
    
    func isCitySaved() -> Bool {
        let savedCityLat = sharedPreferences.float(forKey: "selected_city_latitude")
        let savedCityLon = sharedPreferences.float(forKey: "selected_city_longitude")
        let isSavedCity = savedCityLat != 0 && savedCityLon != 0
        return isSavedCity
    }
    
    // Collapse the search bar back to its original width
    private func collapseSearchBar() {
        
        // Collapse the search bar back to its original size
        if searchBar.text == "" && searchBarHistoryText != "" {
            searchBar.text = searchBarHistoryText
        }
        
        searchResults.removeAll()
        tableViewBottomConstraint.constant = 0
        resultsTableView.reloadData()
        self.resultsTableView.isHidden = true
        
        searchBar.resignFirstResponder()
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            
            guard let self = self else {return}
            
            NSLayoutConstraint.deactivate([self.searchBarExpandedLeadingConstraint, self.searchBarExpandedTrailingConstraint])
            
            
            
            if self.searchBarHistoryText != "" {
                self.permissionAllowedConstraints()

            }else {
                if self.isPermissionDenied && !isCitySaved() {
                    self.permissionDeniedConstraints()
                }else {
                }
            }
            
            NSLayoutConstraint.activate([self.searchBarInitialLeadingConstraint])
//            self.searchBarImage.image = UIImage(named: "pencil")
//            self.searchBar.placeholder = "Choose a city"
            self.setCollapsedStyle(true)
            
            
            self.updateSearchBarViewWidth(withText: nil)
            self.resultsTableView.isHidden = true
            self.mainView.layoutIfNeeded()
        }

    }
    
    
    func updateSearchBarViewWidth(withText text: String? = nil) {
        let minimumWidth: CGFloat = 160
        let maxWidth: CGFloat = UIScreen.main.bounds.width - 40

        var textWidth: CGFloat = minimumWidth

        if let text = text, !text.isEmpty {
            let size = text.widthOfString(usingFont: UIFont.systemFont(ofSize: 14))
            textWidth = CGFloat(size) + 95
        } else {
            if let searchText = searchBar.searchTextField.text, !searchText.isEmpty {
                let size = searchText.widthOfString(usingFont: UIFont.systemFont(ofSize: 14))
                textWidth = CGFloat(size) + 95
            }
        }
        textWidth = max(minimumWidth, min(textWidth, maxWidth))

        UIView.animate(withDuration: 0.3) {
            self.searchBarInitialLeadingConstraint.constant = textWidth
            self.mainView.layoutIfNeeded()
        }
    }
    
    //MARK: update text on searchBar
    func updateText(withText text: String? = nil) {
        
        self.searchBarHistoryText = text ?? ""

        if !self.searchBar.isFirstResponder {
            self.searchBar.text = text
        
            //TOTO ADDED THIS CALL AND CONDITION
            self.collapseSearchBar()
        }
    }
    
    //MARK: udpate visibility
    func updateVisibitiy(isHidden:Bool){
        self.currentAddressSv.isHidden = isHidden
        self.searchBarView.isHidden = isHidden
        
        if isHidden {
            self.searchBar.resignFirstResponder()
        }
    }
    
       
    // MARK: - Utility Methods
    
    private func filterCities(searchText: String) -> [City] {
        let lowercasedSearchText = searchText.lowercased()
        
        let gh = allCities.filter { $0.name.lowercased().contains(lowercasedSearchText) }
        
        print(gh)
        
        return allCities.filter { $0.name.lowercased().contains(lowercasedSearchText) }
    }
    
    private func loadCities() {
        // Load the cities from a local JSON or a remote source
        if let url = Bundle.main.url(forResource: "cities", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let cities = try? JSONDecoder().decode([City].self, from: data) {
            allCities = cities
        }
    }
}

extension SearchBarManager : UITableViewDataSource, UITableViewDelegate {
    // MARK: - UITableViewDataSource and UITableViewDelegate Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let city = searchResults[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.selectionStyle = .default
        cell.frame.size.height = 30
        cell.textLabel?.text = "\(city.name), \(city.country)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let selectedCity = searchResults[indexPath.row]
        searchBar.text = searchResults[indexPath.row].name
        searchBarHistoryText = searchResults[indexPath.row].name
        
        // Notify the delegate (HomeMapViewController) that a city has been selected
        delegate?.didSelectCity(selectedCity)
//        self.searchBarImage.image = UIImage(named: "pencil")
        self.updateSearchBarViewWidth(withText: searchResults[indexPath.row].name)
        resultsTableView.isHidden = true
        searchBar.resignFirstResponder()
    }
    
    private func setupResultsTableView() {
        
        resultsTableView = UITableView()
        resultsTableView.isUserInteractionEnabled = true
        resultsTableView.translatesAutoresizingMaskIntoConstraints = false
        self.mainView.addSubview(resultsTableView)  // Adding table view to the parent of searchBarView
        self.mainView.bringSubviewToFront(resultsTableView)
        
        tableViewBottomConstraint = resultsTableView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor)

        
        NSLayoutConstraint.activate([
            resultsTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 2),
            resultsTableView.leadingAnchor.constraint(equalTo: searchBarView.leadingAnchor),
            resultsTableView.trailingAnchor.constraint(equalTo: searchBarView.trailingAnchor),
            //resultsTableView.heightAnchor.constraint(equalToConstant: 200)
            tableViewBottomConstraint
        ])
        resultsTableView.delegate = self
        resultsTableView.dataSource = self
        resultsTableView.isHidden = true
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapTableView))
        resultsTableView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        tableViewBottomConstraint.constant = -keyboardHeight // Adjust the bottom constraint to match keyboard height
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.mainView.layoutIfNeeded() // Animate the layout changes
        }
    }

    @objc private func keyboardWillHide(notification: Notification) {
        
        tableViewBottomConstraint.constant = 0
        self.resultsTableView.isHidden = true
        
        if let vText = searchBar.text, !vText.isEmpty {
            if vText != searchBarHistoryText {
                searchBar.text = ""
                updateSearchBarViewWidth(withText: nil)
            }
        }
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.mainView.layoutIfNeeded() // Animate the layout changes
        }
    }

}

extension SearchBarManager {
    // Method to set up the search bar depending on the permission status
    func setupSearchBar(isPermissionDenied: Bool) {
        // Customize search bar appearance based on permission
        if isPermissionDenied {
            // If location permission is denied, center the search bar
            centerSearchBar()
            
        } else {
            // If permission is granted, position it at the top
            moveSearchBarToTop()
        }
        
        // Additional setup like styling or adding custom views
        setupResultsTableView()
    }
    
    private func centerSearchBar() {
        // Deactivate leading/trailing constraints if they exist
        if let leadingConstraint = searchBarLeadingConstraint, let trailingConstraint = searchBarTrailingConstraint {
            NSLayoutConstraint.deactivate([leadingConstraint, trailingConstraint])
        }

        // Initialize and activate center constraints if they are nil
        if searchBarCenterXConstraint == nil {
            searchBarCenterXConstraint = searchBarView.centerXAnchor.constraint(equalTo: searchBarView.superview!.centerXAnchor)
            searchBarCenterYConstraint = searchBarView.centerYAnchor.constraint(equalTo: searchBarView.superview!.centerYAnchor)
        }

        searchBarCenterXConstraint?.isActive = true
        searchBarCenterYConstraint?.isActive = true
        searchBarInitialWidthConstraint.constant = 160  // Width in centered state
    }
    
    func moveSearchBarToCenter(){
//        centerSearchBar()
        collapseSearchBar()
        
    }

    private func moveSearchBarToTop() {
        // Deactivate center constraints if they exist
        if let centerXConstraint = searchBarCenterXConstraint, let centerYConstraint = searchBarCenterYConstraint {
            NSLayoutConstraint.deactivate([centerXConstraint, centerYConstraint])
        }

        // Initialize and activate leading/trailing constraints if they are nil
        if searchBarLeadingConstraint == nil {
            searchBarLeadingConstraint = searchBarView.leadingAnchor.constraint(equalTo: searchBarView.superview!.leadingAnchor, constant: 20)
            searchBarTrailingConstraint = searchBarView.trailingAnchor.constraint(equalTo: searchBarView.superview!.trailingAnchor, constant: -20)
        }

        searchBarLeadingConstraint?.isActive = true
        searchBarTrailingConstraint?.isActive = true
        searchBarView.topAnchor.constraint(equalTo: searchBarView.superview!.safeAreaLayoutGuide.topAnchor, constant: 79).isActive = true
        searchBarInitialWidthConstraint.constant = 160  // Adjust width as needed
    }
    
    func moveSearchBarUp(){
        //moveSearchBarToTop()
//        permissionAllowedConstraints()
        collapseSearchBar()
    }
    
    func isSearchBarCenterYConstraint() -> Bool {
        return self.searchBarCenterYConstraint?.isActive ?? false
    }
    
    func returnSearchBarCenterYConstraint() -> NSLayoutConstraint {
        return self.searchBarCenterYConstraint
    }
    
}
