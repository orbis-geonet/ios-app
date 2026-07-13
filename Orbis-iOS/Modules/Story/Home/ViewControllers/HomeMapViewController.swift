//
//  HomeMapViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/03/2021.
//

import UIKit
import GoogleMaps
import GooglePlaces
import HWPanModal
import SDWebImage
import Combine
import Lottie

class HomeMapViewController: OrbisLocalizableViewController {
    
    
    @IBOutlet weak var gpsView: LiquidGlassView!
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var orbisTitleLable: UILabel!
    @IBOutlet weak var userTopBarView: UIView!
    @IBOutlet weak var userTopBar: UIStackView!
    @IBOutlet weak var guestTopStackBar: UIStackView!
    @IBOutlet weak var guestBgBlurView: UIVisualEffectView!
    @IBOutlet weak var checkinIconView: UIImageView!
    @IBOutlet weak var mapRightSlider: UIView!
    @IBOutlet weak var mapLeftSlider: UIView!
    @IBOutlet weak var sliderCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var placeCheckinView: RoundedView!
    @IBOutlet weak var guestCheckinViewBtn: RoundedView!
    @IBOutlet weak var userProPicView: UIImageView!
    @IBOutlet weak var messagesCountView: RoundedView!
    @IBOutlet weak var messagesCountLabel: UILabel!
    @IBOutlet weak var notifCountLabel: UILabel!
    @IBOutlet weak var notifCountView: RoundedView!
    
    
    @IBOutlet weak var communitiesExpandView: LiquidGlassView!
    
    @IBOutlet weak var expandButtonView: LiquidGlassView!
    
    @IBOutlet weak var expandButton: UIButton!
    
    
    // implementation for the center plus icon.
    private let centerIndicatorView = UIImageView()
    private let tribePopupDistance: CLLocationDistance = 6000
    private var currentlyDetectedPlaceKey: String?
    private var hasShownTribePopupForKey: String?
    private var nearbyTribePlaces: [PolygonPlaceDetails] = []
    private var nearbyTribePopupView: NearbyTribePopupView?
    private var nearbyTribePopupMarker: GMSMarker?
    private var nearbyTribePopupPlaceKey: String?
    // Monotonic token for popup create requests. Every hide bumps it, so a create that was queued
    // behind an old card's fade-out becomes stale the moment a newer show/hide happens — the source
    // of the "two floating cards at once" bug during fast panning.
    private var nearbyPopupRequestSeq = 0
    
    
    
    @IBOutlet weak var currentAddressBgView: UIView!
        
    @IBOutlet weak var currentAddressContainer: LiquidGlassView!
    
    @IBOutlet weak var currentAddressLabel: UILabel!
    @IBOutlet weak var currentAddressSv: UIStackView!
    
    @IBOutlet weak var bottomSv: UIStackView!

    
    @IBOutlet weak var currentAddressSvTopConstraint: AdaptiveLayoutConstraint!
    
    private var carouselController: CarouselViewController!
    private var customButton : CustomRoundedButton!
    private var focusBackButton: UIButton!

    // Managers and ViewModels
    private var mapManager: MapManager!
    private var locationManager = LocationManager()
    private var searchBarManager: SearchBarManager!
    private var panGestureManager: PanGestureManager!  // Pan gesture manager for the sliders
    private var heightConstraintOfCarousel: NSLayoutConstraint!
    
    private var mapUpdatingView : MapUpdatingView?
    
    var isFirstTimeLocationEnableObserver: Bool = true
    private var hasAutoOpenedNearbyCommunitiesSheet = false
    private let nearbyPopupViewModel = NearbyPopupViewModel()
    
        
    @IBAction func gpsTapped(_ sender: Any) {

        
        if CLLocationManager.authorizationStatus() == .denied || CLLocationManager.authorizationStatus() == .restricted {
            // Permission denied or restricted, show an alert
            //showLocationPermissionAlert()
            moveToLastPickedLocation()
                       
        } else if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            // Permission granted, proceed with setting the camera to user location
            self.mapManager.lastCitySelected = ""
            mapManager.setMapCameraToUserLocation(zoomLevel: cameraZoom)
        } else {
            // Request permission if not determined
            locationManager.requestLocationPermissions()
        }
    }
    
    @IBAction func userProfileTapped(_ sender: Any) {
        if let searchBar = self.searchBarManager.searchBar {
            if !searchBar.isHidden {
                self.searchBarManager.searchBar.resignFirstResponder()
            }
        }
        gotoMyProfileView()
    }
    
    @IBAction func loginTapped(_ sender: Any) {
        if let searchBar = self.searchBarManager.searchBar {
            if !searchBar.isHidden {
                self.searchBarManager.searchBar.resignFirstResponder()
            }
        }
        gotoAuthView()
    }
    @IBAction func newsFeedTapped(_ sender: Any) {
        newsFeedClicked()
    }
    
    private func newsFeedClicked(){
        if let searchBar = self.searchBarManager.searchBar {
            if !searchBar.isHidden {
                self.searchBarManager.searchBar.resignFirstResponder()
            }
        }
        gotoNewsFeedView()
    }
    
    
    @IBAction func gotoGroupListTapped(_ sender: Any) {
//        groupListTapped()
        
        
        openNearbyCommunitiesSheet()
    }
    
    private func groupListTapped(){
        if let searchBar = self.searchBarManager.searchBar {
            if !searchBar.isHidden {
                self.searchBarManager.searchBar.resignFirstResponder()
            }
        }
        
        performGroupListTapAction()
    }
    
    @IBAction func centerBottomBtnTapped(_ sender: Any) {
        centerButtonTapped()
    }
    private func centerButtonTapped(){
        if let searchBar = self.searchBarManager.searchBar {
            if !searchBar.isHidden {
                self.searchBarManager.searchBar.resignFirstResponder()
            }
        }
        gotoUserCheckinView()
    }
    
    @IBAction func notificationBellTapped(_ sender: Any) {
        if let searchBar = self.searchBarManager.searchBar {
            if !searchBar.isHidden {
                self.searchBarManager.searchBar.resignFirstResponder()
            }
        }
        openNotificationView()
    }
    @IBAction func messagesTapped(_ sender: Any) {
        if let searchBar = self.searchBarManager.searchBar {
            if !searchBar.isHidden {
                self.searchBarManager.searchBar.resignFirstResponder()
            }
        }
        gotoMessagesListView()
    }
    
    private let formatter = ISOCommonFormatter.shared
    
   // let cameraZoom: Float = AppValues.isCurrentDeviceOld ? 15.5 : 14.25
    let cameraZoom: Float = 11.5//13.12 //13.205498
    private let minZoomForTapAction: Float = AppValues.isCurrentDeviceOld ? 12 : 11
    private let minZoomForDataLoad: Float = AppValues.isCurrentDeviceOld ? 11 : 10
    var mapView: GMSMapView!
   // var locationManager: CLLocationManager?
    var geoCoder = CLGeocoder()
    var userCurrentLocation: CLLocation?
    var userLocationAddressString: String?
    var isUpdatingLocation = false
    var isMapUpdating: Bool = false
    var isMarkerTapPerforming = false
    private var hasShownDefaultNearestTribePopup = false
    
    var mapRefreshTimer = Timer()
    
    var isUserLoggedIn: Bool {
        return UserSessionManager.shared.currentUser != nil
    }
    var isFetchingUnreadMessages = false
    var isFetchingUnreadNotifications = false
    var viewModel: MapViewModel!
    var userMarker: GMSMarker?
    var selectedMarkerInfoView: MapMarkerInfoView?
    private var searchBarHistoryText = ""
    private var isLocationPermissionDenied: Bool = false
    private var searchBarPlaceHolder: String = "Choose a city"
    //private var locationPermissionSubject = PassthroughSubject<Bool, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    private let minSelectedMarkerWidth: CGFloat = 60.toCGFloat.relativeToIphone8Width()
    
    private var disposeBag: Set<AnyCancellable> = []
    
    private func initialzeMapUpdatingView() {
        // Pass the parent view to the custom view initializer
        mapUpdatingView = MapUpdatingView(parentView: self.view, leftView: mapLeftSlider, rightView: mapRightSlider)
        
        mapUpdatingView?.progressBar(progress: 0.0)
        mapUpdatingView?.setAlphaForSubTitleLabel(alpha: 0.0)
            
        mapUpdatingView?.progressCallBack = { [weak self] progress in
            
            print("progressCallBack ==== \(progress)")
            
            if progress >= 85/100 && progress < 100/100 {
                //UIView.animate(withDuration: 0.25) { [weak self] in
                self?.mapUpdatingView?.setAlphaForSubTitleLabel(alpha: 1.0)
                //}
            }
            
            if progress >= 1 {
                self?.mapUpdatingView?.isHidden = true
                self?.mapUpdatingView?.progressBar(progress: 0.0)
                self?.mapUpdatingView?.setAlphaForSubTitleLabel(alpha: 0.0)
            }
        }
        mapUpdatingView?.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    
        let tap = UITapGestureRecognizer(target: self, action: #selector(openNearbyCommunitiesSheet))
        communitiesExpandView.addGestureRecognizer(tap)
        communitiesExpandView.isUserInteractionEnabled = true

        expandButton.addTarget(self, action: #selector(openNearbyCommunitiesSheet), for: .touchUpInside)
        
        currentAddressContainer.backgroundColor = .clear
        currentAddressSv.backgroundColor = .clear
        currentAddressLabel.backgroundColor = .clear
        searchBarManager = SearchBarManager(permission: true, parentView: self.view, currentAddressV: currentAddressSv, leftView: mapLeftSlider, rightView: mapRightSlider)
        
        initialzeMapUpdatingView()
       
        if let pendingNotifTapObj = PushNotificationUIManager.shared.pendingOpenNotification {
            PushNotificationUIManager.shared.goToNotificationContentView(notif: pendingNotifTapObj)
            PushNotificationUIManager.shared.pendingOpenNotification = nil
            DynamicLinkUIManager.shared.pendingDynamicLink = nil
        }
        else if let pendingDynamicLink = DynamicLinkUIManager.shared.pendingDynamicLink {
            DynamicLinkUIManager.shared.handleDeeplink(link: pendingDynamicLink)
            PushNotificationUIManager.shared.pendingOpenNotification = nil
            DynamicLinkUIManager.shared.pendingDynamicLink = nil
        }
        
        initializeLocationManager(shouldShowAlert: true)
        // Refactored Code
        setupManagers()
        setupCenterPlusIndicator()
        updateNearbyCommunitiesVisibility()
        setAttributedTitle()
        addObservers()
        updateUnreadNotifCount(value: OrbisNotificationCount(notifications: 0, pendingRequests: 0))
        
        setupCarouselController()
        setupTopCustomRoundButton()
        
        viewModel = MapViewModel(mapView: mapManager.mapView!)
        handleViewModelActionMethods()
        
        ForceUpdateManager.shared.verifyVersion()
        
        
    }
    private func updateNearbyCommunitiesVisibility() {
        // Never show the nearby-tribes expand affordances ("^" button) in territory focus mode.
        let hasTribes = !mapManager.getAllVisibleTribes().isEmpty
        let hidden = !hasTribes || mapManager.isGroundOverlayClicked2
        communitiesExpandView.isHidden = hidden
        expandButtonView.isHidden = hidden
        expandButton.isHidden = hidden
    }
    private func autoOpenNearbyCommunitiesSheetIfNeeded(with places: [PolygonPlaceDetails]) {
        guard !hasAutoOpenedNearbyCommunitiesSheet else { return }
        guard !places.isEmpty else { return }
        guard presentedViewController == nil else { return }

        hasAutoOpenedNearbyCommunitiesSheet = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self else { return }
            self.openNearbyCommunitiesSheet()
        }
    }
    
    
    @objc private func openNearbyCommunitiesSheet() {
        let tribes = mapManager.getAllVisibleTribes()
        guard !tribes.isEmpty else {
            print("nearby - tribes list is empty")
            return
        }
        let storyboard = UIStoryboard(name: "Home", bundle: .main)
        let vc = storyboard.instantiateViewController(withIdentifier: "NearbyCommunitiesSheetViewController") as! NearbyCommunitiesSheetViewController
        vc.places = tribes
        vc.searchLocation = mapManager.mapView?.camera.target
        vc.onSelectGroup = { [weak self, weak vc] group in
            // Server search result row: same destination as a nearby row — the tribe's detail screen.
            vc?.dismiss(animated: true) {
                self?.gotoGroupDetailView(withModel: group)
            }
        }
        vc.onSelectPlace = { [weak self, weak vc] place in
            // Android parity (#8): GroupListBottomSheet.onItemClicked -> GroupDetailsActivity, then hide sheet.
            // No map focus / no camera move — dismiss the sheet, then push the group detail screen.
            vc?.dismiss(animated: true) {
                guard let self = self,
                      let group = place.toOrbisPlace().placeDominantGroup else { return }
                self.gotoGroupDetailView(withModel: group)   // same resolution as didTapNearbyTribePopup
            }
        }
        vc.onNewsFeedTap = { [weak self] in
            self?.newsFeedClicked()
        }
        
        vc.onCenterBottomTap = { [weak self] in
            self?.centerButtonTapped()
        }

        vc.onGroupListTap = { [weak self] in
            self?.groupListTapped()
        }
        
        vc.onPlusButtonTapped = { [weak self] in
            self?.openCreateNewGroupView()
        }

        
        if #available(iOS 16.0, *) {
            if let sheet = vc.sheetPresentationController {
                sheet.delegate = vc
                sheet.detents = [
                    .custom(identifier: .init("small")) { _ in
                        NearbyCommunitiesSheetViewController.peekHeight
                    },
                    .large()
                ]
                sheet.selectedDetentIdentifier = .init("small")
                sheet.largestUndimmedDetentIdentifier = .init("small")
                sheet.preferredCornerRadius = 18
            }
        } else if #available(iOS 15.0, *) {
            if let sheet = vc.sheetPresentationController {
                sheet.delegate = vc
                sheet.detents = [.medium(), .large()]
                sheet.selectedDetentIdentifier = .medium
                sheet.largestUndimmedDetentIdentifier = .medium
                sheet.preferredCornerRadius = 18
            }
        }
        present(vc, animated: true)
    }
    
    
    private func setupCenterPlusIndicator() {
        centerIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        centerIndicatorView.image = UIImage(systemName: "plus")
        centerIndicatorView.tintColor = UIColor(named: "appBlack2")
        centerIndicatorView.contentMode = .scaleAspectFit
        centerIndicatorView.backgroundColor = .clear
        centerIndicatorView.layer.cornerRadius = 14
        centerIndicatorView.clipsToBounds = true
        centerIndicatorView.isHidden = true
        view.addSubview(centerIndicatorView)
        NSLayoutConstraint.activate([
            centerIndicatorView.centerXAnchor.constraint(equalTo: mapContainerView.centerXAnchor),
            centerIndicatorView.centerYAnchor.constraint(equalTo: mapContainerView.centerYAnchor),
            centerIndicatorView.widthAnchor.constraint(equalToConstant: 20),
            centerIndicatorView.heightAnchor.constraint(equalToConstant: 20)
        ])

        view.bringSubviewToFront(centerIndicatorView)
        updateCenterPlusVisibility()
    }
    
    private func shouldShowDefaultNearestTribePopup() -> Bool {
        return !hasUsableMapLocation() && !hasShownDefaultNearestTribePopup
    }

    private func showDefaultNearestTribePopupIfNeeded(from places: [PolygonPlaceDetails]) {
        guard shouldShowDefaultNearestTribePopup() else { return }
        guard let mapView = mapManager.mapView else { return }
        guard !places.isEmpty else { return }

        let center = mapView.camera.target

        let nearestPlace = places.min { first, second in
            distanceFromMapCenter(center, to: first) < distanceFromMapCenter(center, to: second)
        }

        guard let place = nearestPlace else { return }

        hasShownDefaultNearestTribePopup = true
        showNearbyTribePopup(place: place)
    }

    private func distanceFromMapCenter(
        _ center: CLLocationCoordinate2D,
        to place: PolygonPlaceDetails
    ) -> CLLocationDistance {
        
        let centerLocation = CLLocation(
            latitude: center.latitude,
            longitude: center.longitude
        )

        if let coordinate = place.coordinates?.toCLLocationCoordinate2D() {
            let placeLocation = CLLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            return centerLocation.distance(from: placeLocation)
        }

        if let points = place.polygonPoints, !points.isEmpty {
            let nearestDistance = points.map { point -> CLLocationDistance in
                let coordinate = point.toCLLocationCoordinate2D()
                let location = CLLocation(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                return centerLocation.distance(from: location)
            }.min()

            return nearestDistance ?? CLLocationDistance.greatestFiniteMagnitude
        }

        return CLLocationDistance.greatestFiniteMagnitude
    }
    
    
    
    
    // Setting up managers for location, map, search bar, etc.
    private func setupManagers() {
       
        // Initialize the map manager and the mapView
        mapManager = MapManager(
                    mapContainerView: mapContainerView,
                    locationManager: locationManager,
                    cameraZoom: cameraZoom,
                    minZoomForDataLoad: minZoomForDataLoad
                )
        
        mapManager.delegate = self
        
        locationManager.delegate = self
        
        panGestureManager = PanGestureManager(leftSlider: mapLeftSlider, rightSlider: mapRightSlider, sliderCenterConstraint: sliderCenterConstraint)
        
        panGestureManager.isDraggingMapViewCallBack = { [weak self] isDragging in
            self?.mapManager.isDrag = isDragging
        }
        
        panGestureManager.mapViewZoomCallBack = { [weak self] zoom in
            self?.mapManager.mapView?.animate(toZoom: zoom)
            if let searchBar = self?.searchBarManager.searchBar {
                if !searchBar.isHidden {
                    self?.searchBarManager.searchBar.resignFirstResponder()
                }
            }
        }
        
        //locationManager.enableLocationService()
        
        locationManager.locationPermissionDenied
            .sink { [weak self] isDenied in
                
                if self!.isFirstTimeLocationEnableObserver {
                    self?.isFirstTimeLocationEnableObserver = false
                    return
                }
                
                self?.handleLocationPermissionDenied(isDenied, completion: { [weak self] in
                    
                    if !isDenied {
                        self?.mapManager.locationservicesEnabledandAuthorized(isAuthrized: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                            
                            
                            self?.mapManager.updateMapInteractionSettings() //previously self instead of mapManager
                            self?.mapManager.placeViewModel.locationSharedOrSelected = true
                            self?.getUserCurrentLocation()
                        }
                    }else{
                        self?.mapManager.locationservicesEnabledandAuthorized(isAuthrized: false)
                        
                       // if let mapM = self?.mapManager, !mapM.isCitySaved() {
                            self?.moveToNewYorkIfNotPickedLocation()
                        //}
                    }
                })
            }
            .store(in: &cancellables)
        
    }
    
    private func checkIfMapCenterIsNearTribe() {
        guard let mapView = mapManager.mapView else { return }

        let centerCoordinate = mapView.camera.target

        print("Debug - checking center plus at: \(centerCoordinate)")

        guard let tribe = viewModel.nearbyTribeForMapCenter(
            centerCoordinate,
            bufferMeters: 500
        ) else {
            print("Debug - no nearby tribe found")
            currentlyDetectedPlaceKey = nil
            return
        }

        print("Debug - nearby tribe found: \(tribe.name ?? "No Name")")

        guard let placeKey = tribe.placeKey else { return }

        if hasShownTribePopupForKey != placeKey {
            hasShownTribePopupForKey = placeKey
            showTribeNearbyPopup(place: tribe.toOrbisPlace())
        }
    }
    
    private func isMapCenterInsideOrNearTribe(
        center: CLLocationCoordinate2D,
        tribe: PolygonPlaceDetails,
        bufferMeters: CLLocationDistance = 150
    ) -> Bool {

        if let points = tribe.polygonPoints, !points.isEmpty {
            let path = GMSMutablePath()

            for point in points {
                path.add(point.toCLLocationCoordinate2D())
            }

            if GMSGeometryContainsLocation(center, path, true) {
                return true
            }

            for index in 0..<points.count {
                let start = points[index].toCLLocationCoordinate2D()
                let end = points[(index + 1) % points.count].toCLLocationCoordinate2D()

                let distance = GMSGeometryDistance(center, nearestPointOnSegment(center, start, end))

                if distance <= bufferMeters {
                    return true
                }
            }

            return false
        }

        if let circleCenter = tribe.coordinates?.toCLLocationCoordinate2D() {
            let distance = GMSGeometryDistance(center, circleCenter)
            let radius = CLLocationDistance(tribe.size ?? 0)
            return distance <= radius + bufferMeters
        }

        return false
    }
    
    private func nearestPointOnSegment(
        _ point: CLLocationCoordinate2D,
        _ start: CLLocationCoordinate2D,
        _ end: CLLocationCoordinate2D
    ) -> CLLocationCoordinate2D {

        let px = point.longitude
        let py = point.latitude
        let ax = start.longitude
        let ay = start.latitude
        let bx = end.longitude
        let by = end.latitude

        let dx = bx - ax
        let dy = by - ay

        if dx == 0 && dy == 0 {
            return start
        }

        let t = max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))

        return CLLocationCoordinate2D(
            latitude: ay + t * dy,
            longitude: ax + t * dx
        )
    }
    
    private func showTribeNearbyPopup(place: OrbisPlace) {
        guard let group = place.placeDominantGroup else { return }

        let alert = UIAlertController(
            title: "Tribe Nearby",
            message: "You are close to \(group.name ?? "this tribe").",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "View Tribe", style: .default, handler: { [weak self] _ in
            self?.gotoGroupDetailView(withModel: group)
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }
    
    private func setupSearchBar(isPermissionDenied: Bool) {
        searchBarManager.permissionSetup(permission: isPermissionDenied)
        searchBarManager.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navVC = self.navigationController, navVC.viewControllers[0].isKind(of: OnboardingViewController.self) {
            self.navigationController?.viewControllers.remove(at: 0)
        }
        updateAuthViews()
        fetchUnreadMessagesIfNecessary()
        fetchUnreadNotificationsCount()
        
        if self.isLocationPermissionDenied {
            // Center on New York if location permission is denied and no save city else move to saveCity
            if !self.searchBarManager.isCitySaved() {
                self.searchBarManager?.searchBarView.isHidden = false
            }
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("+++ DID RECEIVE MEMORY WARNING!!!")
        print("Received memory warning. Clearing up resources HomeMapViewController.")

    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func fetchUnreadNotificationsCount() {
        guard isUserLoggedIn else { return }
        guard !isFetchingUnreadNotifications else { return }
        isFetchingUnreadNotifications = true
        viewModel.fetchUnreadNotificationCount { [weak self] data, err in
            if let count = data as? OrbisNotificationCount {
                UserSessionManager.shared.userNotificationCount = count
                self?.updateUnreadNotifCount(value: count)
            }
            self?.isFetchingUnreadNotifications = false
        }
    }
    
    private func fetchUnreadMessagesIfNecessary() {
        guard isUserLoggedIn else { return }
        guard !isFetchingUnreadMessages else { return }
        isFetchingUnreadMessages = true
        viewModel.fetchUnreadMessagesCount { [weak self] data, err in
            if let count = data as? Int {
                self?.updateUnreadMessagesCount(value: count)
            }
            self?.isFetchingUnreadMessages = false
        }
    }
    
    private func updateUnreadNotifCount(value: OrbisNotificationCount) {
        let sum = value.sum
        notifCountLabel.text = "\(sum)"
        notifCountView.isHidden = sum <= 0
    }
    
    private func updateUnreadMessagesCount(value: Int) {
        messagesCountLabel.text = "\(value)"
        messagesCountView.isHidden = value <= 0
    }
    
    private func handleViewModelActionMethods() {
        viewModel.onFetchedPlaceForMapNotifier = {
            [weak self] place in
            guard let self = self else { return }
            self.viewModel.addUpdatePlaceToMapFromObserver(mapView: self.mapView, place: place, isNewlyCreatedPlace: true)
        }
        viewModel.onPlaceSizeChangeNotifier = {
            [weak self] place in
            guard let self = self else { return }
            self.viewModel.addUpdatePlaceToMapFromObserver(mapView: self.mapView, place: place, isNewlyCreatedPlace: true)
        }
        viewModel.onGroupOwnerShipChangeNotifier = {
            [weak self] place in
            guard let self = self else { return }
            self.viewModel.addUpdatePlaceToMapFromObserver(mapView: self.mapView, place: place, isNewlyCreatedPlace: true)
        }
        viewModel.onFirstPageLoadComplete = {
            [weak self] in
            self?.hideOrbisLoader()
        }
        viewModel.onMapSelectedMarkerRemoved = {
            [weak self] in
            self?.mapManager.removeSelectedMarkerInfoView() //previously without mapManager
        }
        
        viewModel.$centerCoordinatePlaceModel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] placeModel in
                //TODO: we are not using it anymore.
                //self?.updateCenterPlaceNameUI(withModel: self?.viewModel.centerCoordinatePlaceModel)
               // self?.mapManager.updateCenterPlaceNameUI(withModel: placeModel)
            }
            .store(in: &disposeBag)
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(userDidLogin(_:)), name: NSNotification.Name(AppNotificationKeys.userDidLogin), object: nil)
    }
    
    @objc private func userDidLogin(_ notification: NSNotification) {
        updateAuthViews()
    }
    
    private func updateAuthViews() {
        guestTopStackBar.isHidden = isUserLoggedIn
        //        guestBgBlurView.isHidden = isUserLoggedIn
        userTopBar.isHidden = !isUserLoggedIn
        userTopBarView.isHidden = !isUserLoggedIn
        
        placeCheckinView.isHidden = !isUserLoggedIn
        guestCheckinViewBtn.isHidden = isUserLoggedIn
        updateUserProfilePic()
    }
    
    private func updateUserProfilePic() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard let imageLink = UserSessionManager.shared.currentUser?.proPicLink, !imageLink.isEmpty else {
            userProPicView.image = placeholderImage
            return
        }
        userProPicView.setSDWebImage(urlString: imageLink, placeholderImage: placeholderImage, storageDirectory: .profilePictures, sizeModifier: .fourHundred)
    }
    
    private func setAttributedTitle() {
        let attributedString = NSMutableAttributedString(string: "ORBIS")
        attributedString.addAttribute(NSAttributedString.Key.kern, value: CGFloat(4.8), range: NSRange(location: 0, length: attributedString.length))
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(named: AppColors.appBlack.rawValue)!, range: NSRange(location: 0, length: attributedString.length))
        attributedString.addAttribute(NSAttributedString.Key.font, value: orbisTitleLable.font!, range: NSRange(location: 0, length: attributedString.length))
        orbisTitleLable.attributedText = attributedString
    }
    
    private func gotoMessagesListView() {
        let messageListVC = UIStoryboard.getViewController(inStoryboard: "Chat", identifier: "messageListVC") as! MessageListViewController
        self.navigationController?.pushViewController(messageListVC, animated: true)
    }
    
    
    private func gotoNewsFeedView() {

        // Android parity (#2, MapFragment.kt:801-808): read the map camera target UNCONDITIONALLY —
        // no GPS/mLastLocation gate. MapManager always parks the camera on the saved city or the NY
        // default, so camera.target is always valid; a location-denied user browses New York rather
        // than being stranded on the map with no feed. (The old mLastLocation guard never even used
        // its bound value — the body already reads camera.target.)
        let watchingLocation = CLLocation(
            latitude: self.mapManager.mapView!.camera.target.latitude,
            longitude: self.mapManager.mapView!.camera.target.longitude
        )

        Constants.location = watchingLocation
        Constants.feedCity = self.searchBarManager.searchBar.text

        let newsFeedVC = UIStoryboard.getViewController(inStoryboard: "NewsFeed", identifier: "newsFeedTabVC") as! NewsFeedTabViewController
        self.navigationController?.pushViewController(newsFeedVC, animated: true)
    }
    
    private func showMapScene() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                        let delegate = windowScene.delegate as? SceneDelegate, let window = delegate.window else { return }
        let homeNavVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "homeNavVC") as! UINavigationController
        let mapVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "homeMainVC") as! HomeMapViewController
        homeNavVC.viewControllers = [mapVC]
        window.rootViewController = homeNavVC
        window.makeKeyAndVisible()
    }
    

    
    
    private func performGroupListTapAction() {

        // Android parity (#2, GroupListActivity path): map camera target unconditionally, no GPS gate.
        let watchingLocation = CLLocation(
            latitude: self.mapManager.mapView!.camera.target.latitude,
            longitude: self.mapManager.mapView!.camera.target.longitude
        )
        Constants.location = watchingLocation
        Constants.groupCity = self.searchBarManager.searchBar.text
        gotoGroupListView()
    }
    private func hasUsableMapLocation() -> Bool {
        let hasUserLocation = UserSessionManager.shared.userCurrentLocation != nil

        let prefs = UserDefaults.standard
        let savedLat = prefs.float(forKey: "selected_city_latitude")
        let savedLon = prefs.float(forKey: "selected_city_longitude")
        let hasSavedCity = savedLat != 0 && savedLon != 0

        return hasUserLocation || hasSavedCity
    }

    private func updateCenterPlusVisibility() {
        centerIndicatorView.isHidden = !hasUsableMapLocation()
    }

    
    private func gotoGroupListView() {
        let groupListVC = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "groupListVC") as! GroupListViewController
        self.navigationController?.pushViewController(groupListVC, animated: true)
    }
    private func openCreateNewGroupView() {
        guard let _ = UserSessionManager.shared.currentUser else {
            gotoAuthView()
            return
        }
        let createGroupView = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "createGroupVC") as! CreateGroupViewController
        createGroupView.viewModel = CreateGroupViewModel()
        self.navigationController?.pushViewController(createGroupView, animated: true)
    }
    
    private func gotoAuthView() {
        if UserSessionManager.shared.hasLoginOnboardingBeenShown {
            let authView = UIStoryboard.getViewController(inStoryboard: "Auth", identifier: "authMainVC") as! AuthMainViewController
            authView.defaultSelectionIndex = 0
            self.navigationController?.pushViewController(authView, animated: true)
        }
        else {
            UserSessionManager.shared.setLoginOnboardingShown()
            let authOptionPickerVC = UIStoryboard.getViewController(inStoryboard: "Auth", identifier: "authOptionPickerVC") as! AuthOptionPickerViewController
            self.navigationController?.pushViewController(authOptionPickerVC, animated: true)
        }
    }
    
    private func gotoMyProfileView() {
        let myProfileVC = UIStoryboard.getViewController(inStoryboard: "Profile", identifier: "userProfileVC") as! UserProfileViewController
        myProfileVC.viewModel = ProfileDetailViewModel(user: UserSessionManager.shared.currentUser!, isViewingSelf: true)
        self.navigationController?.pushViewController(myProfileVC, animated: true)
    }
    
    func gotoPlaceDetailView(viewModel: PlaceDetailViewModel? = nil) {
        let placeDetailVC = UIStoryboard.getViewController(inStoryboard: "Places", identifier: "placeDetailVC") as! PlaceDetailViewController
        if let viewModel = viewModel {
            placeDetailVC.viewModel = viewModel
        }
        else {
            placeDetailVC.viewModel = PlaceDetailViewModel(place: OrbisPlace())
        }
        self.navigationController?.pushViewController(placeDetailVC, animated: true)
    }
    
    private func gotoUserCheckinView() {
        guard isUserLoggedIn else {
            gotoAuthView()
            return
        }
        guard UserSessionManager.shared.userCurrentLocation != nil else {
            initializeLocationManager(shouldShowAlert: true)
            return
        }
        //MARK: get current map location
        let watchingLocation = CLLocation(
            latitude: self.mapManager.mapView!.camera.target.latitude,
            longitude: self.mapManager.mapView!.camera.target.longitude
        )
        Constants.location = watchingLocation
        
        let userCheckinVC = UIStoryboard.getViewController(inStoryboard: "Places", identifier: "userCheckinVC") as! UserCheckinViewController
        userCheckinVC.modalPresentationStyle = .overCurrentContext
        userCheckinVC.onCreatePlaceTapped = {
            [weak self] in
            self?.gotoCreatePlaceView()
        }
        userCheckinVC.onCheckinSelect = {
            [weak self] place in
            self?.gotoPlaceDetailView(viewModel: PlaceDetailViewModel(place: place))
        }
        presentPanModal(userCheckinVC)
    }
    
    private func gotoCreatePlaceView() {
        guard isUserLoggedIn else {
            gotoAuthView()
            return
        }
        
        let createPlaceVC = UIStoryboard.getViewController(inStoryboard: "Places", identifier: "createPlaceVC") as! CreatePlaceViewController
        createPlaceVC.modalPresentationStyle = .overCurrentContext
        createPlaceVC.onCreateSuccess = {
            [weak self] place in
            guard let self = self else { return }
            
            //TODO: original code
            //self.handleCreatePlaceSuccess(place: place)
            //mapping to this code
            loadCheckIn(newPlace: place, checkInPolygonCoordinateKey: place.checkInPolygonCoordinateKey!)
        }
        presentPanModal(createPlaceVC)
    }

    func loadCheckIn(newPlace: PlaceDetails, checkInPolygonCoordinateKey: String) {
        print("placeCreated: checkInPolygonId: \(checkInPolygonCoordinateKey)")
        
        // Update lastPlaceCreatedKey and lastLocation
        self.mapManager.lastPlaceCreatedKey = newPlace.placeKey!
        self.mapManager.lastLocation = newPlace.coordinates?.toCLLocationCoordinate2D()
        
        // Ask the view model to update the polygon map
        self.mapManager.placeViewModel.askPolygonMapUpdate(checkInPolygonCoordinateKey: checkInPolygonCoordinateKey, place: newPlace)
        
        // Mark check-in as not completed and start loading
        self.mapManager.checkInCompleted = false
        self.mapManager.startCheckInLoading()
        
        finalizeCheckIn(newPlace: newPlace)

        // Use Task for asynchronous progress updates
        Task {
            // First phase: 1 to 15
            for i in 1...15 {
                await updateCheckInProgress(to: i)
                try? await Task.sleep(nanoseconds: 55 * 1_000_000) // 55 milliseconds
            }
            
            // Second phase: 16 to 75
            for i in 16...75 {
                await updateCheckInProgress(to: i)
                try? await Task.sleep(nanoseconds: 26 * 1_000_000) // 26 milliseconds
            }
            
            // Third phase: 76 to 99
            for i in 76...99 {
                await updateCheckInProgress(to: i)
                try? await Task.sleep(nanoseconds: 300 * 1_000_000) // 300 milliseconds
            }
            
            // Finalize progress and perform navigation
            await updateCheckInProgress(to: 100) // Ensure progress reaches 100%
        }
    }

    // Method to update progress in the UI
    private func updateCheckInProgress(to progress: Int) async {
        DispatchQueue.main.async { [weak self] in
            self?.mapUpdatingView?.progressBar(progress: Float(progress) / 100.0)
        }
    }

    // Method to handle completion and navigation
    private func finalizeCheckIn(newPlace: PlaceDetails) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {return}
            self.mapUpdatingView?.progressBar(progress: 1.0)
            self.mapUpdatingView?.isHidden = true
            
            // Create and configure the intent for PlaceActivity
            let watchingLocation = CLLocation(
                latitude: self.mapManager.mapView?.camera.target.latitude ?? 0.0,
                longitude: self.mapManager.mapView?.camera.target.longitude ?? 0.0
            )
            Constants.location = watchingLocation
            
            // Pass the newPlace data to the next view controller
            self.gotoPlaceDetailView(viewModel: PlaceDetailViewModel(place: newPlace.toOrbisPlace()))
        }
    }
    
    
    func handlePlaceCheckinSuccess(place: OrbisPlace) {
        
        
        //MARK: updae checkIn situation
        if (Constants.lastCheckinPlace != nil && Constants.lastCheckInPolygonCoordinateKey != nil && !mapManager.placeSheetCheckIn){
            
            //            let newPlace = Constants.lastCheckinPlace
            //            let chekInCoordkey = Constants.lastCheckInPolygonCoordinateKey
            self.mapManager.updatingMap()
            
            loadCheckIn(newPlace: place.toPlaceDetails(), checkInPolygonCoordinateKey: place.checkInPolygonCoordinateKey!)
        }
    }
    
     
    
    private func openNotificationView() {
        guard isUserLoggedIn else {
            gotoAuthView()
            return
        }
        if UserSessionManager.shared.currentUser?.accountPrivate == true {
            let privateNotificationVC = UIStoryboard.getViewController(inStoryboard: "Notification", identifier: "privateNotificationVC") as! PrivateAccountNotificationViewController
            let navVC = OrbisNavigationController(rootViewController: privateNotificationVC)
            navVC.modalPresentationStyle = .overFullScreen
            presentPanModal(navVC)
        }
        else {
            let publicAccNotificationVC = UIStoryboard.getViewController(inStoryboard: "Notification", identifier: "publicAccountNotificationVC") as! PublicAccountNotificationListViewController
            let navVC = OrbisNavigationController(rootViewController: publicAccNotificationVC)
            navVC.modalPresentationStyle = .overFullScreen
            presentPanModal(navVC)
        }
    }
    private func zoomToTribe(_ place: PolygonPlaceDetails) {
        guard let mapView = mapManager.mapView else { return }

        hideNearbyTribePopup()

        if let points = place.polygonPoints, !points.isEmpty {
            let bounds = GMSCoordinateBounds()

            var updatedBounds = bounds
            points.forEach { point in
                updatedBounds = updatedBounds.includingCoordinate(
                    point.toCLLocationCoordinate2D()
                )
            }

            let update = GMSCameraUpdate.fit(updatedBounds, withPadding: 80)
            mapView.animate(with: update)

        } else if let coordinate = place.coordinates?.toCLLocationCoordinate2D() {
            let camera = GMSCameraPosition.camera(
                withTarget: coordinate,
                zoom: 15
            )

            mapView.animate(to: camera)
        }

        selectedPlaceToScrollCarousel(place: place)
    }
    
    // MARK:- User Location Methods
    private func initializeLocationManager(shouldShowAlert: Bool) {
        
        locationManager.stopUpdatingLocation()
        
        currentAddressSv.isHidden = true
        
        locationManager.enableLocationService()
        
        guard let searchBarManager = self.searchBarManager else {
            return
        }
        searchBarManager.updateVisibitiy(isHidden: true)
    }
    
    private func handleLocationPermissionDenied(_ isDenied: Bool,completion: @escaping () -> Void) {
        if isDenied {
            isLocationPermissionDenied = true
            setupSearchBar(isPermissionDenied: true)
            currentAddressSv.isHidden = true
            currentAddressContainer.isHidden = true
            mapManager.updateMapInteractionSettings()
            
            if self.mapManager.isCitySaved() {
                currentAddressContainer.isHidden = false
                currentAddressSv.isHidden = false
                mapLeftSlider.isUserInteractionEnabled = true
                mapRightSlider.isUserInteractionEnabled = true
            }else {
                mapLeftSlider.isUserInteractionEnabled = false
                mapRightSlider.isUserInteractionEnabled = false
            }
            
            view.layoutIfNeeded()
            completion()
        }else{
           // self.showOrbisLoader(disableUserInteraction: true) TODO: need to tackle this later
            self.mapManager.mapView?.isUserInteractionEnabled = false
            isLocationPermissionDenied = false
            setupSearchBar(isPermissionDenied: false)
            currentAddressContainer.isHidden = true
            currentAddressSv.isHidden = true
            
            if self.mapManager.isCitySaved() {
                currentAddressContainer.isHidden = false
                currentAddressSv.isHidden = false
                mapLeftSlider.isUserInteractionEnabled = true
                mapRightSlider.isUserInteractionEnabled = true
            }else {
                mapLeftSlider.isUserInteractionEnabled = true
                mapRightSlider.isUserInteractionEnabled = true
            }
            
            view.layoutIfNeeded()
            //self.hideOrbisLoader()
            completion()
        }
    }
    
    fileprivate func getUserCurrentLocation() {
        guard !isUpdatingLocation else {return}
       
        locationManager.startUpdatingLocation()
    }
    
    private func gotoGroupDetailView(withModel model: Group) {
        let groupDetailsVC = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "groupDetailVC") as! GroupDetailsViewController
        groupDetailsVC.viewModel = GroupDetailViewModel(group: model)
        self.navigationController?.pushViewController(groupDetailsVC, animated: true)
    }
    
    private func gotoGroupDetails(withPlaceKey key: String) {
        guard !key.isEmpty else { return }
        //guard let place = viewModel.mapData.first(where: {$0.placeKey == key }), let group = place.placeDominantGroup else { return }
        guard let place = viewModel.mapData[key], let group = place.placeDominantGroup else { return }
        gotoGroupDetailView(withModel: group)
    }
    
    private func gotoPlaceDetails(withKey key: String) {
        guard !key.isEmpty else { return }
        //guard let place = viewModel.mapData.first(where: {$0.placeKey == key }) else { return }
        guard let place = viewModel.mapData[key] else { return }
        gotoPlaceDetailView(viewModel: PlaceDetailViewModel(place: place))
    }
}

//MARK: - LocationManagerDelegate
extension HomeMapViewController: LocationManagerDelegate{
    
    func showLocationPermissionAlert() {
        self.showAlert(title: AppStrings.AppPermission.Location.title , message: AppStrings.AppPermission.Location.message )
    }
    
    func navigateToLocatonPermissionAlert() {
        self.navigateToLocatonSettingScreen(title: AppStrings.AppPermission.Location.title , message: AppStrings.AppPermission.Location.message )
    }
    
    func didUpdateLocation(_ location: CLLocation) {

        hasShownDefaultNearestTribePopup = true
        hideNearbyTribePopup()
        // This hide is VC-initiated (not a closest-tribe change) — reset the manager's key or it
        // will never re-emit didFindNearbyTribe for the same tribe and the popup stays gone.
        mapManager.clearNearbyTribeKey()

        UserSessionManager.shared.userCurrentLocation = location.coordinate
        self.mapManager.userCurrentLocation = location
        updateCenterPlusVisibility()
        if self.mapManager.placeViewModel.locationSharedOrSelected {
            
            let sharedPreferences = UserDefaults.standard
            let savedCityLat = sharedPreferences.float(forKey: "selected_city_latitude")
            let savedCityLon = sharedPreferences.float(forKey: "selected_city_longitude")
            let isSavedCity = savedCityLat != 0 && savedCityLon != 0
            
            if !isSavedCity {
                //move to center
                searchBarManager.moveSearchBarToCenter()
                mapManager.updateUserLocation(location: location, moveToUserLocation : true)
              
            }else{
                //move to top
                searchBarManager.moveSearchBarUp()
            }
    
        }
    }
    
    func didUpdateLocationAuthorization(_ isAuthorized: Bool) {
        isLocationPermissionDenied = !isAuthorized
        setupSearchBar(isPermissionDenied: !isAuthorized)
        
        let sharedPreferences = UserDefaults.standard
        let savedCityLat = sharedPreferences.float(forKey: "selected_city_latitude")
        let savedCityLon = sharedPreferences.float(forKey: "selected_city_longitude")
        let isSavedCity = savedCityLat != 0 && savedCityLon != 0
        
        if !isSavedCity {
            //move to center
            searchBarManager.moveSearchBarToCenter()
        }else{
            //move to top
            searchBarManager.moveSearchBarUp()
        }
        
        
        if self.isLocationPermissionDenied {
            
            if !self.searchBarManager.isCitySaved() {
                self.searchBarManager?.searchBarView.isHidden = false
            }
        }
    }
    
    func moveToLastPickedLocation(){
        let sharedPreferences = UserDefaults.standard
        let savedCityLat = sharedPreferences.float(forKey: "selected_city_latitude")
        let savedCityLon = sharedPreferences.float(forKey: "selected_city_longitude")
        let isSavedCity = savedCityLat != 0 && savedCityLon != 0
        
        if isSavedCity {
            let customLocation = CLLocation(latitude: Double(savedCityLat), longitude: Double(savedCityLon))
            mapManager.centerMapOnLocation(location: customLocation, title: "", displayMarker: false)
        }else{
            navigateToLocatonPermissionAlert()
        }
    }
    
    func moveToNewYorkIfNotPickedLocation(){
        let sharedPreferences = UserDefaults.standard
        let savedCityLat = sharedPreferences.float(forKey: "selected_city_latitude")
        let savedCityLon = sharedPreferences.float(forKey: "selected_city_longitude")
        let isSavedCity = savedCityLat != 0 && savedCityLon != 0
        
        if isSavedCity {
            let customLocation = CLLocation(latitude: Double(savedCityLat), longitude: Double(savedCityLon))
            mapManager.centerMapOnLocation(location: customLocation, title: "", displayMarker: false)
        }else{
           let NYLocation = CLLocation(latitude: Double(NewYorkCoordinates.latitude), longitude: Double(NewYorkCoordinates.longitude))
            
            let coordinatesToUse = GMSCameraPosition.camera(withLatitude: NYLocation.coordinate.latitude, longitude: NYLocation.coordinate.longitude, zoom: cameraZoom)
            
            CLHelper.resetFirstTimeAction()
            self.mapManager.mapView?.animate(to: coordinatesToUse)
            mapManager.startedOnCity = true
            
            if !mapManager.loadedOverlay {
                mapManager.bindingloading = true
                self.showMapCenteredLoader()
                mapManager.placeViewModel.findPolygonPlacesForMap(latitude: mapManager.NewYork.latitude, longitude: mapManager.NewYork.longitude)
            }
        }
    }
    
}

//MARK: MapManagerDelegate

extension HomeMapViewController: MapManagerDelegate {
    
    
    
    
    func mapManager(_ manager: MapManager, showHide isHidden: Bool) {
        
        if isHidden {
            if let searchBar = self.searchBarManager.searchBar {
                if !searchBar.isHidden {
                    self.searchBarManager.searchBar.resignFirstResponder()
                }
            }
        }
        
        self.searchBarManager?.searchBarView.isHidden = isHidden
    }
    
    func mapManager(_ manager: MapManager, gotoView: Bool, withKey: String) {
        
        if gotoView {
            self.gotoPlaceDetails(withKey: withKey)
        }else{
            self.gotoGroupDetails(withPlaceKey: withKey)
        }
    }
    
    func mapManager(_ manager: MapManager, hideGpsView isHidden: Bool){
        gpsView.isHidden = isHidden
    }
    
    func mapManager(_ manager: MapManager, updateCurrentAddressLabelWithText: String?) {
        
        //print("small label text: \(String(describing: updateCurrentAddressLabelWithText))")
        currentAddressLabel.text = updateCurrentAddressLabelWithText
            
    }
    
    
    func mapManager(_ manager: MapManager, hideCertainViews isHidden: Bool) {
        self.currentAddressSv.isHidden = isHidden
        guard let searchBarManager = self.searchBarManager else {
            return
        }
        searchBarManager.updateVisibitiy(isHidden: isHidden)
    }
    
    func mapManager(_ manager: MapManager, hideSuburbView isHidden: Bool) {
        self.currentAddressSv.isHidden = isHidden
    }
    
    
    func mapManagerShowOrbisLoader(isShow : Bool = true) {
        if isShow {
            self.showMapCenteredLoader()
        }else {
            self.hideOrbisLoader()
        }
    }

    // Map loader pinned to the SAME center as the crosshair (mapContainerView center). The generic
    // showOrbisLoader() offsets its centerY by half the safe-area inset, which left the lottie
    // floating below the crosshair. Same tag, so the existing hideOrbisLoader() paths remove it.
    private func showMapCenteredLoader() {
        view.hideOrbisLoader()
        let size = CGFloat(100).relativeToIphone8Width()
        let loader = UIUtil.getAppLoader(height: size, width: size)
        loader.tag = AppElementTags.appLoaderTag
        loader.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loader)
        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: mapContainerView.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: mapContainerView.centerYAnchor),
            loader.widthAnchor.constraint(equalToConstant: size),
            loader.heightAnchor.constraint(equalToConstant: size)
        ])
        view.bringSubviewToFront(loader)
        loader.play()
    }
    
    func isEnableMapDragging(isEnabled: Bool){
        self.mapManager.mapView?.isUserInteractionEnabled = isEnabled
        self.mapManager.mapView?.settings.scrollGestures = isEnabled
        self.mapManager.mapView?.settings.zoomGestures = isEnabled
        mapRightSlider.isUserInteractionEnabled = isEnabled
        mapLeftSlider.isUserInteractionEnabled = isEnabled
    }
    
    
    func mapManager(_ manager: MapManager, handleError error: any Error) {
        self.handleError(error: error)
    }
    
    
    func mapManager(_ manager: MapManager, didTap marker: GMSMarker) {
        if let searchBar = self.searchBarManager.searchBar {
            if !searchBar.isHidden {
                self.searchBarManager.searchBar.resignFirstResponder()
            }
        }

    }
    
    func mapManager(_ manager: MapManager, idleAt position: GMSCameraPosition) {

        if let searchBar = self.searchBarManager.searchBar {
            if !searchBar.isHidden {
                self.searchBarManager.searchBar.resignFirstResponder()
            }
        }
        
        if !panGestureManager.isDragging {
            panGestureManager.setCurrentZoom(zoom: position.zoom)
            panGestureManager.resetSliderToInitialPosition()
        }
        checkIfMapCenterIsNearTribe()
        
    }
    
    func mapManager(_ manager: MapManager, didTapAt coordinate: CLLocationCoordinate2D) {
        if let searchBar = self.searchBarManager.searchBar {
            if !searchBar.isHidden {
                self.searchBarManager.searchBar.resignFirstResponder()
            }
        }
    }
    
    func mapManager(_ manager: MapManager, didChange position: GMSCameraPosition) {
        
        if let searchBar = self.searchBarManager.searchBar {
            if !searchBar.isHidden {
                self.searchBarManager.searchBar.resignFirstResponder()
            }
        }
        
        self.searchBarManager?.searchBarView.isHidden = true
    }
    
    func mapManager(_ manager: MapManager, progress: Float){
        
        print("progress bar is updating: \(progress)")
        
        if ((self.mapUpdatingView?.isHidden) != nil) {
            self.mapUpdatingView?.isHidden = false
            self.mapUpdatingView?.setAlphaForSubTitleLabel(alpha: 0.0)
            self.mapUpdatingView?.progressBar(progress: 0.0)
            //return
        }
        
        
        print("progress bar is updating: \(progress)")
        self.mapUpdatingView?.progressBar(progress: Float(progress/100))
        
        if progress >= 85/100 && progress < 100/100 {
            //UIView.animate(withDuration: 0.25) { [weak self] in
            self.mapUpdatingView?.setAlphaForSubTitleLabel(alpha: 1.0)
            //}
        }
       
    }
    
    func mapManager(_ manager: MapManager, ishidden: Bool){
        if (ishidden) {
            mapUpdatingView?.progressBar(progress: 0.0)
            mapUpdatingView?.setAlphaForSubTitleLabel(alpha: 0.0)
        }
        mapUpdatingView?.isHidden = ishidden
    }
    
    func mapManager(_ manager: MapManager, didFindNearbyTribe place: PolygonPlaceDetails) {
        showNearbyTribePopup(place: place)
    }

    func mapManagerDidMoveAwayFromNearbyTribe(_ manager: MapManager) {
        hideNearbyTribePopup()
    }

    func mapManager(_ manager: MapManager, didTapNearbyTribePopup place: PolygonPlaceDetails) {
        if let group = place.toOrbisPlace().placeDominantGroup {
            gotoGroupDetailView(withModel: group)
        }
    }
    
//    func mapManager(_ manager: MapManager, didUpdateVisibleTribes places: [PolygonPlaceDetails]) {
//        let hasTribes = !places.isEmpty
//        communitiesExpandView.isHidden = !hasTribes
//        expandButtonView.isHidden = !hasTribes
//        expandButton.isHidden = !hasTribes
//    }

//    func mapManager(_ manager: MapManager, didUpdateVisibleTribes places: [PolygonPlaceDetails]) {
//        let hasTribes = !places.isEmpty
//        communitiesExpandView.isHidden = !hasTribes
//        expandButtonView.isHidden = !hasTribes
//        expandButton.isHidden = !hasTribes
//        nearbyTribePlaces = places
//        showDefaultNearestTribePopupIfNeeded(from: places)
//    }
    
    func mapManager(_ manager: MapManager, didUpdateVisibleTribes places: [PolygonPlaceDetails]) {
        // Same rule as updateNearbyCommunitiesVisibility: the "^" expand affordances stay hidden
        // during territory focus mode, even when tribe data refreshes mid-focus.
        let hidden = places.isEmpty || manager.isGroundOverlayClicked2
        communitiesExpandView.isHidden = hidden
        expandButtonView.isHidden = hidden
        expandButton.isHidden = hidden

        nearbyTribePlaces = places

        showDefaultNearestTribePopupIfNeeded(from: places)
        autoOpenNearbyCommunitiesSheetIfNeeded(with: places)
    }
}

extension HomeMapViewController{
    private func showNearbyTribePopup(place: PolygonPlaceDetails) {

        print("showing tribe for the place \(place)")

        let placeKey = place.placeKey ?? UUID().uuidString

        if nearbyTribePopupPlaceKey == placeKey {
            return
        }

        // Sequence-guarded create. The old shape (create inside the hide's fade completion) raced:
        // two overlapping shows meant the FIRST fade's completion created its card AFTER the second
        // show had already created one — the ref got overwritten and the earlier marker was orphaned
        // on the map forever (the duplicate floating cards during fast navigation).
        let hadPopup = nearbyTribePopupView != nil
        hideNearbyTribePopup()                     // bumps nearbyPopupRequestSeq
        let seq = nearbyPopupRequestSeq
        let delay: TimeInterval = hadPopup ? 0.18 : 0   // let the old card's fade read as a swap
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.nearbyPopupRequestSeq == seq else { return }   // superseded
            self.createNearbyTribePopup(place: place)
        }
    }

    private func hideNearbyTribePopup() {
        nearbyPopupRequestSeq += 1   // any pending create is now stale
        guard let popup = nearbyTribePopupView, let marker = nearbyTribePopupMarker else { return }
        // Clear the identity refs SYNCHRONOUSLY (before the async fade) so overlapping hide/create
        // calls during a pan can't stack on the same marker or nil a newer one. Only clear the
        // manager's weak marker ref if it still points at THIS marker (=== identity), so a stale
        // hide can't orphan a newer card's tap routing.
        nearbyTribePopupView = nil
        nearbyTribePopupMarker = nil
        nearbyTribePopupPlaceKey = nil
        if mapManager.nearbyPopupMarker === marker {
            mapManager.nearbyPopupMarker = nil
        }
        UIView.animate(withDuration: 0.18, animations: {
            popup.alpha = 0
        }, completion: { _ in
            marker.map = nil
        })
    }
    
    
    
    private func createNearbyTribePopup(place: PolygonPlaceDetails) {
        guard let mapView = mapManager.mapView,
              let anchor = popupAnchorCoordinate(for: place) else { return }

        // Hard invariant: at most one live popup marker. If a ref somehow survives (any future
        // race), remove it from the map before creating the replacement.
        if let stale = nearbyTribePopupMarker {
            stale.map = nil
        }

        let popup = NearbyTribePopupView.loadFromNib()
        // Render the full card from local place data immediately (name/description/count/border are
        // all in place.dominantGroup); the fetch below only refreshes and adds member avatars.
        popup.configure(place: place)
        popup.frame = CGRect(x: 0, y: 0, width: 250, height: 160)
        popup.layoutIfNeeded()

        popup.onTap = { [weak self] in
            guard let self else { return }
            if let group = place.toOrbisPlace().placeDominantGroup {
                self.gotoGroupDetailView(withModel: group)
            }
        }

        let marker = GMSMarker()
        marker.position = anchor
        marker.iconView = popup
        marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)
        marker.zIndex = 1100
        marker.tracksViewChanges = true
        marker.userData = place
        marker.map = mapView

        nearbyTribePopupMarker = marker
        nearbyTribePopupView = popup
        nearbyTribePopupPlaceKey = place.placeKey
        mapManager.nearbyPopupMarker = marker

        popup.alpha = 0
        UIView.animate(withDuration: 0.22) { popup.alpha = 1 }

        guard let groupKey = place.dominantGroup?.groupKey else {
            popup.configure(place: place)
            return
        }

        // Bind the fetch completion to THIS marker/popup, not the shared closest-tribe key. Android
        // routes resolved data back by groupKey and always configures its own popup; the previous
        // `nearbyTribePopupPlaceKey == currentPlaceKey` guard dropped the completion whenever a pan
        // made another tribe closest, leaving this card stuck on "Loading" forever. Now it drops only
        // if this exact marker was already removed from the map (superseded), never on closest-change.
        //
        // Do NOT freeze tracksViewChanges. It was set true at creation and stays true for the
        // popup's lifetime, so every async member avatar rasterizes into the card as it decodes —
        // a static (non-panning) GMSMapView does NOT re-snapshot a frozen iconView, which is why
        // late/slow avatars showed only partially. GMS stops tracking automatically when the
        // marker leaves the map (hide sets marker.map = nil).
        fetchNearbyPopupData(groupKey: groupKey, place: place, popup: popup, marker: marker, allowRetry: true)
    }

    // One transient network failure while panning used to blank the member avatars permanently
    // (no retry until another tribe became closest). Retry once while this exact card is on screen.
    private func fetchNearbyPopupData(groupKey: String,
                                      place: PolygonPlaceDetails,
                                      popup: NearbyTribePopupView,
                                      marker: GMSMarker,
                                      allowRetry: Bool) {
        nearbyPopupViewModel.fetchPopupData(groupKey: groupKey, fallbackGroup: place.dominantGroup?.toGroup()) { [weak self, weak popup, weak marker] result in
            guard let self, let popup, let marker, marker.map != nil else { return }
            switch result {
            case .success(let data):
                popup.configure(data: data)
            case .failure:
                popup.configure(place: place)
                guard allowRetry else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self, weak popup, weak marker] in
                    guard let self, let popup, let marker, marker.map != nil else { return }
                    self.fetchNearbyPopupData(groupKey: groupKey, place: place, popup: popup, marker: marker, allowRetry: false)
                }
            }
        }
    }

    // Northernmost polygon point (top of circle), nudged slightly south — mirrors Android renderAndPlace.
    private func popupAnchorCoordinate(for place: PolygonPlaceDetails) -> CLLocationCoordinate2D? {
        if let pts = place.polygonPoints, !pts.isEmpty,
           let top = pts.max(by: { ($0.latitude ?? -90) < ($1.latitude ?? -90) }),
           let lat = top.latitude, let lon = top.longitude {
            let offsetDeg = ((place.size ?? 0) / 111_000.0) * 0.1
            return CLLocationCoordinate2D(latitude: lat - offsetDeg, longitude: lon)
        }
        if let c = place.polygonCenter, let lat = c.latitude, let lon = c.longitude {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        if let c = place.coordinates, let lat = c.latitude, let lon = c.longitude {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return nil
    }
}


//MARK: SearchBarManager Delegate
extension HomeMapViewController:SearchBarManagerDelegate {
    
//    func didSelectCity(_ city: City) {
//        hasShownDefaultNearestTribePopup = true
//        
//        self.currentAddressContainer.isHidden = false
//        self.isLocationPermissionDenied = false
//        mapManager.updateMapInteractionSettings()
//
//        let cityCoordinate = CLLocationCoordinate2D(
//            latitude: Double(city.lat) ?? 0.0,
//            longitude: Double(city.lng) ?? 0.0
//        )
//
//        mapManager.onCitySelected(cityName: city.name, loc: cityCoordinate)
//        updateCenterPlusVisibility()
//    }
    
    func didSelectCity(_ city: City) {

        hasShownDefaultNearestTribePopup = true

        hideNearbyTribePopup()
        mapManager.clearNearbyTribeKey()   // VC-initiated hide — see didUpdateLocation

        self.currentAddressContainer.isHidden = false
        self.isLocationPermissionDenied = false
        mapManager.updateMapInteractionSettings()

        let cityCoordinate = CLLocationCoordinate2D(
            latitude: Double(city.lat) ?? 0.0,
            longitude: Double(city.lng) ?? 0.0
        )

        mapManager.onCitySelected(cityName: city.name, loc: cityCoordinate)

        updateCenterPlusVisibility()
    }
    
    func updateTextOnSearchBar(_ locationName: String?){
        self.mapManager.lastCitySelected = locationName ?? ""
        self.searchBarManager.updateText(withText: locationName)

    }
    
    func mapManager(_ manager: MapManager, showOnlySearchBar show: Bool) {
        
        
        
        self.searchBarManager.searchBar.isHidden = show
    }

}

//MARK: CarouselController

extension HomeMapViewController {
    
    private func setupCarouselController() {
        
        let calculatedHeight : CGFloat =  100
        carouselController = CarouselViewController(withCardData: [])
        //carouselController.view.backgroundColor = .red

        carouselController.onCellVisibility_ChangeFocusedPlace = { [weak self] index, polygonPlaceDetails in
            self?.mapManager.placeViewModel.changeFocusedPlace(position: index)
        }
        
        carouselController.onCellSelected = { [weak self] polygonplacedetails in
            
            //MARK: get current polygonplacedetails location
            let watchingLocation = CLLocation(
                latitude: (polygonplacedetails.coordinates?.latitude)!,
                longitude: (polygonplacedetails.coordinates?.longitude)!
            )
            Constants.location = watchingLocation
            
            self?.gotoPlaceDetailView(viewModel: PlaceDetailViewModel(place: polygonplacedetails.toOrbisPlace()))
        }
        // Set this callback to update the parent view height
        carouselController.onMaxHeightCellBack = { [weak self] cellHeight in
            self?.heightConstraintOfCarousel.constant = cellHeight
            UIView.animate(withDuration: 0.2) {
                self?.view.layoutIfNeeded()
            }
        }
        
        addChild(carouselController)
        view.addSubview(carouselController.view)
        carouselController.view.isHidden = true
        
        carouselController.didMove(toParent: self)
        carouselController.view.translatesAutoresizingMaskIntoConstraints = false
        
        heightConstraintOfCarousel =  carouselController.view.heightAnchor.constraint(equalToConstant: calculatedHeight)
        
        NSLayoutConstraint.activate([
            carouselController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            carouselController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            carouselController.view.bottomAnchor.constraint(equalTo: bottomSv.topAnchor, constant: -2),
            heightConstraintOfCarousel
        ])
    }
    
    private func populateCarouselWithData(withCardData: [PolygonPlaceDetails]) {
        carouselController.populateWithData(withCardData: withCardData)
    }
    
    func isShow_OR_Hide_Carousel(isVisible: Bool) {
            if isVisible, presentedViewController is NearbyCommunitiesSheetViewController {
                presentedViewController?.dismiss(animated: true)
            }
            carouselController.view.isHidden = !isVisible
            customButton.isHidden = !isVisible
            focusBackButton?.isHidden = !isVisible

            if !isVisible {
                carouselController.scrollToIndex(0)
            }

            searchBarManager.updateVisibitiy(isHidden: isVisible)

            // Focus mode owns the bottom of the screen: hide the nearby-tribes "^" expand affordances
            // while the carousel is up, restore them (tribe-count permitting) on focus exit. Note:
            // on exit this runs BEFORE isGroundOverlayClicked2 flips false, so decide from isVisible.
            let hideExpand = isVisible || mapManager.getAllVisibleTribes().isEmpty
            communitiesExpandView.isHidden = hideExpand
            expandButtonView.isHidden = hideExpand
            expandButton.isHidden = hideExpand

            self.view.bringSubviewToFront(customButton)
        }

    @objc private func onFocusBackTapped() {
        mapManager.exitFocusMode()
    }

    func update_Carousel_DataSet(places: [PolygonPlaceDetails]) {
        
        print("inside")
        nearbyTribePlaces = places

        carouselController.populateWithData(withCardData: places)
        self.mapManager.placeViewModel.changeFocusedPlace(position: 0)
        
    }
    
    
    func selectedPlaceToScrollCarousel(place : PolygonPlaceDetails) {

        if let index = self.mapManager.placeViewModel.polygonFocusedPlaces.firstIndex(where: { $0.placeKey == place.placeKey }) {
            
            //print("place.placeKey === \(place.placeKey)")
            carouselController.scrollToIndex(index)
            //
                        
        }
        
    }
    
    func selectedGroupMainPolyGone(place: PolygonPlaceDetails) {
        customButton.updateContent(place: place)
    }
    
    func carouselScrollToIndex(indexOf: Int) {
        
    }

    
    private func setupTopCustomRoundButton() {

        // Empty seed — updateContent(place:) fills title+icon on focus enter. (Was seeded with
        // sample data "Clube do Picnic" + a double force-unwrap that leaked when a tribe had no name.)
        customButton = CustomRoundedButton(icon: nil, title: "")
        customButton.translatesAutoresizingMaskIntoConstraints = false
        customButton.isHidden = true
        customButton.layer.shadowColor = UIColor.black.cgColor
        customButton.layer.shadowOpacity = 0.2
        customButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        customButton.layer.shadowRadius = 5
        customButton.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        customButton.layer.borderWidth = 1
        customButton.backgroundColor = .white

        focusBackButton = UIButton(type: .system)
        focusBackButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        focusBackButton.tintColor = .darkGray
        focusBackButton.backgroundColor = .white
        focusBackButton.layer.cornerRadius = 20
        focusBackButton.layer.shadowColor = UIColor.black.cgColor
        focusBackButton.layer.shadowOpacity = 0.2
        focusBackButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        focusBackButton.layer.shadowRadius = 5
        focusBackButton.translatesAutoresizingMaskIntoConstraints = false
        focusBackButton.isHidden = true

        view.addSubview(focusBackButton)
        view.addSubview(customButton)

        NSLayoutConstraint.activate([
            focusBackButton.centerYAnchor.constraint(equalTo: customButton.centerYAnchor),
            focusBackButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            focusBackButton.widthAnchor.constraint(equalToConstant: 40),
            focusBackButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        let customCenterX = customButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        customCenterX.priority = .defaultHigh
        NSLayoutConstraint.activate([
            customButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 75),
            customCenterX,
            customButton.leadingAnchor.constraint(greaterThanOrEqualTo: focusBackButton.trailingAnchor, constant: 12),
            customButton.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        focusBackButton.addTarget(self, action: #selector(onFocusBackTapped), for: .touchUpInside)

        // Set the callback action
        customButton.onTap { [weak self] place in
            print("Button tapped!")
            
            guard let self = self else {return}
            
            let place = place?.toOrbisPlace()
            guard let place = place, let group = place.placeDominantGroup else { return }
            self.gotoGroupDetailView(withModel: group)
        }

    }
}
