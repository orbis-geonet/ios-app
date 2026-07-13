//
//  CreatePlaceSelectLocationVC.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 04/04/2021.
//

import UIKit
import HWPanModal
import GoogleMaps

class CreatePlaceSelectLocationVC: OrbisLocalizableViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var placeAddressTextField: UITextField!
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var markerIconView: UIImageView!
    @IBOutlet weak var createBtn: UIButton!
    
    
    @IBAction func backTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func createTapped(_ sender: Any) {
        tryCreatePlace()
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
        let convertedMapFrame = mapContainerView.convert(mapContainerView.bounds, to: self.view)
        if convertedMapFrame.contains(panGesturePoint) {
            return false
        }
        return true
    }

    let cameraZoom: Float = kGMSMaxZoomLevel
    var mapView: GMSMapView!
    var viewModel: CreatePlaceViewModel!
    var hasMapInitialized = false
    //var onCreateSuccess: ((OrbisPlace) -> Void)? Original code
    var onCreateSuccess: ((PlaceDetails) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeMapView()
        resetMapView()
        updateStaticTexts()
    }
    
    override func updateStaticTexts() {
        titleLabel.text = AppStrings.Places.createPlaceTitle
        placeAddressTextField.placeholder =  AppStrings.Places.exactAddressPlaceholder
        createBtn.setTitle(AppStrings.Places.createPlaceBtnText, for: .normal)
    }
    
    private func initializeMapView() {
        mapView = getMapCenteredToPlaceLocation()
        mapView.isHidden = true
        mapView.delegate = self
        mapContainerView.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.trailingAnchor.constraint(equalTo: mapContainerView.trailingAnchor).isActive = true
        mapView.leadingAnchor.constraint(equalTo: mapContainerView.leadingAnchor).isActive = true
        mapView.topAnchor.constraint(equalTo: mapContainerView.topAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: mapContainerView.bottomAnchor).isActive = true
        
        markerIconView.image = viewModel.placeTypeImage
        
        placeAddressTextField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
    }

    // MARK:- Map methods
    
    private func getMapCenteredToPlaceLocation() -> GMSMapView {
        
        let mlastlocation = Constants.location ?? CLLocation(latitude: 0.0, longitude: 0.0)
        
        viewModel.placeLocation = mlastlocation.coordinate
//        let coordinates = UserSessionManager.shared.userCurrentLocation ?? CLLocationCoordinate2D(latitude: BrazilCoordinate.latitude, longitude: BrazilCoordinate.longitude)
        
        let coordinates = mlastlocation.coordinate
        
        let camera = GMSCameraPosition.camera(withLatitude: coordinates.latitude, longitude: coordinates.longitude, zoom: cameraZoom)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.frame = mapContainerView.bounds
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.rotateGestures = false
        mapView.settings.tiltGestures = false
        return mapView
    }
    
    private func resetMapView() {
        guard mapView != nil else {return}
        mapView.clear()
    }
    
    fileprivate func setMapCameraToCoordincate(loc: CLLocationCoordinate2D) {
        let mlastlocation = Constants.location ?? CLLocation(latitude: 0.0, longitude: 0.0)
        let camera = GMSCameraPosition.camera(withTarget: mlastlocation.coordinate, zoom: self.cameraZoom)
        self.mapView.camera = camera
    }
    
    private func tryCreatePlace() {
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.tryCreatePlace { [weak self] data, err in
//            if var place = data as? OrbisPlace { original code
            if var place = data as? PlaceDetails {
//                if place.dominantGroup == nil && place.competingGroups == nil { original code
                if place.dominantGroup == nil && place.competingGroups == nil {
                    place.dominantGroup = self?.viewModel.model.groupPublisher?.toGroupDetails()
                    place.competingGroups = (self?.viewModel.model.groupPublisher == nil) ? [] : [self!.viewModel.model.groupPublisher!.toGroupDetails()]
                }
                self?.dismissWithSuccess(place: place)
            }
            else {
                self?.handleError(error: err ?? ResponseError.requestFailed)
            }
            self?.hideOrbisLoader()
        }
    }
    
    private func dismissWithSuccess(place: PlaceDetails) {
        var placeWithGroup = place
        placeWithGroup.dominantGroup = viewModel.groupPublisher?.toGroupDetails()
        self.dismiss(animated: true) {
            [weak self] in
            self?.onCreateSuccess?(place)
        }
    }
    
    // MARK:- Text Field Delegate methods
    
    @objc private func textDidChange(_ textField: UITextField) {
        viewModel.address = textField.text ?? ""
    }
}

extension CreatePlaceSelectLocationVC: GMSMapViewDelegate {
    
    func mapViewSnapshotReady(_ mapView: GMSMapView) {
        guard !hasMapInitialized else { return }
        mapView.isHidden = false
        hasMapInitialized = true
        setMapCameraToCoordincate(loc: UserSessionManager.shared.userCurrentLocation!)
    }
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        viewModel.placeLocation = position.target
    }
}
