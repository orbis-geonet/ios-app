//
//  PlaceHeaderTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 03/04/2021.
//

import UIKit
import GoogleMaps
import Cosmos

protocol OrbisViewHeaderContentChangeDelegate: AnyObject {
    func pictureViewTapped(view: UIView)
    func descriptionTapped(view: UIView)
    func followUnfollowTapped(imageView: UIImageView)
}

class PlaceHeaderTableViewCell: UITableViewCell {
    @IBOutlet weak var placeMapContainer: UIView!
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var placeDescriptionLabel: OrbisExpandableLabel!
    @IBOutlet weak var placeFollowingIndicatorView: UIImageView!
    @IBOutlet weak var starRatingView: CosmosView!
    @IBOutlet weak var averageRatingLabel: UILabel!
    @IBOutlet weak var totalReviewsLabel: UILabel!
    @IBOutlet weak var placeAddressSv: UIStackView!
    @IBOutlet weak var placeAddressLabel: UILabel!
    @IBOutlet weak var placeTelephoneSv: UIStackView!
    @IBOutlet weak var placeTelephoneLabel: UILabel!
    @IBOutlet weak var placeScheduleSv: UIStackView!
    @IBOutlet weak var placeScheduleLabel: UILabel!
    @IBOutlet weak var placeWebsiteSv: UIStackView!
    @IBOutlet weak var placeWebsiteLabel: UILabel!
    
    @IBAction func moreTapped(_ sender: Any) {
        onMoreTapped?()
    }
    
    let cameraZoom: Float = 15
    var mapView: GMSMapView!
    var headerContentChangeDelegate: OrbisViewHeaderContentChangeDelegate?
    var onMoreTapped: (() -> Void)?
    var onReviewTapped: (() -> Void)?
    var onAddressSvTapped: (() -> Void)?
    var onTelephoneSvTapped: (() -> Void)?
    var onScheduleSvTapped: (() -> Void)?
    var onWebsiteSvTapped: (() -> Void)?
    
    var viewModel: PlaceHeaderCellViewModel! {
        didSet {
            updateViewContent()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupStarRating()
        setupActionStackViews()
        addLanguageUpdateObserver()
        updateStaticTexts()
        initializeMapView()
        
        let descriptionTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(descriptionDidTap(_:)))
        placeDescriptionLabel.isUserInteractionEnabled = true
        placeDescriptionLabel.addGestureRecognizer(descriptionTapGesture)
        
        let followingIndicatorTapGesture = UITapGestureRecognizer(target: self, action: #selector(placeFollowingIndicatorTapped(_:)))
        placeFollowingIndicatorView.isUserInteractionEnabled = true
        placeFollowingIndicatorView.addGestureRecognizer(followingIndicatorTapGesture)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func setupStarRating() {
        starRatingView.settings.updateOnTouch = false
        starRatingView.settings.fillMode = .precise
        starRatingView.settings.starSize = 20.toCGFloat.relativeToIphone8Width()
        starRatingView.settings.starMargin = 5.toCGFloat.relativeToIphone8Width()
        
        starRatingView.rating = 0
        averageRatingLabel.text = ""
        totalReviewsLabel.text = ""
        
        starRatingView.didTouchCosmos = {
            [weak self] _ in
            self?.onReviewTapped?()
        }
    }
    
    private func setupActionStackViews() {
        placeAddressSv.isUserInteractionEnabled = true
        let placeAddressTapGesture = UITapGestureRecognizer(target: self, action: #selector(placeAddressDidTap(_:)))
        placeAddressSv.addGestureRecognizer(placeAddressTapGesture)
        
        placeTelephoneSv.isUserInteractionEnabled = true
        let placeTelephoneTapGesture = UITapGestureRecognizer(target: self, action: #selector(placeTelephoneDidTap(_:)))
        placeTelephoneSv.addGestureRecognizer(placeTelephoneTapGesture)
        
        placeScheduleSv.isUserInteractionEnabled = true
        let placeScheduleTapGesture = UITapGestureRecognizer(target: self, action: #selector(placeScheduleDidTap(_:)))
        placeScheduleSv.addGestureRecognizer(placeScheduleTapGesture)
        
        placeWebsiteSv.isUserInteractionEnabled = true
        let placeWebsiteTapGesture = UITapGestureRecognizer(target: self, action: #selector(placeWebsiteDidTap(_:)))
        placeWebsiteSv.addGestureRecognizer(placeWebsiteTapGesture)
    }
    
    @objc private func placeAddressDidTap(_ gesture: UITapGestureRecognizer) {
        self.onAddressSvTapped?()
    }
    
    @objc private func placeTelephoneDidTap(_ gesture: UITapGestureRecognizer) {
        self.onTelephoneSvTapped?()
    }
    
    @objc private func placeScheduleDidTap(_ gesture: UITapGestureRecognizer) {
        self.onScheduleSvTapped?()
    }
    
    @objc private func placeWebsiteDidTap(_ gesture: UITapGestureRecognizer) {
        self.onWebsiteSvTapped?()
    }
    
    @objc private func descriptionDidTap(_ gesture: UITapGestureRecognizer) {
        headerContentChangeDelegate?.descriptionTapped(view: self.placeDescriptionLabel)
    }
    
    @objc private func placeFollowingIndicatorTapped(_ gesture: UITapGestureRecognizer) {
        headerContentChangeDelegate?.followUnfollowTapped(imageView: placeFollowingIndicatorView)
    }
    
    private func updateViewContent() {
        placeFollowingIndicatorView.tintColor = viewModel.isFollowing ? UIColor(named: AppColors.appLightGreen.rawValue) : UIColor(named: AppColors.appPinkishGray.rawValue)
        placeNameLabel.text = viewModel.name
        placeDescriptionLabel.text = viewModel.description
        placeDescriptionLabel.isHidden = viewModel.description.isEmpty
        updatePlaceRating()
        updateMapLocation()
    }
    
    private func updatePlaceRating() {
        starRatingView.rating = viewModel.starRating
        averageRatingLabel.text = viewModel.avgRating
        averageRatingLabel.isHidden = viewModel.avgRating.isEmpty
        totalReviewsLabel.text = viewModel.totalRatingCount
    }
    
    private func addLanguageUpdateObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateLanguage), name: NSNotification.Name(rawValue: AppNotificationKeys.userLanguageDidUpdate), object: nil)
    }
    
    @objc private func didUpdateLanguage(_ notification: NSNotification) {
        updateStaticTexts()
    }
    
    // MARK:- UI Initialization
    
    func updateStaticTexts() {
        placeAddressLabel.text = AppStrings.Places.placeAddressLabel
        placeTelephoneLabel.text = AppStrings.Places.placeTelephoneLabel
        placeScheduleLabel.text = AppStrings.Places.placeScheduleLabel
        placeWebsiteLabel.text = AppStrings.Places.placeWebsiteLabel
    }
    
    private func updateMapLocation() {
        resetMapView()
        guard let placeLat = viewModel.place.coordinates?.latitude, let placeLong = viewModel.place.coordinates?.longitude else { return }
        viewModel.addPlaceToMap(mapView: mapView, orbisPlace: viewModel.place)
        let location = CLLocationCoordinate2D(latitude: placeLat, longitude: placeLong)
        setMapCameraToCoordincate(loc: location)
    }
    
    private func initializeMapView() {
        mapView = getMapCenteredToPlaceLocation()
        mapView.isHidden = true
        mapView.delegate = self
        placeMapContainer.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.trailingAnchor.constraint(equalTo: placeMapContainer.trailingAnchor).isActive = true
        mapView.leadingAnchor.constraint(equalTo: placeMapContainer.leadingAnchor).isActive = true
        mapView.topAnchor.constraint(equalTo: placeMapContainer.topAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: placeMapContainer.bottomAnchor).isActive = true
    }

    // MARK:- Map methods
    
    private func getMapCenteredToPlaceLocation() -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: BrazilCoordinate.latitude, longitude: BrazilCoordinate.longitude, zoom: cameraZoom)
        
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        
        /*
        if let styleURL = Bundle.main.url(forResource: "google_map_style", withExtension: "json") {
            do {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } catch {
                NSLog("One or more of the map styles failed to load. \(error)")
            }
        } else {
            NSLog("Unable to find google map style json")
        }
        */
        
        
        if let styleURL = Bundle.main.url(forResource: "style_json", withExtension: "json") {
            do {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } catch {
                NSLog("One or more of the map styles failed to load. \(error)")
            }
        } else {
            NSLog("Unable to find google map style json")
        }
        
        
        mapView.frame = placeMapContainer.bounds
        mapView.settings.zoomGestures = false
        mapView.settings.scrollGestures = false
        mapView.settings.rotateGestures = false
        mapView.settings.tiltGestures = false
        return mapView
    }
    
    private func resetMapView() {
        guard mapView != nil else {return}
        mapView.clear()
    }
    
    fileprivate func setMapCameraToCoordincate(loc: CLLocationCoordinate2D) {
        let camera = GMSCameraPosition.camera(withTarget: loc, zoom: self.cameraZoom)
        self.mapView.camera = camera
    }
    
}

extension PlaceHeaderTableViewCell: GMSMapViewDelegate {
    
    func mapViewSnapshotReady(_ mapView: GMSMapView) {
        mapView.isHidden = false
    }
    
    func mapView(_ mapView: GMSMapView, didTap overlay: GMSOverlay) {
        headerContentChangeDelegate?.pictureViewTapped(view: self.contentView)
    }
}
