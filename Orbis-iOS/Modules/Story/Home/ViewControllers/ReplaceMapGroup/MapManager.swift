//
//  MapManager.swift
//  Orbis-iOS
//
//  Created by Kamran on 25/10/2024.
//


import GoogleMaps
import UIKit
import Combine
import FirebaseStorage
import SDWebImage


protocol MapManagerDelegate: AnyObject {
    func mapManager(_ manager: MapManager, didTap marker: GMSMarker)
    func mapManager(_ manager: MapManager, idleAt position: GMSCameraPosition)
    func mapManager(_ manager: MapManager, didTapAt coordinate: CLLocationCoordinate2D)
    func mapManager(_ manager: MapManager, didChange position: GMSCameraPosition)
    func mapManager(_ manager: MapManager, hideCertainViews isHidden: Bool)
    func mapManager(_ manager: MapManager, hideSuburbView isHidden: Bool)
    func mapManagerShowOrbisLoader(isShow: Bool)
    func mapManager(_ manager: MapManager, handleError error: Error)
    func mapManager(_ manager: MapManager, updateCurrentAddressLabelWithText: String?)
    func mapManager(_ manager: MapManager, hideGpsView isHidden: Bool)
    func mapManager(_ manager: MapManager, gotoView:Bool, withKey: String)
    func mapManager(_ manager: MapManager, showHide isHidden: Bool)
    func mapManager(_ manager: MapManager, showOnlySearchBar show: Bool)


    func updateTextOnSearchBar(_ locationName: String?)
    func isEnableMapDragging(isEnabled: Bool)
    
    func isShow_OR_Hide_Carousel(isVisible: Bool)
    func update_Carousel_DataSet(places: [PolygonPlaceDetails])
    func selectedPlaceToScrollCarousel(place: PolygonPlaceDetails)
    func selectedGroupMainPolyGone(place: PolygonPlaceDetails)
    func carouselScrollToIndex(indexOf: Int)
    func mapManager(_ manager: MapManager, progress: Float)
    func mapManager(_ manager: MapManager, ishidden: Bool)
    
    
    // to show and close nearby tribe popup.
    func mapManager(_ manager: MapManager, didFindNearbyTribe place: PolygonPlaceDetails)
    func mapManagerDidMoveAwayFromNearbyTribe(_ manager: MapManager)
    func mapManager(_ manager: MapManager, didUpdateVisibleTribes places: [PolygonPlaceDetails])
    func mapManager(_ manager: MapManager, didTapNearbyTribePopup place: PolygonPlaceDetails)

}

class MapManager: NSObject {
    
    weak var mapView: GMSMapView?
    private weak var mapContainerView: UIView?
    private let locationManager: LocationManager
    //private var viewModel:MapViewModel?
    private var cancellables = Set<AnyCancellable>()
    private let cameraZoom: Float
    private let minZoomForDataLoad: Float
    private var isLocationPermissionDenied: Bool {
            // "Location not granted" — true for denied, restricted, AND notDetermined
            // (a fresh, not-yet-asked launch). Android treats no-permission the same way
            // and falls back to New York; treating .notDetermined as granted is what left
            // iOS on the Google SDK default (San Francisco).
            let status = CLLocationManager.authorizationStatus()
            return status != .authorizedWhenInUse && status != .authorizedAlways
        }
    
    private var selectedMarkerInfoView: MapMarkerInfoView?
    private var isMarkerTapPerforming = false
    private let minZoomForTapAction: Float = AppValues.isCurrentDeviceOld ? 12 : 11
    private let minSelectedMarkerWidth: CGFloat = 60.toCGFloat.relativeToIphone8Width()
    var userCurrentLocation: CLLocation?
    
    weak var delegate: MapManagerDelegate?
    
    
    // MARK: Polygon variables
    var lastPlace: PolygonPlaceDetails! // Replace PolygonPlaceDetails with the appropriate type
    var lastPlaceCreatedKey: String = ""
    var lastOverlay: GMSGroundOverlay! // Replace GMSGroundOverlay with the appropriate type if using a different map library
    var lastZoomLevel: Double = 0.0
    var loadedOverlay = false

    private let MILLIS_IN_SECOND: Int64 = 1000
    private let SECONDS_IN_MINUTE: Int = 60
    private let MINUTES_IN_HOUR: Int = 60
    private let HOURS_IN_DAY: Int = 24
    private let DAYS_IN_YEAR: Float = 365.24 // More accurate representation of a year
    var timeDelayBoolForGroundOverlay = false


    lazy var MILLISECONDS_IN_DAY: Int64 = {
        return MILLIS_IN_SECOND * Int64(SECONDS_IN_MINUTE) * Int64(MINUTES_IN_HOUR) * Int64(HOURS_IN_DAY)
    }()

    let MILLISECONDS_IN_HOUR: Int64 = 3_600_000

    lazy var MILLISECONDS_IN_YEAR: Float = {
        return Float(MILLISECONDS_IN_DAY) * DAYS_IN_YEAR
    }()

    let defaultZoom: Float = 11.5//13.12

    private var allCities: [String: CLLocationCoordinate2D] = [:]
    let NewYork = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    private var sharedPreferences = UserDefaults.standard // Replace with appropriate UserDefaults usage
    private let FINE_LOCATION_CODE: Int = 1001
    private var locationListener: CLLocationManagerDelegate! // Replace with an appropriate delegate
   // private var mMap: GMSMapView? = nil // Replace GMSMapView with appropriate map view if necessary
    private var currentLeftProgress: Int = 0
    private var previousLeftProgress: Int = 0
    private var previousRightProgress: Int = 0
    private let middleOfProgress: Int = 100
    private var currentZoom: Float = 10.0
    private var zoomSensitive: Float = 0.03
    var mLastLocation: CLLocation? = nil
    var lastLocation: CLLocationCoordinate2D? = nil
    private var myLocationMarker: GMSMarker? = nil // Replace GMSMarker with appropriate marker if needed
    private var areLocationAllowedPermissions: Bool = false
    var placeSheetCheckIn: Bool = false
    var startedOnCity: Bool = true
    var isDrag: Bool = false
    private var fusedLocationClient: CLLocationManager! // Replace with an appropriate fused location client if needed
    private var checkLocationPermission: (() -> Void)? = nil // Replace with appropriate permission check handler
    var placeViewModel = PlaceViewModel() // Replace with the appropriate view model type
    var places: [PolygonPlaceDetails] = []
    private var polygonPlacesKeys: [String] = [] // Use for observational equality through changes
    var placeOverlays: [GMSGroundOverlay: PolygonPlaceDetails] = [:]
    var associatedOverlays: [GMSPolygon: GMSGroundOverlay] = [:]
    var associatedPolygons: [GMSGroundOverlay: GMSPolygon?] = [:]
    private var creationJobs = [Task<(), Never>]() // Equivalent to ArrayList<Job>

    // Perf S1 (off-main geometry). Main-confined; see OperationViking_Perf5_S1_SPEC.md §4.2.
    private var currentGeneration: UInt64 = 0     // idle-sweep epoch, bumped per sweep + on teardown
    private var idleTask: Task<Void, Never>?      // the single owning task for the current S1 idle sweep
    var focusPolygonMarkers: [GMSMarker: PolygonPlaceDetails] = [:]
    weak var nearbyPopupMarker: GMSMarker?
    var pendingPlaces: [String: PolygonPlaceDetails] = [:]
    var isGeoObserving: Bool = false
    var checkInCompleted: Bool = false
    var cityRecentlyChanged: Bool = false
    var polygonFocusingFirstTime: Bool = true
    var mapPage: Int = 0
    var lastCitySelected = ""
    private var fabClicked = false
    var pendingRegionChange: CLLocationCoordinate2D? = nil
    private var willBePlaceOverLays: [PolygonPlaceDetails] = []
    private var lastOverlayUpdatedTime: Int = 0
    var isGroundOverlayClicked = false
    var isGroundOverlayClicked2 = false
    var circle: GMSCircle? = nil
    var bindingloading: Bool = false
    
    static var testingInt : Int = 0
    var testingPlaceKey : String? = nil
    var date1: Date? = nil
    private var isFocusCirclecalled = false
    private var savedMinZoom: Float = kGMSMinZoomLevel
    private var savedMaxZoom: Float = kGMSMaxZoomLevel
    
    
    private let nearbyTribeDistanceMeters: CLLocationDistance = 1000
    private var nearbyTribeCheckWorkItem: DispatchWorkItem?
    private var lastNearbyTribeKey: String?

    // Focus-mode camera lock: the exact entry camera (offset target + entry zoom) the camera must
    // snap back to when the user pans away and releases (Android lock-view parity).
    private var focusLockCameraPosition: GMSCameraPosition?

    // Loader counter: number of territory image/attach loads in flight. Drives the lottie loader —
    // show while a territory that came into view is still loading, hide when the last one settles.
    private var inFlightOverlayLoads = 0
    private var loaderShowWorkItem: DispatchWorkItem?
    private var loaderHideWorkItem: DispatchWorkItem?

    // Throttle for the pan-driven sweep (loads territories WHILE panning, not only on idle).
    private var lastPanSweepTime: CFTimeInterval = 0

    // Region-fetch policy. The server returns territories within REGION_FETCH_RADIUS_KM of the
    // requested point (PlaceRepositories passes distance: 25). A refetch must fire BEFORE the
    // viewport edge leaves that disc — the old fixed 24.5km trigger let the leading screen edge
    // run up to ~17km past the data boundary at default zoom (empty band until the user paused).
    private let regionFetchRadiusKm: Double = 25
    private var lastRegionFetchTime: CFTimeInterval = 0

    // Territories animate their entrance ONCE per session. Re-creations (pan away and back) attach
    // at full size instantly — replaying the grow-from-zero timer on every viewport re-entry both
    // looked broken and left half-grown bounds when a sweep removed the overlay mid-animation.
    private var animatedPlaceKeys = Set<String>()
    
    private let placesAccessQueue = DispatchQueue(label: "com.orbis.placesAccessQueue")
    
    deinit {
        
    }
    
    init(mapContainerView: UIView, locationManager: LocationManager, cameraZoom: Float, minZoomForDataLoad: Float) {
        self.mapContainerView = mapContainerView
        self.locationManager = locationManager
        self.cameraZoom = cameraZoom
        self.minZoomForDataLoad = minZoomForDataLoad
        super.init()
        setupMapView()
    }
    


    func isCitySaved() -> Bool {
        let savedCityLat = sharedPreferences.float(forKey: "selected_city_latitude")
        let savedCityLon = sharedPreferences.float(forKey: "selected_city_longitude")
        let isSavedCity = savedCityLat != 0 && savedCityLon != 0
        return isSavedCity
    }
    
    private func setupMapView() {
        
        guard let mapContainerView = mapContainerView else { return }
        
        placeViewModelListener()
        
        // Determine the camera position based on location permission status
        var coordinatesToUse: GMSCameraPosition?
        let defaultCameraZoom: Float = AppValues.isCurrentDeviceOld ? 11.5 : 11.5
        
        let savedCityLat = sharedPreferences.float(forKey: "selected_city_latitude")
        let savedCityLon = sharedPreferences.float(forKey: "selected_city_longitude")
        let isSavedCity = savedCityLat != 0 && savedCityLon != 0

        var isCenteredMap = false
        placeViewModel.locationSharedOrSelected = isSavedCity
        
        if self.isLocationPermissionDenied {
            // Center on New York if location permission is denied and no save city else move to saveCity
            if isSavedCity {
                print("Why this happend...................")
                print("savedCityLat = \(savedCityLat)")
                print("savedCityLon = \(savedCityLon)")
                print("isSavedCity = \(isSavedCity)")


                let savedCityLocation = CLLocationCoordinate2D(latitude: Double(savedCityLat), longitude: Double(savedCityLon))
                
                coordinatesToUse = GMSCameraPosition.camera(withLatitude: savedCityLocation.latitude, longitude: savedCityLocation.longitude, zoom: defaultCameraZoom)
                placeViewModel.locationSharedOrSelected = true
                placeViewModel.setLastCitySelected(loc: savedCityLocation)
            } else {
                
                startedOnCity = true
                
                coordinatesToUse = GMSCameraPosition.camera(withLatitude: NewYorkCoordinates.latitude, longitude: NewYorkCoordinates.longitude, zoom: defaultCameraZoom)
                
                
                mapView = GMSMapView.map(withFrame: CGRect.zero, camera: coordinatesToUse!)
               
                if !loadedOverlay {
                    bindingloading = true
                    delegate?.mapManagerShowOrbisLoader(isShow: true)
                    placeViewModel.findPolygonPlacesForMap(latitude: NewYorkCoordinates.latitude, longitude: NewYorkCoordinates.longitude)
                }
            }
            
        }
        else {
            areLocationAllowedPermissions = true
            placeViewModel.locationSharedOrSelected = true
            // Center on user location if location permission is granted and no savedCity is there
            if isSavedCity {
                let savedCityLocation = CLLocationCoordinate2D(latitude: Double(savedCityLat), longitude: Double(savedCityLon))
                coordinatesToUse = GMSCameraPosition.camera(withLatitude: savedCityLocation.latitude, longitude: savedCityLocation.longitude, zoom: defaultCameraZoom)
                isCenteredMap = true
                startedOnCity = true
    
            } else {
                //for user location data
            }
            
        }
        
        // Initialize the map view with the chosen camera position
        var mapView: GMSMapView!
        
        if (coordinatesToUse == nil){
            // Never construct GMSMapView() without a camera — it yields the Google SDK
            // default (San Francisco). Fall back to New York, matching Android.
            let newYork = GMSCameraPosition.camera(withLatitude: NewYorkCoordinates.latitude,
                                                   longitude: NewYorkCoordinates.longitude,
                                                   zoom: defaultCameraZoom)
            mapView = GMSMapView.map(withFrame: .zero, camera: newYork)
        }
        else if isCenteredMap{
            // Start on the saved-city camera rather than a camera-less GMSMapView()
            // (which would flash San Francisco before the delayed recenter below).
            let savedCamera = GMSCameraPosition.camera(withLatitude: Double(savedCityLat),
                                                       longitude: Double(savedCityLon),
                                                       zoom: defaultCameraZoom)
            mapView = GMSMapView.map(withFrame: .zero, camera: savedCamera)

            let customLocation = CLLocation(latitude: Double(savedCityLat), longitude: Double(savedCityLon))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return } // Safeguard against deallocation
                self.centerMapOnLocation(location: customLocation, title: "", displayMarker: false)
            }
            
        }
        else{
            mapView = GMSMapView.map(withFrame: CGRect.zero, camera: coordinatesToUse!)
        }
    
        mapView.delegate = self
        // Apply custom style if available
        
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
        
        
        // Add mapView to the container view
        mapContainerView.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: mapContainerView.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: mapContainerView.trailingAnchor),
            mapView.topAnchor.constraint(equalTo: mapContainerView.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: mapContainerView.bottomAnchor)
        ])
        self.mapView = mapView
    }
    
    func getAllVisibleTribes() -> [PolygonPlaceDetails] {
        return placesAccessQueue.sync { places }   // S0: guarded read of the shared array
    }

    // The VC hides the nearby popup on its own for non-map reasons (location fix, city pick). Without
    // resetting this key the manager still believes the popup for that tribe is showing and never
    // re-emits didFindNearbyTribe for it — the popup stays gone until another tribe becomes closest.
    func clearNearbyTribeKey() {
        lastNearbyTribeKey = nil
    }

    // MARK: - Territory-load loader (lottie) counter. Main-thread only (all attach paths are main).

    private func overlayLoadDidStart() {
        inFlightOverlayLoads += 1
        loaderHideWorkItem?.cancel()
        loaderHideWorkItem = nil
        guard inFlightOverlayLoads == 1, loaderShowWorkItem == nil else { return }
        // Grace delay: cache-hit loads settle within a frame or two — don't flash the loader for them.
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.loaderShowWorkItem = nil
            guard self.inFlightOverlayLoads > 0 else { return }
            self.delegate?.mapManagerShowOrbisLoader(isShow: true)
        }
        loaderShowWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: work)
    }

    private func overlayLoadDidFinish() {
        inFlightOverlayLoads = max(0, inFlightOverlayLoads - 1)
        guard inFlightOverlayLoads == 0 else { return }
        loaderShowWorkItem?.cancel()
        loaderShowWorkItem = nil
        loaderHideWorkItem?.cancel()
        // Small trailing delay so back-to-back loads in one sweep don't strobe the loader.
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.inFlightOverlayLoads == 0 else { return }
            self.bindingloading = false
            self.delegate?.mapManagerShowOrbisLoader(isShow: false)
        }
        loaderHideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }

    // True exactly once per placeKey per session; callers animate on true, attach statically on false.
    private func markAnimatedIfFirstAppearance(placeKey: String?) -> Bool {
        guard let key = placeKey, !key.isEmpty else { return true }
        if animatedPlaceKeys.contains(key) { return false }
        animatedPlaceKeys.insert(key)
        return true
    }

    // Territories should START loading while the user is still panning (the idle sweep alone only
    // fires after the gesture ends). Throttled so a continuous pan re-sweeps ~3x/second. S1-only:
    // the S0 fallback smooths polygons on the main thread and would jank the gesture.
    private func schedulePanDrivenSweep() {
        guard AppValues.offMainGeometryEnabled else { return }
        let now = CACurrentMediaTime()
        guard now - lastPanSweepTime > 0.35 else { return }
        lastPanSweepTime = now
        updateGroundOverlayInBounds()
        maybeFetchRegionForCamera()   // long flings cross the data boundary mid-gesture
    }

    // Refetch when the camera has moved far enough from the last fetch center that the viewport
    // is approaching the edge of the fetched 25km disc. Threshold adapts to zoom: fetch radius
    // minus the visible half-diagonal, floored at 3km. Time-throttled (3s) instead of an
    // in-flight flag so a failed request self-heals on the next movement.
    func maybeFetchRegionForCamera() {
        guard let mapView = mapView, !isGroundOverlayClicked2 else { return }
        let now = CACurrentMediaTime()
        guard now - lastRegionFetchTime > 3 else { return }

        let target = mapView.camera.target
        let movedKm = Double(distance(latLng: target)) / 1000

        let region = mapView.projection.visibleRegion()
        let halfDiagonalKm = GMSGeometryDistance(region.farLeft, region.nearRight) / 2000
        let thresholdKm = max(3, regionFetchRadiusKm - halfDiagonalKm)

        guard movedKm > thresholdKm else { return }

        lastRegionFetchTime = now
        pendingRegionChange = target
        mapPage = 0
        placeViewModel.findPolygonPlacesForMap(latitude: target.latitude, longitude: target.longitude)
    }
    
    
    // Debounced: coalesces the burst of per-place calls (checkCenterPlusNearTribe runs at the end of
    // addGroundOverlayBasedOnBounds, i.e. once per place during the overlay loop) into ONE evaluation
    // after placeOverlays has settled. Without this the closest tribe oscillated as overlays were
    // added/removed mid-loop, thrashing the popup's create/hide and racing its async data fetch
    // (loading-forever regression). Android recomputes the popup only when the camera settles.
    private func checkCenterPlusNearTribe() {
        nearbyTribeCheckWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.performNearbyTribeCheck() }
        nearbyTribeCheckWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }

    private func performNearbyTribeCheck() {
        guard let mapView = mapView else { return }
        if isGroundOverlayClicked2 { return }

        let center = mapView.camera.target

        // Overlays are cached across the whole session now (never destroyed on pan-out), so
        // placeOverlays contains far-away territories too. The popup must only consider tribes
        // that are actually attached AND on screen, or panning to an empty area would pop the
        // card for a territory tens of km behind the user.
        let visibleRegion = mapView.projection.visibleRegion()
        var viewport = GMSCoordinateBounds(coordinate: visibleRegion.nearLeft, coordinate: visibleRegion.nearRight)
        viewport = viewport.includingCoordinate(visibleRegion.farLeft).includingCoordinate(visibleRegion.farRight)
        let visiblePlaces = placeOverlays.compactMap { (overlay, place) -> PolygonPlaceDetails? in
            guard overlay.map != nil else { return nil }
            guard let anchor = place.polygonCenter?.toCLLocationCoordinate2D()
                    ?? place.coordinates?.toCLLocationCoordinate2D() else { return nil }
            return viewport.contains(anchor) ? place : nil
        }

        guard let nearbyPlace = visiblePlaces.min(by: {
            centerDistance($0, from: center) < centerDistance($1, from: center)
        }) else {
            if lastNearbyTribeKey != nil {
                delegate?.mapManagerDidMoveAwayFromNearbyTribe(self)
            }

            lastNearbyTribeKey = nil
            return
        }

        let placeKey = nearbyPlace.placeKey ?? "unknown"

        if lastNearbyTribeKey != placeKey {
            lastNearbyTribeKey = placeKey
            delegate?.mapManager(self, didFindNearbyTribe: nearbyPlace)
        }
    }

    private func centerDistance(_ place: PolygonPlaceDetails, from center: CLLocationCoordinate2D) -> CLLocationDistance {
        let anchor: CLLocationCoordinate2D
        if let c = place.polygonCenter, let lat = c.latitude, let lng = c.longitude {
            anchor = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        } else if let c = place.coordinates, let lat = c.latitude, let lng = c.longitude {
            anchor = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        } else {
            return .greatestFiniteMagnitude
        }
        return GMSGeometryDistance(center, anchor)
    }

    private func isCenterNearPolygon(
        center: CLLocationCoordinate2D,
        place: PolygonPlaceDetails,
        bufferMeters: CLLocationDistance
    ) -> Bool {

        if place.isCircle() {
            guard let coordinates = place.coordinates,
                  let lat = coordinates.latitude,
                  let lng = coordinates.longitude else {
                return false
            }

            let circleCenter = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let radius = CLLocationDistance(place.size ?? 0)
            let distance = GMSGeometryDistance(center, circleCenter)

            return distance <= radius + bufferMeters
        }

        guard let points = place.polygonPoints, !points.isEmpty else {
            return false
        }

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

            let nearest = nearestPointOnSegment(center, start, end)
            let distance = GMSGeometryDistance(center, nearest)

            if distance <= bufferMeters {
                return true
            }
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
    
    func locationservicesEnabledandAuthorized(isAuthrized: Bool){
        areLocationAllowedPermissions = isAuthrized
    }
    
    // MARK: - Map Interaction Settings
    
    func updateMapInteractionSettings() {
        guard let mapView = mapView else { return }
        
        mapView.settings.rotateGestures = false

        if isLocationPermissionDenied && !isCitySaved() {
            mapView.isUserInteractionEnabled = false
            mapView.settings.scrollGestures = false
            mapView.settings.zoomGestures = false
        } else {
            mapView.isUserInteractionEnabled = true
            mapView.settings.scrollGestures = true
            mapView.settings.zoomGestures = true
        }
    }
    
    // MARK: - Camera and User Location

    func removeSelectedMarkerInfoView() {
        print("removeSelectedMarkerInfoView")
        self.selectedMarkerInfoView?.removeFromSuperview()
        self.selectedMarkerInfoView = nil
    }
    
    // MARK: - Public Methods
    
    func updateCenterPlaceNameUI(withModel placeModel: MapCenterAddressResponse?) {
        // Method to update center place name UI
        guard let model = placeModel else {
            delegate?.mapManager(self, hideCertainViews: true)
            return
        }
        guard placeModel?.centerCoordinate == mapView?.camera.target else {
            delegate?.mapManager(self, hideCertainViews: true)
            return
        }
        
        delegate?.mapManager(self, updateCurrentAddressLabelWithText: model.getPlaceName(zoom: mapView!.camera.zoom))
        
    }
    
    
    private func resetMapView() {
        guard mapView != nil else {return}
        mapView?.clear()
    }
    
    func updateUserLocation(location: CLLocation , moveToUserLocation : Bool = false) {
        
        mLastLocation = location
        if !cityRecentlyChanged {
            placeViewModel.lastLocationSelected = location
        }
        Constants.location = location // Assuming you have a Constants struct with a location property
        
        // Remove existing marker
        if myLocationMarker != nil {
            myLocationMarker?.map = nil
        }
        
        self.userCurrentLocation = location
        
        var shouldMoveToUserLocation = false

        if moveToUserLocation {
            shouldMoveToUserLocation = true
        } else if placeViewModel.locationSharedOrSelected && !moveToUserLocation {
            shouldMoveToUserLocation = false
        }
        
        if areLocationAllowedPermissions && shouldMoveToUserLocation  {
            // Add marker at user location
            addUserLocationMarker()
            centerMapOnLocation(location: mLastLocation, title: "", displayMarker: true)
        }else {
            print(areLocationAllowedPermissions)
            print(shouldMoveToUserLocation)
        }
         
    }
    
    func setMapCameraToUserLocation(zoomLevel zoom: Float = 10) {
        guard let userLoc = self.userCurrentLocation else {
            return
        }
        if self.myLocationMarker != nil {
            self.myLocationMarker?.map = nil
        }
        addUserLocationMarker()
        self.setMapCameraToCoordincate(loc: userLoc.coordinate, zoom: zoom, completion: nil)
    }
    
    func addUserLocationMarker() {
        resetMapView()
        // Creates a marker for user location
        guard let loc = self.userCurrentLocation?.coordinate else {
            return
        }
        let userMarkerIconView = UIImageView(image: #imageLiteral(resourceName: "user-locaiton-marker-ic"))
        let marker = GMSMarker()
        marker.position = loc
        marker.tracksInfoWindowChanges = true
        marker.tracksViewChanges = true
        marker.iconView = userMarkerIconView
        UIView.animate(withDuration: 0.2, delay: 0.5, options: .curveEaseInOut) {
            [weak self] in
            guard let self = self else { return }
            marker.map = self.mapView
        } completion: { [weak self] bool in
            guard let self = self else { return }
            self.myLocationMarker = marker
        }
    }
    
    func setMapCameraToCoordincate(loc: CLLocationCoordinate2D, zoom: Float, completion: (() -> Void)?) {
        let camera = GMSCameraPosition.camera(withTarget: loc, zoom: zoom)
        let cameraUpdate = GMSCameraUpdate.setCamera(camera)
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        CATransaction.setValue(0.8, forKey: kCATransactionAnimationDuration)
        self.mapView?.animate(with: cameraUpdate)
        CATransaction.commit()
    }
    
}

// MARK: - GMSMapViewDelegate

extension MapManager: GMSMapViewDelegate {
    
//    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
//        
//        for (groundOverlay, polygon) in associatedPolygons {
//                // Ensure the polygon exists and has a valid path
//                if let polygon = polygon, let path = polygon.path {
//                    // Check if the tapped coordinate is within the polygon's path
//                    if GMSGeometryContainsLocation(coordinate, path, true) {
//                        handlePolygonTap(polygon, associatedOverlay: groundOverlay)
//                        break
//                    }
//                }
//            }
//        }
        
        // Handle a polygon tap by removing associated overlays and taking other actions
    func handlePolygonTap(_ polygon: GMSPolygon, associatedOverlay:GMSOverlay) {
            do {
                if let circle = circle {
                        circle.map = nil // Removes the circle from the map
                    }
                
                if let overlayAssociated = associatedOverlays[polygon] {
                    mapView(mapView!, didTap: associatedOverlay)
                }
            }
        }
        
        
    
    func mapView(_ mapView: GMSMapView, didTap overlay: GMSOverlay){
        
        if let polygon = overlay as? GMSPolygon {
            if let overlayAssociated = associatedOverlays[polygon] {
                handlePolygonTap(polygon, associatedOverlay: overlayAssociated)
            }
            return
        }
        
        
        isGroundOverlayClicked = true
        isGroundOverlayClicked2 = true
        placeSheetCheckIn = false
        delegate?.mapManagerDidMoveAwayFromNearbyTribe(self)
        lastNearbyTribeKey = nil

        if let circle = circle {
            circle.map = nil // Removes the circle from the map
        }
        
        isFocusCirclecalled = true
        
        if let groundOverlay = overlay as? GMSGroundOverlay,
           let placeDetails = placeOverlays[groundOverlay] {
            polygonPlaceGroundOverlayClicked(placeDetails: placeDetails, overlay: groundOverlay)
            delegate?.update_Carousel_DataSet(places: placeDetails.places!)
            
        }
    }
    
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if marker == nearbyPopupMarker, let place = marker.userData as? PolygonPlaceDetails {
            delegate?.mapManager(self, didTapNearbyTribePopup: place)
            return true
        }
        if (isGroundOverlayClicked2) {
            let selected = focusPolygonMarkers[marker]
            if (selected != nil) {
                placeViewModel.changeFocusedPlace(selectedPlace: selected!)
            }else {
                print("selected marker nil")
            }
        }
        //delegate?.mapManager(self, didTap: marker)  // Forward event to delegate
        return true
    }
    
    
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
          
        
        print("isDrag .................... \(isDrag)")
        
        if self.isDrag {
            return
        }

        // Focus (tribe lock) mode: no sweeps, no geo lookups, no region refetch. If the user panned
        // away inside the lock bounds, snap the camera back to the lock view on release (Android parity).
        if isGroundOverlayClicked2 {
            delegate?.mapManager(self, idleAt: position)
            snapBackToFocusLockIfNeeded(position: position)
            return
        }

        //Calling here to store and synce camera zoom value with PanGesture Slider
        delegate?.mapManager(self, idleAt: position)
        
        //date1 = Date()
        //print("cameraIdleCalled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in  // 300ms delay
            
            guard let self = self else {return}
            
            self.updateGroundOverlayInBounds()
            
            let coordinates = mapView.camera.target
            
            if !self.isGroundOverlayClicked {
                self.placeViewModel.getLocationInfo(
                    latitude: coordinates.latitude,
                    longitude: coordinates.longitude
                )
            }
            
            self.isGroundOverlayClicked = false

            // Zoom-adaptive, throttled region refetch (was a fixed dist > 24.5 check that let the
            // viewport outrun the 25km fetched disc — see maybeFetchRegionForCamera).
            self.maybeFetchRegionForCamera()
        }
        
    }
    
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        if isGroundOverlayClicked2 { return }   // in focus: freeze redraws so a pan can't re-plant region+avatar (Android onCameraMoveStarted `if (overlayClicked) return` parity)
        if !isGroundOverlayClicked {
           // myLocationFab.isHidden = false
            reRenderPolygons()
        }
    }

    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {

        if isFocusCirclecalled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
                self?.isFocusCirclecalled = false
            })
            return
        }

        if isGroundOverlayClicked2 { return }   // in focus: camera is locked, don't exit or recheck

        removeFocusedPlaceView()
        delegate?.mapManager(self, didChange: position)
        delegate?.mapManager(self, hideCertainViews: true)

        checkCenterPlusNearTribe()   // self-debounced (coalesces with the per-place overlay-loop calls)
        schedulePanDrivenSweep()     // territories entering the viewport start loading mid-pan
    }
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        return nil
    }
    
    func mapView(_ mapView: GMSMapView, markerInfoContents marker: GMSMarker) -> UIView? {
        return nil
    }
    
    private func refreshCenterPlaceName(at position: GMSCameraPosition) {
       
       // viewModel?.fetchCenterCoordinatePlaceName(coordinate: position.target)
        delegate?.mapManager(self, hideCertainViews: true)
    }
    
    private func refreshCenterPlaceNamePlaceViewModel(at position: GMSCameraPosition) {
        placeViewModel.getLocationInfo(latitude: position.target.latitude, longitude: position.target.longitude)
    }
    
    private func updateGPSViewVisibility(atPosition position: GMSCameraPosition) {
        
        let cameraPosition = position.target
        guard let userLocation = self.userCurrentLocation else {
           // gpsView.isHidden = true
            delegate?.mapManager(self, hideGpsView: true)
            return
        }
        let distance = userLocation.distance(from: CLLocation(latitude: cameraPosition.latitude, longitude: cameraPosition.longitude))
       // gpsView.isHidden = distance.rounded().isZero
        delegate?.mapManager(self, hideGpsView: distance.rounded().isZero)
    }
    
    
    

}
//MARK: map rendering section Overlays and marker goes here not working yet
extension MapManager {
    
    func buildCities() {
        if let path = Bundle.main.path(forResource: "cities", ofType: "json"),
           let inputStream = InputStream(fileAtPath: path) {
            placeViewModel.buildCities(inputStream: inputStream)
        }
    }

    
    func saveLastCitySelectedOnSharedPreferences() {
        if let loc = placeViewModel.lastLocationSelected {
            let coordinate = loc.coordinate
            sharedPreferences.set(Float(coordinate.latitude), forKey: "selected_city_latitude")
            sharedPreferences.set(Float(coordinate.longitude), forKey: "selected_city_longitude")
            sharedPreferences.synchronize()
            enableMapDragging()
        }else{
            print("no last locatin to save")
        }
    }
    
    func onCitySelected(cityName: String, loc:CLLocationCoordinate2D?) {
        guard let loc = loc, cityName != lastCitySelected else {
           // restoreCitySelectorLayout()
           // hideKeyboard()
            return
        }

        cityRecentlyChanged = true
        lastCitySelected = cityName
        cancelAllCreationJobs()
        
        lastOverlayUpdatedTime = Int(Date().timeIntervalSince1970)
        placeViewModel.locationSharedOrSelected = true
        loadedOverlay = false
        
        removeAllGroundOverlaysAndPolygons()
        placeViewModel.setLastCitySelected(loc: loc)
        saveLastCitySelectedOnSharedPreferences()
        
       // print("onLocationChanged - City selected \(cityName)")
        
        if !areLocationAllowedPermissions {
            enableMapDragging()
            centerMapOnLocation(location: placeViewModel.lastLocationSelected, title: nil, displayMarker: false)
            
        } else {
            mapView?.animate(to: GMSCameraPosition.camera(withTarget: loc, zoom: defaultZoom))
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else {return}
            self.cityRecentlyChanged = false
        }

//        restoreCitySelectorLayout()
//        hideKeyboard()
    }
    
    private func removeAllGroundOverlaysAndPolygons() {
        print("removeAllGroundOverlaysAndPolygons")
        for (overlayCircle, polygonAssociated) in placeOverlays {
            // Remove associated polygon if it exists
            if let polygon = associatedPolygons[overlayCircle] as? GMSPolygon {
                polygon.map = nil // Remove polygon from map
            }
            
            // Remove the overlay circle from the map
            overlayCircle.map = nil
        }
        
        // Clear all collections. placeOverlays/willBePlaceOverLays are main-confined GMS registries;
        // places/polygonPlacesKeys are shared with the access queue, so clear them under it (S0 race close).
        placeOverlays.removeAll()
        willBePlaceOverLays.removeAll()
        placesAccessQueue.sync {
            self.polygonPlacesKeys.removeAll()
            self.places.removeAll()
        }
        delegate?.mapManager(self, didUpdateVisibleTribes: [])
    }


    
    private func cancelAllCreationJobs() {
        // S1: invalidate any in-flight Phase C (bump BEFORE the teardown that follows at call sites, so a
        // queued stale attach fails its generation guard) and stop the current S1 sweep's Phase B.
        currentGeneration &+= 1
        idleTask?.cancel()
        idleTask = nil
        for job in creationJobs {
            job.cancel()
        }
        creationJobs.removeAll()
        bindingloading = true
        delegate?.mapManagerShowOrbisLoader(isShow: true)
    }
    
    //TODO: Observer Listner to be called from ViewDidLoad

    func placeViewModelListener() {
        observeNewAddedPolygonPlace()
        observeMapPolygonPlaces()
        observePolygonFocusedPlaces()
        observeNewFocusedChanges()
        observeNewAddedPlace()
        observeUpdatePolygon()
        observeUpdateCircle()
        observeLocationInfo()
        observeAllCities()
    }
    
    //MARK: PlaceViewModel Listener code
    
    func observeNewAddedPolygonPlace() {
        placeViewModel.$newAddedPolygonPlace
            .receive(on: DispatchQueue.main) // Ensure it runs on the main thread
            .sink { [weak self] newPolygonPlace in
                guard let self = self else { return }
                
                // Check the specific initial load flag for mapPolygonPlaces
                if self.placeViewModel.isInitialNewAddedPolygonPlace {
                    self.placeViewModel.isInitialNewAddedPolygonPlace = false
                    return
                }
                
                
                if !self.polygonPlaceContains(place: newPolygonPlace!) {
                    self.removeSupersededPlaces(by: newPolygonPlace!)
                    self.addPlaceToMemory(place: newPolygonPlace!)
                    self.addGroundOverlayBasedOnBounds(place: newPolygonPlace!)
                }
            }
            .store(in: &cancellables)
    }
    
    
    func observeMapPolygonPlaces() {
        placeViewModel.$mapPolygonPlaces
            .receive(on: DispatchQueue.main) // Ensure it runs on the main thread
            .sink { [weak self] (places: [PolygonPlaceDetails]) in
                
                guard let self = self else { return }
                

                // Check the specific initial load flag for mapPolygonPlaces
                if self.placeViewModel.isInitialMapPolygonPlacesLoad {
                    self.placeViewModel.isInitialMapPolygonPlacesLoad = false
                    return
                }
                
                if cityRecentlyChanged { return }
                
                delegate?.mapManagerShowOrbisLoader(isShow: false)
                loadedOverlay = true
                fabClicked = false
                
                if let pendingChange = pendingRegionChange {
                    lastLocation = CLLocationCoordinate2D(latitude: pendingChange.latitude, longitude: pendingChange.longitude)
                    if places.isEmpty {
                        // Empty region (ocean etc.): consume the pending change here — the marker
                        // block below only clears it for non-empty results, and a dangling value
                        // used to re-trigger displayLocationMarker on a later unrelated fetch.
                        pendingRegionChange = nil
                    }
                }
                
                if places.isEmpty || places.count != 20 {
                    self.bindingloading = false
                    delegate?.mapManagerShowOrbisLoader(isShow: false)
                }
                
                let placesEmpty = placesAccessQueue.sync { self.places.isEmpty }   // S0: guarded read
                if placesEmpty {
                    placeViewModel.isLoading = true
                }
                
                if !places.isEmpty && pendingRegionChange != nil {
                    displayLocationMarker()
                    pendingRegionChange = nil
                }
                print("places count no :  \(places.count)")
                if places.count == 20 && !cityRecentlyChanged {
                    mapPage += 1
                    print("mapPage no :  \(mapPage)")
                    placeViewModel.findPolygonPlacesForMap(latitude: lastLocation?.latitude ?? 0, longitude: lastLocation?.longitude ?? 0, page: mapPage)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    guard let self else { return }
                    self.delegate?.mapManager(self, didUpdateVisibleTribes: self.getAllVisibleTribes())
                }
                
                // Process each place with a DispatchWorkItem for concurrent handling
                for place in places {
                    if cityRecentlyChanged {
                        return
                    }
                    
                    let job = Task { [weak self] in
                        guard let self = self else { return }
                        if !self.polygonPlaceContains(place: place) {
                            self.addPlaceToMemory(place: place)

                            DispatchQueue.main.async { [weak self] in
                                self?.removeSupersededPlaces(by: place)
                                self?.addGroundOverlayBasedOnBounds(place: place)
                            }
                        }
                    }
                    creationJobs.append(job)
                }
            }
            .store(in: &cancellables)
    }
    
    func observePolygonFocusedPlaces() {
        placeViewModel.$polygonFocusedPlaces
            .receive(on: DispatchQueue.main) // Ensure it runs on the main thread
            .sink { [weak self] places in
                guard let self = self else { return }
                
                if self.placeViewModel.isInitialPolygonFocusedPlacesLoad {
                    self.placeViewModel.isInitialPolygonFocusedPlacesLoad = false
                    return
                }
                
                if isGroundOverlayClicked2 && !places.isEmpty {
                    if !placeViewModel.changedFocus {
                        //TODO : BOTTOM CARDS VISIBILITY
                        // map_places_pager_2.adapter = PlacesPagerAdapter(context: self, places: places)
                        
                        
                        
                        //delegate?.update_Carousel_DataSet(places: places)
                        
                        
                    } else {
                        // map_places_pager_2.adapter?.notifyDataSetChanged()
                        //delegate?.update_Carousel_DataSet(places: places)

                    }
                    

                    
                    
                    if placeViewModel.newFocusedChanges == nil {
                        
                        //var mFocusPolygonMarkers = focusPolygonMarkers

                        for marker in focusPolygonMarkers.keys {
                            marker.map = nil // Remove the marker from the map
                            //mFocusPolygonMarkers.removeValue(forKey: marker)
                        }
                        
                        //focusPolygonMarkers = mFocusPolygonMarkers

                        for place in places {
                           drawFocusedPlaceMarker(place: place, unique: places.count == 1)
                        }
                    }
                    
                    if polygonFocusingFirstTime {
                        //adjustViewPagerHeightAt(index: 0)
                    }
                    
                    // map_places_pager.isHidden = false
                    polygonFocusingFirstTime = false
                    
                    //Show Carousel View
                    delegate?.isShow_OR_Hide_Carousel(isVisible: true)
                }
                
            }.store(in: &cancellables)
    }
    


    
    func observeNewFocusedChanges() {
        placeViewModel.$newFocusedChanges
            .receive(on: DispatchQueue.main) // Ensure it runs on the main thread
            .sink { [weak self] changes in
                
                
                if self?.placeViewModel.isInitialNewFocusedChangesLoad  == nil {
                    self?.placeViewModel.isInitialNewFocusedChangesLoad = false
                    return
                }
                
                guard let self = self, let (oldPlace, newFocus) = changes else { return }
                
               
                
                //var mFocusPolygonMarkers = focusPolygonMarkers
                
                // Remove markers for old and new focus places
                for (marker, place) in focusPolygonMarkers where place.placeKey == oldPlace.placeKey || place.placeKey == newFocus.placeKey {
                    marker.map = nil
                    //mFocusPolygonMarkers.removeValue(forKey: marker)
                }
                
                //focusPolygonMarkers = mFocusPolygonMarkers
                
                
                // Draw markers for the old and new focused places
                drawFocusedPlaceMarker(place: oldPlace, unique: false)
                drawFocusedPlaceMarker(place: newFocus, unique: false)
                
                
                delegate?.selectedPlaceToScrollCarousel(place: newFocus)

 
            }.store(in: &cancellables)
    }
    

    func observeNewAddedPlace(){
        placeViewModel.$newAddedPlace
            .receive(on: DispatchQueue.main) // Ensure it runs on the main thread
            .sink { [weak self] place in
                guard let self = self else { return }
                
                if self.placeViewModel.isInitialNewAddedPlaceLoad {
                    self.placeViewModel.isInitialNewAddedPlaceLoad = false
                    return
                }
                
               // print("Place created: \(String(describing: place?.name))")
                mapPage = 0
                //TODO:-  reset all array here
                //placeViewModel.completeCheckInProgressBar()
                placeViewModel.findPolygonPlacesForMap(latitude: lastLocation?.latitude ?? 0, longitude: lastLocation?.longitude ?? 0)
                enableMapDragging()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self = self else {return}
                    self.checkInCompleted = true
                    self.hideCheckInLoading()
                }
                if let mplace = place{
                    placeViewModel.findPolygonPlace(placeKey: mplace.placeKey!)
                }
            }.store(in: &cancellables)
    }
    
    func observeUpdatePolygon(){
        
        placeViewModel.$updatedPolygon
            .receive(on: DispatchQueue.main) // Ensure it runs on the main thread
            .sink { [weak self] update in
                guard let self = self, let mupdate = update else { return }
                
                if self.placeViewModel.isInitialUpdatePolygonLoad {
                    self.placeViewModel.isInitialUpdatePolygonLoad = false
                    return
                }
                
                var (oldPlace, polygonsAppeared) = update!
                //print("Updated place/polygon from: \(String(describing: oldPlace.name))")
                
                var newPolygons: [PolygonPlaceDetails] = []
                var newPolygonsPlaceKeys: Set<String> = []
                
                for place in polygonsAppeared {
                    if let place = place, !newPolygonsPlaceKeys.contains(place.placeKey!) {
                        newPolygonsPlaceKeys.formUnion(place.places!.map { $0.placeKey! })
                        newPolygons.append(place)
                    }
                }
                
                if newPolygons.isEmpty {
                    //print("Place/polygon: \(String(describing: oldPlace.name)) deleted from the map")
                    removeGroundOverlayAndPolygon(place: oldPlace)
                    removePlaceOfMemory(place: oldPlace)
                    return
                }
                
                var firstNew = newPolygons.removeFirst()
                //print("Animating update for place/polygon: \(String(describing: firstNew.name))")
                transformOverlayAndPolygonWithAnimation(fromPlace: &oldPlace, toPlace: &firstNew)
                
                replaceOldPlaceForNewPlaceInMemory(oldPlace: oldPlace, newPlace: firstNew)
                
                removeIncludedPlaces(newPlace:firstNew)
                
                for nextPlace in newPolygons {
                    //print("Creating place/polygon: \(String(describing: nextPlace.name))")
                    print("add memory called from updatePolygon")
                    addPlaceToMemory(place: nextPlace)
                    self.addGroundOverlayBasedOnBounds(place: nextPlace)
                }
            }.store(in: &cancellables)
    }

    func observeUpdateCircle(){
        
        placeViewModel.$updatedCircle
            .receive(on: DispatchQueue.main) // Ensure it runs on the main thread
            .sink { [weak self] update in
                guard let self = self, let mupdate = update else { return }
                
                if self.placeViewModel.isInitialUpdateCircleLoad {
                    self.placeViewModel.isInitialUpdateCircleLoad = false
                    return
                }
                
            var (oldPlace, newPlace) = update!

                if newPlace == nil || !newPlace!.isCircle() {
                    disappearCircleAnimation(place: oldPlace)
                } else {
                    updateCircleAnimation(oldPlace: &oldPlace, newPlace: &newPlace!)
                }
            }.store(in: &cancellables)
        
    }
    
    func observeLocationInfo() {
        
        
        placeViewModel.$locationInfo
            .receive(on: DispatchQueue.main) // Ensure it runs on the main thread
            .sink { [weak self] locationInfo in
                guard let self = self else { return }
                
                if self.placeViewModel.isInitialLocationInfoLoad {
                    self.placeViewModel.isInitialLocationInfoLoad = false
                    return
                }
                
               
                var isLocationInfoValid = false
                if  locationInfo != nil {
                    isLocationInfoValid = locationInfo?.centerCoordinate!.latitude != 0 && locationInfo?.centerCoordinate!.longitude != 0
                }
                
                // Adjust based on actual criteria for validity

                let isHiddensuburb = !(isLocationInfoValid && placeViewModel.locationSharedOrSelected && !isGroundOverlayClicked2)
                let isHiddencity = !isLocationInfoValid || !placeViewModel.locationSharedOrSelected || isGroundOverlayClicked2
                
               
                
                delegate?.mapManager(self, hideSuburbView: isHiddensuburb)
                delegate?.mapManager(self, showHide: isHiddencity)
                
                
                let neighborhood = locationInfo?.suburb ?? locationInfo?.cityDistrict
                let city = locationInfo?.city ?? locationInfo?.municipality ?? locationInfo?.county ?? locationInfo?.stateDistrict ?? locationInfo?.state
                let country = locationInfo?.country ?? ""

               // print("locationInfo: \(String(describing: locationInfo))")
            
                let text = neighborhood ?? city ?? country

                if !text.isEmpty {

                    delegate?.updateTextOnSearchBar(city)
                    if currentZoom > 11 {
                        
                        //!neighborhood.isNullOrEmpty() && placeViewModel.locationSharedOrSelected && !isGroundOverlayClicked2
                        let isHidden = neighborhood?.isEmpty ?? true || !placeViewModel.locationSharedOrSelected || isGroundOverlayClicked2
                    
                        delegate?.mapManager(self, hideSuburbView: isHidden)
                        //delegate?.updateTextOnSearchBar(text)
                        delegate?.mapManager(self, updateCurrentAddressLabelWithText: text)
                    }
                    if currentZoom < 11 && currentZoom >= 7 {
                        delegate?.mapManager(self, hideSuburbView: true)
                    }
                    
                    if currentZoom < 7 || city?.isEmpty ?? true {
                        delegate?.mapManager(self, hideSuburbView: true)
                        delegate?.updateTextOnSearchBar(country)
                    }
                    
                } else {
                    //Hide if no location name
                    delegate?.mapManager(self, hideCertainViews: true)
                }
                
                
                //delegate.shouldShowCenterSearchBar()
                
                CLHelper.performFirstTimeAction { [weak self] in
                    print("This is the very first launch of the app!")
                    self?.delegate?.mapManager(self!, showHide: false)
                    self?.delegate?.mapManager(self!, hideSuburbView: true)
                    self?.delegate?.updateTextOnSearchBar("")
                    return
                }
                
                
                
            }.store(in: &cancellables)
        
    }
    
    func observeAllCities() {
        placeViewModel.$allCities.sink { [weak self] cities in
            guard let self = self else { return }
            
            if self.placeViewModel.isInitialAllCitiesLoad {
                self.placeViewModel.isInitialAllCitiesLoad = false
                return
            }
            
            allCities = cities
            //loadCitiesToSelectors()
        }.store(in: &cancellables)
    }
    
    
    //TODO: Original code comment for replaced testing (may be removed later)
//    func polygonPlaceContains(place: PolygonPlaceDetails) -> Bool {
//        // Ensure `placeKey` is not nil
//        guard let placeKey = place.placeKey else { return false }
//           
//
//        return DispatchQueue.main.sync {
//            
//            // Check if `placeKey` exists in `places`
//            for p in places {
//                if p.placeKey == placeKey {
//                    return true
//                }
//            }
//            
//            // If `place` is not a circle, check `polygonPlacesKeys`
//            if !place.isCircle() {
//                return polygonPlacesKeys.contains(placeKey)
//            }
//            
//            return false
//        }
//    }

    func polygonPlaceContains(place: PolygonPlaceDetails) -> Bool {
        // Ensure `placeKey` is not nil
        guard let placeKey = place.placeKey else { return false }
           

        return placesAccessQueue.sync {
            
            // Check if `placeKey` exists in `places`
            for p in places {
                if p.placeKey == placeKey {
                    return true
                }
            }
            
            // If `place` is not a circle, check `polygonPlacesKeys`
            if !place.isCircle() {
                return polygonPlacesKeys.contains(placeKey)
            }
            
            return false
        }
    }

    
    func addPlaceToMemory(place: PolygonPlaceDetails) {
        // Ensure this method is only executed on the main thread for UI safety
        placesAccessQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Append the place to places array
            // print("self.places append in addPlaceToMemory placeKey  \(place.placeKey)")
            self.places.append(place)
            
            
            // If place is not a circle and polygonCenter is available, add place keys
            if !place.isCircle(), let polygonCenter = place.polygonCenter {
                if let placeKeys = place.places?.compactMap({ $0.placeKey }) {
                    self.polygonPlacesKeys.append(contentsOf: placeKeys)
                }
            }
        }
    }


    func addGroundOverlayBasedOnBounds(place: PolygonPlaceDetails,
                                       precomputedBounds: GMSCoordinateBounds? = nil,
                                       precomputedRadius: CLLocationDistance? = nil)  {

        guard let googleMap = self.mapView else {return}
        guard let polygonCenter = place.polygonCenter else { return }

        // S0: use the viewport hoisted once by updateGroundOverlayInBounds when available; the
        // single-place callers (observeNewAddedPolygonPlace / pagination) pass nil and compute here.
        let bounds: GMSCoordinateBounds
        if let precomputedBounds = precomputedBounds {
            bounds = precomputedBounds
        } else {
            let visibleRegion = googleMap.projection.visibleRegion()
            var b = GMSCoordinateBounds(coordinate: visibleRegion.nearLeft, coordinate: visibleRegion.nearRight)
            b = b.includingCoordinate(visibleRegion.farLeft)
            b = b.includingCoordinate(visibleRegion.farRight)
            bounds = b
        }

        let size = place.isCircle() ? place.size : CoordinatesUtil.calculatePolygonRadius(coord: place.polygonPoints!)
        var inBounds = false

        if !place.isCircle(), let polygonPoints = place.polygonPoints {
            // Center first — edge-straddling territories can miss every sampled vertex.
            if let ctr = place.polygonCenter, let lat = ctr.latitude, let lng = ctr.longitude,
               bounds.contains(CLLocationCoordinate2D(latitude: lat, longitude: lng)) {
                inBounds = true
            } else {
                for i in stride(from: 0, to: polygonPoints.count, by: 100) {
                    if bounds.contains(polygonPoints[i].toCLLocationCoordinate2D()) {
                        inBounds = true
                        break
                    }
                }
            }
        } else if let coordinates = place.coordinates {
            inBounds = bounds.contains(coordinates.toCLLocationCoordinate2D())
        }

        let visibleRadius = precomputedRadius ?? googleMap.getRadius()
        let isVisibleSizeCriteriaMet = (visibleRadius / (size ?? 1.0)) <  AppValues.markersVisibilityFactor
        
        
        // Cached-overlay policy (matches the S1 sweep): never destroy for viewport/zoom reasons.
        // Zoom fails detach the overlay (kept in placeOverlays for instant re-attach); pan-outs
        // leave it attached — GMS culls off-screen geometry. Destroy+recreate was the ~1s
        // vanish-then-reload blink on every pan-back.
        if isVisibleSizeCriteriaMet  {
            if self.findOverlay(for: place) != nil {
                self.setOverlayHidden(place: place, hidden: false)
            } else if inBounds {
                if !self.willBePlaceOverLays.contains(where: { $0.placeKey == place.placeKey }) {
                    self.willBePlaceOverLays.append(place)
                    self.createGroundOverlayAndPolygon(placeDetails: place)
                    //MapManager.testingInt = 1
                }
            }
        } else {
            self.setOverlayHidden(place: place, hidden: true)
        }

        checkCenterPlusNearTribe()
    }

    
    /*
    func createGroundOverlayAndPolygon(placeDetails: PolygonPlaceDetails)  {
        //print("createGroundOverlayAndPolygon")
        var mutablePlaceDetails = placeDetails
        mutablePlaceDetails.computeSize()
        let diameter = CGFloat(mutablePlaceDetails.size! * 2.0)
        
       // print("iOS place detail size:\(String(describing: mutablePlaceDetails.size)), diameter size \(diameter)")

        let storageRef = Storage.storage().reference(withPath: Constants.GROUP_PHOTO_STORAGE + Utils.getImageUrl200(imageName: mutablePlaceDetails.dominantGroup!.imageName!))

        let centerLatLng = CLLocationCoordinate2D(latitude: mutablePlaceDetails.polygonCenter!.latitude!, longitude: mutablePlaceDetails.polygonCenter!.longitude!)
        let polygonPoints = mutablePlaceDetails.polygonPoints

        var newPolygon: GMSPolygon? = nil
       // var polygonAnimation: CAAnimation? = nil

        if !mutablePlaceDetails.isCircle() {
           // print("calculatingPolygon", mutablePlaceDetails.name as Any)
            var smoothedLatLng = CoordinatesUtil.coordinatesToLatLng(polygonPoints!)
            smoothedLatLng = CoordinatesUtil.chaikin(arr: smoothedLatLng, num: 2)
            smoothedLatLng = CoordinatesUtil.bspline(poly: &smoothedLatLng)

            let centroid = CoordinatesUtil.calculateCentroid(points: smoothedLatLng)
            let path = GMSMutablePath()
            for point in smoothedLatLng {
                path.add(point)
            }

            newPolygon = GMSPolygon(path: path)
            newPolygon?.strokeWidth = 0
            newPolygon?.strokeColor = mutablePlaceDetails.getPlaceColor()
            newPolygon?.zIndex = Int32(UInt32(900 - Int(mutablePlaceDetails.size!)))
            newPolygon?.fillColor = isGroundOverlayClicked2 ? mutablePlaceDetails.getTransparentColor() : mutablePlaceDetails.getNormalColor()
            newPolygon?.isTappable = !isGroundOverlayClicked2
           // polygonAnimation = AnimationsUtil.createPolygonAppearingAnimation(for: newPolygon!, centroid: centroid, polygonPoints: smoothedLatLng)
            
            // No animation
        }

        let isCheckIn = mutablePlaceDetails.places!.contains { $0.placeKey == lastPlaceCreatedKey }
        
        /*
        func onResourceLoaded(image: UIImage?) {
            
            let customIcon = CLHelper.createCustomIconView(for: mutablePlaceDetails, with: image)
            
            let visibleRegion = mapView!.projection.visibleRegion()
            
            let groundOverlay = AnimationsUtil.addGroundOverlayToMap(mapView: mapView!, centerLatLng: centerLatLng, image: customIcon, zoomLevel: diameter, isTappable: !isGroundOverlayClicked2, zIndex: Int32(1000 - Float(mutablePlaceDetails.size ?? 0)))
            
            
            if groundOverlay.map != nil {
                
                newPolygon?.map = !isGroundOverlayClicked2 ? mapView : nil
                if  newPolygon?.map != nil {
                    //polygon appearence animation
                    AnimationsUtil.isAnimatingPolygon = true
                    AnimationsUtil.animatePolygonScaling(polygon: newPolygon!, coordinates: AnimationsUtil.coordinates(from: polygonPoints!))
                    associatedOverlays[newPolygon!] = groundOverlay
                }
                associatedPolygons[groundOverlay] = newPolygon
                
                if isCheckIn {
                    handleCheckInSituation(for: groundOverlay)
                }
    
                
                //TODO: store animation goes here
                
                // Start the overlay animation
                AnimationsUtil.startOverlayAnimation(for: groundOverlay, targetBounds:groundOverlay.bounds!)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: { [weak self] in
                    guard let self = self else {return}
                    
                    mutablePlaceDetails.animator = AnimationsUtil.createPulseAnimation(groundOverlay: groundOverlay, placeDetails: mutablePlaceDetails)
                    if  mutablePlaceDetails.animator != nil {
                        // AnimationsUtil.startPulseAnimation(placeDetails:mutablePlaceDetails, valueAnimator: mutablePlaceDetails.animator!)
                    }
                    
                })
                
                //TODO: end of store animation here
                
                
                placeOverlays[groundOverlay] = mutablePlaceDetails
                //print("placeOverlays added Item \(String(describing: mutablePlaceDetails.placeKey))")
               // testingPlaceKey = mutablePlaceDetails.placeKey //TODO: testing will be removed
            }
            bindingloading = false
            delegate?.mapManagerShowOrbisLoader(isShow: false)
        }
        */
        
        func onResourceLoaded(image: UIImage?) {
            // Create custom icon
            let customIcon = CLHelper.createCustomIconView(for: mutablePlaceDetails, with: image)
            
            guard let mapView = mapView else { return }
            
            // Add ground overlay to the map
            let groundOverlay = AnimationsUtil.addGroundOverlayToMap(
                mapView: mapView,
                centerLatLng: centerLatLng,
                image: customIcon,
                zoomLevel: diameter,
                isTappable: !isGroundOverlayClicked2,
                zIndex: Int32(1000 - Float(mutablePlaceDetails.size ?? 0))
            )
            
            guard groundOverlay.map != nil else { return }
            
            // Handle polygon appearance and animation
            if !isGroundOverlayClicked2, let polygon = newPolygon {
                polygon.map = mapView
                AnimationsUtil.isAnimatingPolygon = true
                if let polygonPoints = polygonPoints {
                    AnimationsUtil.animatePolygonScaling(
                        polygon: polygon,
                        coordinates: AnimationsUtil.coordinates(from: polygonPoints)
                    )
                }
                associatedOverlays[polygon] = groundOverlay
                associatedPolygons[groundOverlay] = polygon
            }
            
            // Handle check-in logic
            if isCheckIn {
                handleCheckInSituation(for: groundOverlay)
            }
            
            // Start overlay animation
            if let bounds = groundOverlay.bounds {
                AnimationsUtil.startOverlayAnimation(for: groundOverlay, targetBounds: bounds)
            }
            
            // Schedule pulse animation asynchronously
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self = self else { return }
                mutablePlaceDetails.animator = AnimationsUtil.createPulseAnimation(
                    groundOverlay: groundOverlay,
                    placeDetails: mutablePlaceDetails
                )
                // Uncomment if pulse animation is needed
                // if let animator = mutablePlaceDetails.animator {
                //     AnimationsUtil.startPulseAnimation(placeDetails: mutablePlaceDetails, valueAnimator: animator)
                // }
            }
            
            // Store overlay and details
            placeOverlays[groundOverlay] = mutablePlaceDetails
            
            // Final clean-up
            bindingloading = false
            delegate?.mapManagerShowOrbisLoader(isShow: false)
        }

        
        storageRef.downloadURL { [weak self] url, error in
            
            guard let self = self else {return}
            
            guard let url = url, error == nil else {
                    onResourceLoaded(image: nil)
                return
            }
            SDWebImageDownloader.shared.downloadImage(with: url) { image, _, _, _ in
                    onResourceLoaded(image: image)
            }
        }
    }
    */
    
    
    func createGroundOverlayAndPolygon(placeDetails: PolygonPlaceDetails) {
        var mutablePlaceDetails = placeDetails
        mutablePlaceDetails.computeSize()
        guard let size = mutablePlaceDetails.size else { return }
        let diameter = CGFloat(size * 2.0)

        let storagePath = Constants.GROUP_PHOTO_STORAGE + Utils.getImageUrl200(imageName: mutablePlaceDetails.dominantGroup?.imageName ?? "")

        let centerLatLng = CLLocationCoordinate2D(
            latitude: mutablePlaceDetails.polygonCenter?.latitude ?? 0,
            longitude: mutablePlaceDetails.polygonCenter?.longitude ?? 0
        )

        // Prepare polygon
        let polygonPoints = mutablePlaceDetails.polygonPoints
        var newPolygon: GMSPolygon?
        if !mutablePlaceDetails.isCircle(), let points = polygonPoints {
            newPolygon = createPolygon(for: mutablePlaceDetails, smoothedPoints: smoothPolygonPoints(points.toCLLocationCoordinate2DArray()))
        }

        let isCheckIn = mutablePlaceDetails.places?.contains(where: { $0.placeKey == lastPlaceCreatedKey }) ?? false

        // Resource loading closure
        func onResourceLoaded(image: UIImage?) {
            defer { self.overlayLoadDidFinish() }
            guard let mapView = self.mapView else { return }

            // The download that led here is async and uncancellable; dedup was only checked at create
            // START (willBePlaceOverLays). Re-check at USE time so a stale completion — one whose place
            // was cleared mid-flight by a full/by-key clear (city change, check-in, circle update) and
            // then re-created — cannot add a SECOND overlay for the same tribe.
            guard self.willBePlaceOverLays.contains(where: { $0.placeKey == mutablePlaceDetails.placeKey }) else { return }
            guard self.findOverlay(for: mutablePlaceDetails) == nil else { return }

            let customIcon = CLHelper.createCustomIconView(for: mutablePlaceDetails, with: image)
            let groundOverlay = AnimationsUtil.addGroundOverlayToMap(
                mapView: mapView,
                centerLatLng: centerLatLng,
                image: customIcon,
                zoomLevel: diameter,
                isTappable: !isGroundOverlayClicked2,
                zIndex: Int32(1000 - Float(size))
            )

            guard groundOverlay.map != nil else {
                // Created during focus mode (addGroundOverlayToMap leaves .map nil): release the
                // willBePlaceOverLays entry, else this territory can never be re-created — the
                // "loaded once, gone forever" caching bug.
                self.willBePlaceOverLays.removeAll { $0.placeKey == mutablePlaceDetails.placeKey }
                return
            }

            // Handle polygon — entrance animation only on the territory's FIRST appearance this session;
            // re-creations (pan away and back) attach at final size with no replay.
            let firstAppearance = self.markAnimatedIfFirstAppearance(placeKey: mutablePlaceDetails.placeKey)
            if !isGroundOverlayClicked2, let polygon = newPolygon {
                if firstAppearance {
                    AnimationsUtil.isAnimatingPolygon = true
                    if let points = polygonPoints {
                        AnimationsUtil.animatePolygonScaling(
                            polygon: polygon,
                            coordinates: AnimationsUtil.coordinates(from: points),
                            mapView: mapView
                        )
                    }
                } else {
                    polygon.map = mapView
                }

                associatedOverlays[polygon] = groundOverlay
                associatedPolygons[groundOverlay] = polygon
            }

            // Handle check-in logic
            if isCheckIn {
                handleCheckInSituation(for: groundOverlay)
            }

            // Start overlay animation (first appearance only)
            if firstAppearance, let bounds = groundOverlay.bounds {
                AnimationsUtil.startOverlayAnimation(for: groundOverlay, targetBounds: bounds)
            }

            // Pulse animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                mutablePlaceDetails.animator = AnimationsUtil.createPulseAnimation(
                    groundOverlay: groundOverlay,
                    placeDetails: mutablePlaceDetails
                )
            }

            // Store overlay
            placeOverlays[groundOverlay] = mutablePlaceDetails

            #if DEBUG
            // TEMP dup diagnostic (remove after root-causing the double territory avatar).
            let _key = mutablePlaceDetails.placeKey ?? "nil"
            // Case 1: same placeKey rendered twice = a real render dup.
            let _sameKey = self.placeOverlays.values.filter { $0.placeKey == mutablePlaceDetails.placeKey }.count
            if _sameKey > 1 {
                print("🟥DUP-SAMEKEY key=\(_key) entries=\(_sameKey) focus=\(self.isGroundOverlayClicked2)")
            }
            // Case 2: a DIFFERENT-key overlay whose center is within this place's own span = two
            // distinct places overlapping into the figure-8 (backend data / split territory).
            if let ctr = mutablePlaceDetails.polygonCenter, let clat = ctr.latitude, let clng = ctr.longitude {
                let _c = CLLocationCoordinate2D(latitude: clat, longitude: clng)
                let _span = (mutablePlaceDetails.size ?? 0) * 2.0
                for (_, _pl) in self.placeOverlays where _pl.placeKey != mutablePlaceDetails.placeKey {
                    if let _oc = _pl.polygonCenter, let _olat = _oc.latitude, let _olng = _oc.longitude {
                        let _d = GMSGeometryDistance(_c, CLLocationCoordinate2D(latitude: _olat, longitude: _olng))
                        if _d < _span {
                            print("🟥NEARBY-DIFFKEY key=\(_key) other=\(_pl.placeKey ?? "nil") dist=\(Int(_d))m span=\(Int(_span))m")
                        }
                    }
                }
            }
            #endif

            // Finalize: loader hide is owned by overlayLoadDidFinish (deferred at the top).
        }

        // Cached load: the old path did a Firebase downloadURL RPC + raw SDWebImageDownloader fetch
        // per call — the downloader never touches SDWebImage's cache, so every overlay re-creation
        // (each pan/zoom bounds re-entry) re-downloaded its tribe image. MapImageLoader memoizes the
        // URL and serves bytes through the shared memory/disk cache. Delivers on main.
        overlayLoadDidStart()
        MapImageLoader.load(storagePath: storagePath) { image in
            onResourceLoaded(image: image)
        }
    }



    private func smoothPolygonPoints(_ points: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        var smoothedPoints = CoordinatesUtil.chaikin(arr: points, num: 2)
        return CoordinatesUtil.bspline(poly: &smoothedPoints)
    }

     
    private func createPolygon(for placeDetails: PolygonPlaceDetails, smoothedPoints: [CLLocationCoordinate2D]) -> GMSPolygon {
        let path = GMSMutablePath()
        for point in smoothedPoints {
            path.add(point)
        }

        let polygon = GMSPolygon(path: path)
        polygon.strokeWidth = 0
        polygon.strokeColor = placeDetails.getPlaceColor()
        polygon.zIndex = Int32(900 - Int(placeDetails.size ?? 0))
        polygon.fillColor = isGroundOverlayClicked2 ? placeDetails.getTransparentColor() : placeDetails.getNormalColor()
        polygon.isTappable = !isGroundOverlayClicked2
        return polygon
    }

    
    

    
    
    
    func handleCheckInSituation(for groundOverlay: GMSGroundOverlay) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else {return}

            //self.onGroundOverlayClick(groundOverlay)
            
            self.mapView(self.mapView!, didTap: groundOverlay)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                
                guard let self = self else {return}

                for (marker, placeDetails) in self.focusPolygonMarkers {
                    if placeDetails.placeKey == self.lastPlaceCreatedKey {
                        //self.onMarkerClick(marker)
                        let _ = self.mapView(self.mapView!, didTap: marker)
                    }
                }
                self.lastPlaceCreatedKey = ""
            }
        }
    }
   
    func polygonPlaceGroundOverlayClicked(placeDetails: PolygonPlaceDetails, overlay: GMSGroundOverlay) {
            blockMapDragging()

            placeViewModel.setFocusedListPolygon(places: placeDetails.places!)

            let polygonAssociated = associatedPolygons[overlay]
            overlay.isTappable = false
            
            if let polygon = polygonAssociated {
                polygon?.isTappable = false
            }

            var originalColor = ""
            if let strokeColorHex = placeDetails.dominantGroup?.strokeColorHex {
                originalColor = strokeColorHex.count > 7
                    ? String(strokeColorHex.dropFirst(3))
                    : strokeColorHex.replacingOccurrences(of: "#", with: "")
            }
            
            if !originalColor.isEmpty {
                originalColor = "#3D" + originalColor
            }

            let circleSpecs: (CLLocationCoordinate2D, Double)
            if placeDetails.isCircle() {
                if let size = placeDetails.size {
                    let coordinate = CLLocationCoordinate2D(latitude: placeDetails.coordinates!.latitude!, longitude: placeDetails.coordinates!.longitude!)
                    circleSpecs = (coordinate, size)
                } else {
                    let coordinate = CLLocationCoordinate2D(latitude: placeDetails.coordinates!.latitude!, longitude: placeDetails.coordinates!.longitude!)
                    circleSpecs = (coordinate, 0.0)
                }
            } else {
                var coordinates: [CLLocationCoordinate2D] = []
                for place in placeDetails.places ?? [] {
                    if let coord = place.coordinates {
                        let clCoordinate = CLLocationCoordinate2D(latitude: coord.latitude!, longitude: coord.longitude!)
                        coordinates.append(clCoordinate)
                    }
                }
                circleSpecs = CoordinatesUtil.minimumEnclosingCircle(polygonPoints: coordinates)
            }

            let radius = circleSpecs.1 * 1.50
            let circleCenter = circleSpecs.0
            circle = GMSCircle(position: circleCenter, radius: radius)
            circle?.strokeWidth = 1.0
            circle?.strokeColor = UIColor(hexString: originalColor, alpha: 0.3)
            circle?.fillColor = UIColor(hexString: originalColor, alpha: 0.3)
            circle?.isTappable = false
            circle?.map = mapView
            

            let zoomLevel = getZoomLevel(radius: radius, center: circleCenter)
            let cameraPosition = CLLocationCoordinate2D(
                latitude: circleCenter.latitude - pixelsToDegrees(pixels: 46, zoom: zoomLevel, center: circleCenter),
                longitude: circleCenter.longitude
            )

            CATransaction.begin()
            CATransaction.setAnimationDuration(1.0)
            CATransaction.setCompletionBlock {
                self.enableMapDragging()
                self.applyFocusCameraLock(center: circleCenter, radius: radius, entryZoom: zoomLevel, entryTarget: cameraPosition)
            }

            mapView?.animate(to: GMSCameraPosition.camera(withTarget: cameraPosition, zoom: zoomLevel))
            CATransaction.commit()
            moveSeekbarsUp()

            circle?.map = mapView
            for (key, value) in placeOverlays {
                if placeDetails != value {
                    key.map = nil //mapView
                    if let associatedPolygon = associatedPolygons[key], associatedPolygon != nil {
                        changePolygonTransparency(poly: associatedPolygon!, transparency: 0.94)
                        associatedPolygon!.isTappable = false
                    }
                    key.isTappable = false
                }
            }
            overlay.map = nil //mapView
    //        if let polygon = polygonAssociated {
    //            changePolygonTransparency(poly: polygon, transparency: 1.0)
    //        }
            
            if let polygon = polygonAssociated, polygon != nil {
                changePolygonTransparency(poly: polygon!, transparency: 1.0)
            }

            // Show polygon group cards (if needed)
            // showPolygonGroupCards(placeDetails: placeDetails)

            lastPlace = placeDetails
            lastOverlay = overlay
        
        

            // TODO: Uncomment if handling progress bars/cards
            // mapPolygonGroupCards.isHidden = false
            // mapPlacesPager.isHidden = false
        
            //Show Carousel View
            delegate?.isShow_OR_Hide_Carousel(isVisible: true)
            delegate?.selectedGroupMainPolyGone(place: placeDetails)

        }
    
    func removeGroundOverlayAndPolygon(place: PolygonPlaceDetails) {
    
            // Store overlays to be removed to avoid modifying the dictionary during iteration
            var overlaysToRemove: [GMSGroundOverlay] = []
            
            for (overlayCircle, overlayPlace) in placeOverlays {
                //print("place.placekey == \(place.placeKey)  and overlayPlace.placekey == \(overlayPlace.placeKey)")
                if overlayPlace.placeKey == place.placeKey {
                    // Remove the associated polygon from the map if it exists
                    if let polygonAssociated = associatedPolygons[overlayCircle] {
                        polygonAssociated?.map = nil // Remove the polygon from the map by setting its map to nil
                    }
                    
                    // Remove the overlay from t//overlayCircle.map = nil
                    overlayCircle.map = nil
                    
                    
                    // Prepare to remove this overlay from placeOverlays
                    overlaysToRemove.append(overlayCircle)
                    
                    // Remove the matching place from willBePlaceOverlays
                    willBePlaceOverLays.removeAll { $0.placeKey == place.placeKey }
                    break // Exit loop after finding the match
                }else{
                   // print("not matched")
                }
            }
            
            // Remove overlays from placeOverlays after iteration
            for overlay in overlaysToRemove {
                let removeplace = placeOverlays[overlay]
                //print("placeOverlays removed Item \(removeplace?.placeKey ?? "no item removed")")
                placeOverlays.removeValue(forKey: overlay)
            }
            
        
    }

    func getZoomLevel(radius: Double, center: CLLocationCoordinate2D) -> Float {
        // Ensure access to display metrics
        let screenWidthInPixels = UIScreen.main.nativeBounds.width
        
        let padding: Double = 1.24 // Match Android padding
        let equatorMetersPerPixelAtZoom0: Double = 156543.03392
        
        // Calculate the meters per pixel at the given latitude for zoom level 0
        let metersPerPixelAtZoom0 = equatorMetersPerPixelAtZoom0 * cos(center.latitude * .pi / 180)
        
        let expansion = 5.35 * radius * padding
        // Calculate the required meters per pixel for the given diameter to fit the screen width
        let requiredMetersPerPixel = expansion / screenWidthInPixels
        
        // Calculate the maximum zoom level
        let maxZoomLevel = Float(log2(metersPerPixelAtZoom0 / requiredMetersPerPixel))
        lastZoomLevel = Double(maxZoomLevel)

        return maxZoomLevel
    }
    

    
    func pixelsToDegrees(pixels: Int, zoom: Float, center: CLLocationCoordinate2D) -> Double {
            let metersPerPixel = 156543.03392 * cos(0.0.toRadians()) / pow(2.0, Double(zoom))
            
            // Deviation by equator
            let equatorMetersPerPixel = metersPerPixel * cos(center.latitude.toRadians())

            // Convert meters to degrees (latitude)
            let degreesPerPixel = equatorMetersPerPixel / 111320.0

            return Double(pixels) * degreesPerPixel
        }

    
    func moveSeekbarsUp() {
        //TODO: need to be fixed.
        /*
        let animator = UIViewPropertyAnimator(duration: 1.0, curve: .linear) {
            let value: CGFloat = 140
            if let layoutParamsL = leftSeekBar.superview?.layoutMargins, let layoutParamsR = rightSeekBar.superview?.layoutMargins {
                var newLayoutParamsL = layoutParamsL
                var newLayoutParamsR = layoutParamsR
                newLayoutParamsL.bottom = value
                newLayoutParamsR.bottom = value
                leftSeekBar.superview?.layoutMargins = newLayoutParamsL
                rightSeekBar.superview?.layoutMargins = newLayoutParamsR
            }
        }
        animator.startAnimation()
         */
    }
    
    func changePolygonTransparency(poly: GMSPolygon, transparency: Float) {
        let placeColor = poly.fillColor
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        placeColor!.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let newAlpha = alpha * CGFloat(1 - transparency)
        let transparentColor = UIColor(red: red, green: green, blue: blue, alpha: newAlpha)

        poly.fillColor = transparentColor
    }
    

    // Helper function to convert dp to px
    
    func dpToPx(_ dp: Int) -> CGFloat {
        return CGFloat(dp) * 1 //UIScreen.main.scale
    }
     
    func drawFocusedPlaceMarker(place: PolygonPlaceDetails, unique: Bool) {
        
        let markerView = UIView()
        //markerView.backgroundColor = .red
        markerView.frame = CGRect(x: 0, y: 0, width: dpToPx(unique ? 64 : 50), height: dpToPx(unique ? 64 : 50))
        //markerView.frame = CGRect(x: 0, y: 0, width: dpToPx(74), height: dpToPx(74))
        
        let imageContainer = UIView()
        //markerView.backgroundColor = .yellow

        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        //imageContainer.frame = markerView.bounds
        imageContainer.frame = CGRectMake(5, 5, 39, 39)
        markerView.addSubview(imageContainer)
        
         let scale: CGFloat = unique ? 0.95 : (tooCloseToAnotherMarker(place) ? 0.47 : 0.65)
        
        //let scale: CGFloat = unique ? 0.95 : (tooCloseToAnotherMarker(place) ? 0.40 : 0.56)
        
        let mImage = OrbisMapPlaceIconManager.shared.placeIcons[place.placeType]?.withRenderingMode(.alwaysTemplate)
        
        let bSize = CGSize(width: mImage!.size.width * scale, height: mImage!.size.height * scale)
        
        
        
        //let baseSize: CGFloat = dpToPx(64)
        let baseSize: CGFloat = dpToPx(52)

        let scaledSize: CGFloat = baseSize * scale
        
        let placeColor = UIColor(hexString: place.dominantGroup?.strokeColorHex ?? "#0000FF").cgColor
        
        // Background circle (Blue or place-specific color)
        let gradientDrawable = CAShapeLayer()
        gradientDrawable.path = UIBezierPath(ovalIn: CGRect(
            x: (baseSize - scaledSize) / 2,
            y: (baseSize - scaledSize) / 2,
            width: scaledSize,
            height: scaledSize
        )).cgPath
        gradientDrawable.fillColor = placeColor
        gradientDrawable.strokeColor = placeColor
        gradientDrawable.lineWidth = dpToPx(2)
        
        // Outlining circle (White border)
        if place.isFocusSelected {
            let strokeWidth: CGFloat = dpToPx(unique ? 5 : 4)
            let outliningCircle = CAShapeLayer()
            outliningCircle.path = UIBezierPath(ovalIn: CGRect(
                x: (baseSize - scaledSize - strokeWidth) / 2,
                y: (baseSize - scaledSize - strokeWidth) / 2,
                width: scaledSize + strokeWidth,
                height: scaledSize + strokeWidth
            )).cgPath
            
            
            outliningCircle.fillColor = UIColor.clear.cgColor
            outliningCircle.strokeColor = UIColor.white.cgColor
            outliningCircle.lineWidth = strokeWidth
            
            // Combine layers to mimic LayerDrawable in Android
            let combinedLayer = CALayer()
            combinedLayer.addSublayer(outliningCircle)
            combinedLayer.addSublayer(gradientDrawable)
            imageContainer.layer.addSublayer(combinedLayer)
            
        } else {
            imageContainer.layer.addSublayer(gradientDrawable)
        }
        
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.image = OrbisMapPlaceIconManager.shared.placeIcons[place.placeType]?.withRenderingMode(.alwaysTemplate)
        imageContainer.addSubview(imageView)
        
        
        
        NSLayoutConstraint.activate([
            
            imageContainer.centerXAnchor.constraint(equalTo: markerView.centerXAnchor),
            imageContainer.centerYAnchor.constraint(equalTo: markerView.centerYAnchor),
//            imageContainer.widthAnchor.constraint(equalToConstant: dpToPx(64)),
//            imageContainer.heightAnchor.constraint(equalToConstant: dpToPx(64)),
            
            imageContainer.widthAnchor.constraint(equalToConstant: dpToPx(52)),
            imageContainer.heightAnchor.constraint(equalToConstant: dpToPx(52)),
            
           
            imageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),
            //                imageView.widthAnchor.constraint(equalToConstant: dpToPx(32)),
            //                imageView.heightAnchor.constraint(equalToConstant: dpToPx(32))
            imageView.widthAnchor.constraint(equalToConstant: bSize.width/1.9),
            imageView.heightAnchor.constraint(equalToConstant: bSize.height/1.9)
            //bSize
        ])
        
        markerView.setNeedsLayout()
        markerView.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: markerView.bounds.size)
        let markerImage = renderer.image { context in
            markerView.layer.render(in: context.cgContext)
        }
        
        if markerImage.size == .zero {
            print("Error: markerImage rendering failed")
            return
        }
        
        let placeLocation = CLLocationCoordinate2D(latitude: place.coordinates?.latitude ?? 0, longitude: place.coordinates?.longitude ?? 0)
        let marker = GMSMarker()
        marker.position = placeLocation
        //marker.icon = markerImage
        marker.iconView = markerView
        marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        marker.map = mapView
        
        marker.userData = place
        
        AnimationsUtil.startBounceAnimation(for: markerView, placeDetails: place)
        focusPolygonMarkers[marker] = place
    }
    
    
    func applyRotationAnimation(to view: UIView) {
        UIView.animate(withDuration: 2.0,
                       delay: 0,
                       options: [.repeat, .curveLinear],
                       animations: {
                           view.transform = CGAffineTransform(rotationAngle: .pi)
                       }, completion: nil)
    }
    
        

    
    // Check if a place marker is too close to another marker
    func tooCloseToAnotherMarker(_ place: PolygonPlaceDetails) -> Bool {
        guard let mapView = mapView else { return false }
        let zoomLevel = lastZoomLevel //mapView.camera.zoom
        let metersPerPixel = 156543.03392 * cos((place.coordinates?.latitude!)! * .pi / 180) / pow(2.0, Double(zoomLevel))
        let epsilon = 41 * metersPerPixel // Assuming each marker is approximately 48 pixels wide
        
        for p in placeViewModel.polygonFocusedPlaces {
            if p.placeKey != place.placeKey && focusedTwoPlaceMarkerDistance(place1: place, place2: p) < epsilon {
                return true
            }
        }
        return false
    }
    // Calculate the distance between two markers
    func focusedTwoPlaceMarkerDistance(place1: PolygonPlaceDetails, place2: PolygonPlaceDetails) -> Double {
        let coordinate1 = CLLocation(latitude: (place1.coordinates?.latitude!)!, longitude: (place1.coordinates?.longitude!)!)
        let coordinate2 = CLLocation(latitude: (place2.coordinates?.latitude!)!, longitude: (place2.coordinates?.longitude!)!)
        return coordinate1.distance(from: coordinate2) // Distance in meters
    }

    
    func hideCheckInLoading() {
        //checkInLoadingExtra.alpha = 0.0
        //checkInLoadingContainer.isHidden = true
        //checkInProgressBar.progress = 0.0
        delegate?.mapManager(self, ishidden: true)
        placeViewModel.restartCheckInProgressBar()
    }
    
    func removePlaceOfMemory(place: PolygonPlaceDetails) {
        print("removePlaceOfMemory")
        // S0: find + mutate the shared arrays under the access queue (was bare-on-main -> raced the
        // queue's appends). cancelAnimation() stays on the caller (main) since it may touch timers/CA.
        let placeToRemove = placesAccessQueue.sync { () -> PolygonPlaceDetails? in
            self.places.first { $0.placeKey == place.placeKey }
        }
        guard let placeToRemove = placeToRemove else { return }
        placeToRemove.cancelAnimation()
        placesAccessQueue.sync {
            self.places.removeAll { $0.placeKey == placeToRemove.placeKey }
            if !placeToRemove.isCircle() {
                let placeKeysToRemove = placeToRemove.places!.compactMap { $0.placeKey }
                self.polygonPlacesKeys = self.polygonPlacesKeys.filter { !placeKeysToRemove.contains($0) }
            }
        }
    }


    func transformOverlayAndPolygonWithAnimation(fromPlace: inout PolygonPlaceDetails, toPlace: inout PolygonPlaceDetails) {
        fromPlace.cancelAnimation()
        fromPlace.computeSize()
        toPlace.computeSize()

        let localToPlace = toPlace // Create a local copy of `toPlace`

        let fromPoints = CoordinatesUtil.coordinatesToLatLng(fromPlace.polygonPoints!)
        var smoothedInitialPoints = CoordinatesUtil.chaikin(arr: fromPoints, num: 2)
        smoothedInitialPoints = CoordinatesUtil.bspline(poly: &smoothedInitialPoints)
        let toPoints = CoordinatesUtil.coordinatesToLatLng(localToPlace.polygonPoints!)
        var smoothedEndingPoints = CoordinatesUtil.chaikin(arr: toPoints, num: 2)
        smoothedEndingPoints = CoordinatesUtil.bspline(poly: &smoothedEndingPoints)

        smoothedInitialPoints = CoordinatesUtil.normalizePoints(points: smoothedInitialPoints, targetSize: smoothedEndingPoints.count)
        smoothedEndingPoints = CoordinatesUtil.normalizePoints(points: smoothedEndingPoints, targetSize: smoothedInitialPoints.count)

        smoothedInitialPoints = CoordinatesUtil.normalizeOrientation(polygon: smoothedInitialPoints)
        smoothedEndingPoints = CoordinatesUtil.normalizeOrientation(polygon: smoothedEndingPoints)

        let (initialRotated, endingRotated) = CoordinatesUtil.rotatePoints(fromPoints: smoothedInitialPoints, toPoints: smoothedEndingPoints)

        let groundOverlay = findOverlay(for: fromPlace)
        var polygon: GMSPolygon? = nil

        if let groundOverlay = groundOverlay {
            polygon = associatedPolygons[groundOverlay] ?? nil
        }

        if let groundOverlay = groundOverlay {
            if polygon == nil {
                let polygonOptions = GMSPolygon()
                let path = GMSMutablePath()
                for point in smoothedInitialPoints {
                    path.add(CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
                }
                polygonOptions.path = path
                polygonOptions.strokeWidth = 0.0
                polygonOptions.strokeColor = fromPlace.getPlaceColor()
                polygonOptions.fillColor = fromPlace.getNormalColor()
                polygonOptions.map = isGroundOverlayClicked2 ? nil : mapView!   // born hidden if a backend polygon-update lands mid-focus; reRenderPolygons re-shows on exit
                polygon = polygonOptions
            }

            let animator = UIViewPropertyAnimator(duration: 1.5, curve: .linear) {
                let t: CGFloat = 1.0 // Animation progress
                let intermediatePoints = CoordinatesUtil.interpolatePoints(fromPoints: initialRotated, toPoints: endingRotated, t: Float(t))
                let path = GMSMutablePath()
                for point in intermediatePoints {
                    path.add(CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
                }
                polygon?.path = path
            }
            animator.startAnimation()

            if localToPlace.isCircle(), let polygon = polygon {
                polygon.map = nil
            }

            associatedPolygons[groundOverlay] = polygon

            UIView.animate(withDuration: 1.5, animations: {
                if let coordinates = localToPlace.polygonCenter {
                    let location = CLLocationCoordinate2D(latitude: coordinates.latitude!, longitude: coordinates.longitude!)
                    groundOverlay.position = location
                }
            })

            // Commented block with escaping closure logic needs to avoid capturing `inout` parameters directly
            /*
            centerMoveAnim.addCompletion { _ in
                if let anim = AnimationsUtil.createPulseAnimation(for: groundOverlay, placeDetails: localToPlace) {
                    localToPlace.animator = anim
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        AnimationsUtil.startPulseAnimation(placeDetails: &localToPlace, valueAnimator: anim)
                    }
                }
            }
            */

            placeOverlays[groundOverlay] = localToPlace
            if let polygon = polygon {
                associatedOverlays[polygon] = groundOverlay
            }
        }

        toPlace = localToPlace // Assign the modified local copy back to the `inout` parameter
    }

    
    private func findOverlay(for place: PolygonPlaceDetails) -> GMSGroundOverlay? {
        for (overlay, overlayPlace) in placeOverlays {
            if overlayPlace.placeKey == place.placeKey {
                return overlay
            }
        }
        return nil
    }

    // Endless-exploration ceiling: cached overlays are never viewport-destroyed, so a long session
    // grows one rendered image per territory visited. Past the cap, destroy the farthest OFF-SCREEN
    // overlays only — their place records stay in `places`, so the sweep transparently re-creates
    // them (images served from the SDWebImage cache) if the user ever returns.
    private func evictDistantOverlaysIfNeeded() {
        let hardCap = 400
        let evictTo = 300
        guard placeOverlays.count > hardCap, let mapView = mapView else { return }

        let center = mapView.camera.target
        let region = mapView.projection.visibleRegion()
        var viewport = GMSCoordinateBounds(coordinate: region.nearLeft, coordinate: region.nearRight)
        viewport = viewport.includingCoordinate(region.farLeft).includingCoordinate(region.farRight)

        let candidates = placeOverlays
            .compactMap { (overlay, place) -> (GMSGroundOverlay, PolygonPlaceDetails, CLLocationDistance)? in
                guard let ctr = place.polygonCenter ?? place.coordinates,
                      let lat = ctr.latitude, let lng = ctr.longitude else { return nil }
                let anchor = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                guard !viewport.contains(anchor) else { return nil }   // never evict visible ones
                return (overlay, place, GMSGeometryDistance(center, anchor))
            }
            .sorted { $0.2 > $1.2 }

        for (overlay, place, _) in candidates.prefix(max(0, placeOverlays.count - evictTo)) {
            if let polygon = associatedPolygons[overlay] ?? nil {
                polygon.map = nil
                associatedOverlays.removeValue(forKey: polygon)
            }
            associatedPolygons.removeValue(forKey: overlay)
            overlay.map = nil
            placeOverlays.removeValue(forKey: overlay)
            willBePlaceOverLays.removeAll { $0.placeKey == place.placeKey }
        }
    }

    // Detach/re-attach a cached overlay (+ its polygon) instead of destroying it. Identity-checked
    // so per-sweep re-application of the same state is a no-op. Main-thread only (GMS).
    private func setOverlayHidden(place: PolygonPlaceDetails, hidden: Bool) {
        guard let overlay = findOverlay(for: place) else { return }
        let overlayTarget: GMSMapView? = hidden ? nil : mapView
        if overlay.map !== overlayTarget { overlay.map = overlayTarget }
        if let polygon = associatedPolygons[overlay] ?? nil {
            let polygonTarget: GMSMapView? = (hidden || isGroundOverlayClicked2) ? nil : mapView
            if polygon.map !== polygonTarget { polygon.map = polygonTarget }
        }
    }

    func replaceOldPlaceForNewPlaceInMemory(oldPlace: PolygonPlaceDetails, newPlace: PolygonPlaceDetails) {
        removePlaceOfMemory(place: oldPlace)
        addPlaceToMemory(place: newPlace)
        willBePlaceOverLays.append(newPlace)
    }
    
    
    func removeIncludedPlaces(newPlace: PolygonPlaceDetails) {
        print("removeIncludedPlaces")
        if let placesArray = newPlace.places {
            for place in placesArray {
                if place.placeKey != newPlace.placeKey {
                    removeGroundOverlayAndPolygon(place: place)
                }
            }
        }
    }

    // A sub-place belongs to exactly one territory server-side, so a freshly fetched record whose
    // sub-place keys intersect an in-memory record under a DIFFERENT placeKey means the old record
    // predates a backend merge/split; left drawn, it renders a second same-tribe avatar fused into
    // the same blob. The designed cleanup (observeUpdatePolygon/-Circle -> removeIncludedPlaces)
    // has no live producer (updatePolygon/updateCircle are never called), so reconcile on the add
    // path instead. Main-thread only (touches overlays + willBePlaceOverLays).
    func removeSupersededPlaces(by newPlace: PolygonPlaceDetails) {
        if isGroundOverlayClicked2 { return }   // in focus: freeze redraws (same idiom as willMove)

        guard let newSubKeys = newPlace.places?.compactMap({ $0.placeKey }), !newSubKeys.isEmpty else { return }
        let newKeySet = Set(newSubKeys)

        let stalePlaces = placesAccessQueue.sync {
            self.places.filter { p in
                guard let key = p.placeKey, key != newPlace.placeKey else { return false }
                guard let subKeys = p.places?.compactMap({ $0.placeKey }) else { return false }
                return subKeys.contains(where: newKeySet.contains)
            }
        }

        for stale in stalePlaces {
            // Strip willBePlaceOverLays before removing the overlay: it is the use-time guard for
            // an in-flight image download, and removeGroundOverlayAndPolygon only clears it when an
            // overlay already exists — clearing it here stops a stale completion from re-adding one.
            willBePlaceOverLays.removeAll { $0.placeKey == stale.placeKey }
            removeGroundOverlayAndPolygon(place: stale)
            removePlaceOfMemory(place: stale)
        }
    }
    
    func disappearCircleAnimation(place: PolygonPlaceDetails) {
        print("remove overlays")
        if let groundOverlay = findOverlay(for: place) {
            //print("place/circle to disappear: \(String(describing: place.name))")
            place.cancelAnimation()
            
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                self.removeGroundOverlayAndPolygon(place: place)
                self.removePlaceOfMemory(place: place)
            }
            
             let anim = AnimationsUtil.createPulseAnimationCeaseExist(for: groundOverlay, on: mapView!)
                // Add animation to a UIView or manually handle animation completion logic if needed
                groundOverlay.opacity = 0 // Example of changing a property for disappearance
            
            
            CATransaction.commit()
            
        } else {
            //print("place/circle to disappear (exclusive in memory): \(String(describing: place.name))")
            willBePlaceOverLays.removeAll { $0.placeKey == place.placeKey }
            removeGroundOverlayAndPolygon(place: place)
            removePlaceOfMemory(place: place)
        }
    }

    func updateCircleAnimation(oldPlace: inout PolygonPlaceDetails, newPlace: inout PolygonPlaceDetails) {
        if let groundOverlay = findOverlay(for: oldPlace) {
            // Prep
            oldPlace.computeSize()
            newPlace.computeSize()
            
            if let oldSize = oldPlace.size, let newSize = newPlace.size, abs(oldSize - newSize) > 15 {
                var localNewPlace = newPlace // Create a local copy of `newPlace`

                localNewPlace.animator = oldPlace.animator
                localNewPlace.previousSize = oldPlace.size

                oldPlace.cancelAnimation()

                willBePlaceOverLays.removeAll { $0.placeKey == oldPlace.placeKey }
                replaceOldPlaceForNewPlaceInMemory(oldPlace: oldPlace, newPlace: localNewPlace)

                //print("place/circle to animate: \(String(describing: oldPlace.name))")
                let anim = AnimationsUtil.createPulseAnimationSlowDiminish(groundOverlay: groundOverlay, placeDetails: &localNewPlace)
                CATransaction.begin()
                CATransaction.setCompletionBlock {
                    if let animator = localNewPlace.animator {
                        animator.startAnimation()
                    }
                }
                groundOverlay.opacity = 0 // Example change
                CATransaction.commit()

                newPlace = localNewPlace // Assign the modified copy back to the original `inout` parameter
            }
        } else {
           // print("place/circle to update exclusive in memory: \(String(describing: oldPlace.name))")
            replaceOldPlaceForNewPlaceInMemory(oldPlace: oldPlace, newPlace: newPlace)
            willBePlaceOverLays.removeAll { $0.placeKey == newPlace.placeKey }
        }
    }

    // Perf S1 dispatcher. Flag OFF (default) = byte-for-byte the tested S0 path; ON = off-main geometry.
    // Sole caller is the idle debounce (already on main), so no extra hop. See spec §5 E3.
    func updateGroundOverlayInBounds() {
        guard AppValues.offMainGeometryEnabled else {
            updateGroundOverlayInBoundsS0()
            return
        }
        updateGroundOverlayInBoundsS1()
    }

    private func updateGroundOverlayInBoundsS0()  {
        guard let googleMap = mapView else { return }

        // S0: read the viewport ONCE per idle. The camera is fixed for this whole pass (called from
        // idleAt after the camera stopped), so recomputing projection.visibleRegion() + getRadius()
        // per place was redundant. Hoist both here and pass them down.
        let visibleRegion = googleMap.projection.visibleRegion()
        var bounds = GMSCoordinateBounds(coordinate: visibleRegion.nearLeft, coordinate: visibleRegion.nearRight)
        bounds = bounds.includingCoordinate(visibleRegion.farLeft)
        bounds = bounds.includingCoordinate(visibleRegion.farRight)
        let visibleRadius = googleMap.getRadius()

        // S0: snapshot `places` under the access queue so we don't iterate the shared array on main
        // while addPlaceToMemory appends to it off the same queue (closes the places data race).
        // PolygonPlaceDetails is a struct, so this is a value copy — safe to iterate off-queue.
        let placesSnapshot = placesAccessQueue.sync { self.places }
        for place in placesSnapshot {
            addGroundOverlayBasedOnBounds(place: place, precomputedBounds: bounds, precomputedRadius: visibleRadius)
        }

        lastOverlayUpdatedTime = Int(Date().timeIntervalSince1970)
        evictDistantOverlaysIfNeeded()
    }

    func distance(latLng: CLLocationCoordinate2D) -> Float {
        if let lastLocation = lastLocation {
            return Float(GMSGeometryDistance(lastLocation, latLng))
        } else {
            return 0.0
        }
    }
    
    func removeFocusedPlaceView() {
        clearFocusCameraLock()
        if !isGroundOverlayClicked {
            
            if let circle = circle {
                circle.map = nil // Remove the circle from the map
            }
            //TODO: need to fix it later
           // mapTwoCards.isHidden = true
           // mapPolygonGroupCards.isHidden = true
           // mapPlacesPager.isHidden = true
            
            //To Hide Carousel View
            delegate?.isShow_OR_Hide_Carousel(isVisible: false)

            if let zoomLevel = mapView?.camera.zoom {
                handleZoomChange(newZoom: zoomLevel)
            }
            isGroundOverlayClicked2 = false
        }else if timeDelayBoolForGroundOverlay {
            //print("removeFocusedPlaceView not called")
            if let circle = circle {
                circle.map = nil // Remove the circle from the map
            }
            //TODO: need to fix it later
           // mapTwoCards.isHidden = true
           // mapPolygonGroupCards.isHidden = true
           // mapPlacesPager.isHidden = true
            
            //To Hide Carousel View
            delegate?.isShow_OR_Hide_Carousel(isVisible: false)

            if let zoomLevel = mapView?.camera.zoom {
                handleZoomChange(newZoom: zoomLevel)
            }
            
            isGroundOverlayClicked2 = false
            timeDelayBoolForGroundOverlay = false
        }
    }
    
    func handleZoomChange(newZoom: Float) {
        currentZoom = newZoom
    }

    func centerMapOnLocation(location: CLLocation?, title: String?, displayMarker: Bool) {
       
        if let location = location {
            mLastLocation = location
            Constants.location = location
            
            placeViewModel.locationSharedOrSelected = true
            placeViewModel.setLastCitySelected(loc: location)
            saveLastCitySelectedOnSharedPreferences()
            
            if myLocationMarker != nil {
                myLocationMarker?.map = nil // Remove the existing marker from the map
            }
            
            let userLocation = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            
            if displayMarker {
                myLocationMarker = GMSMarker(position: userLocation) 
                //myLocationMarker = GMSMarker(position: UserSessionManager.shared.userCurrentLocation!)
                myLocationMarker?.title = title
                
                let userMarkerIconView = UIImageView(image: #imageLiteral(resourceName: "user-locaiton-marker-ic"))
                myLocationMarker?.iconView = userMarkerIconView // Placeholder or change as needed

                myLocationMarker?.map = mapView
            }
            
            if lastLocation == nil {
                lastLocation = userLocation
            }
            
            myLocationMarker?.infoWindowAnchor = CGPoint(x: 0.5, y: 0.5)
           // print("animCamera: centerOnMap")
            mapView?.animate(to: GMSCameraPosition.camera(withTarget: userLocation, zoom: defaultZoom))
            
           // binding.myLocationFab.isHidden = true
            
            if !loadedOverlay {
                bindingloading = true
                delegate?.mapManagerShowOrbisLoader(isShow: true)
                placeViewModel.findPolygonPlacesForMap(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            }
        }
    }

    func bitmapDescriptorFromVector(context: UIViewController, resourceId: String) -> UIImage? {
        guard let image = UIImage(named: resourceId) else {
            return nil
        }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resultImage
    }
    
    func displayLocationMarker() {
        guard let lastLocation = mLastLocation else { return }
        
        // Remove existing location marker if it exists
        if myLocationMarker != nil {
            myLocationMarker?.map = nil
        }
        
        // Create a user location coordinate
        let userLocation = CLLocationCoordinate2D(latitude: lastLocation.coordinate.latitude, longitude: lastLocation.coordinate.longitude)
        
        // Check permissions and if no city is selected
        if areLocationAllowedPermissions && lastCitySelected.isEmpty {
            
            if UserSessionManager.shared.userCurrentLocation == nil {
                return
            }
            // Add a marker to the map at the user's location
            myLocationMarker = GMSMarker(position: UserSessionManager.shared.userCurrentLocation!)
            myLocationMarker?.title = "Your Location"
            
            // Set a custom icon from a vector image if available
            let userMarkerIconView = UIImageView(image: #imageLiteral(resourceName: "user-locaiton-marker-ic"))
            myLocationMarker?.iconView = userMarkerIconView
            myLocationMarker?.map = mapView
            
        }
    }

    // precomputePlacesImageDrawables removed: it fired one downloadURL RPC + full download per
    // sub-place image of every visible territory on EVERY pan start, through the cache-less raw
    // downloader — and nothing on iOS consumed those images (focus markers render bundled
    // place-type icons only). Pure network storm.

    func reRenderPolygons() {
        //print("cameraMoving: Re-showing polygons")
        
        // Remove existing markers from the map
        for marker in focusPolygonMarkers.keys {
            marker.map = nil
        }
        focusPolygonMarkers.removeAll()
        placeViewModel.clearFocusedPolygonPlaces()

        if !polygonFocusingFirstTime {
            #if DEBUG
            // TEMP dup diagnostic (remove after root-causing). If focus-exit re-render re-shows more
            // than one overlay per placeKey, the dup lives in placeOverlays as two entries.
            let _keys = placeOverlays.values.compactMap { $0.placeKey }
            let _dups = Dictionary(grouping: _keys, by: { $0 }).filter { $0.value.count > 1 }.mapValues { $0.count }
            if !_dups.isEmpty { print("🟥DUP-RERENDER placeOverlays has duplicate placeKeys: \(_dups)") }
            #endif
            // Adjust accordingly if `moveSeekbarsDown()` affects visuals
            //moveSeekbarsDown() // Add similar behavior if needed

            // Iterate through overlays and re-render polygons and overlays
            for overlay in placeOverlays.keys {
                if let polygonAssociated = associatedPolygons[overlay],
                   let dominantGroup = placeOverlays[overlay]?.dominantGroup {
                    
                    // Parse the color and set alpha similar to Android implementation
                    let placeColor = UIColor(hexString: dominantGroup.strokeColorHex!)
                    let alpha: CGFloat = placeColor.cgColor.alpha
                    let red = placeColor.cgColor.components?[0] ?? 0
                    let green = placeColor.cgColor.components?[1] ?? 0
                    let blue = placeColor.cgColor.components?[2] ?? 0
                    
                    // Create new color with adjusted alpha (similar to Android implementation)
                    let adjustedAlpha = alpha * 0.35
                    let normalColor = UIColor(red: red, green: green, blue: blue, alpha: adjustedAlpha)
                    
                    // Set polygon properties similar to Android
                    polygonAssociated?.isTappable = true
                    polygonAssociated?.map = mapView // Re-show the polygon on the map
                    polygonAssociated?.fillColor = normalColor
                }
                
                // Re-show overlay on the map and make it tappable
                overlay.isTappable = true
                overlay.map = mapView
            }
        }
        polygonFocusingFirstTime = true
    }
    
    func isExist(placeKey: String) -> PolygonPlaceDetails? {
        var existingPlace: PolygonPlaceDetails? = nil
        for place in placeOverlays.values {
            if place.placeKey == placeKey {
                existingPlace = place
                break
            }
        }
        if existingPlace == nil {
            existingPlace = isSubPlaceExist(placeKey: placeKey)
        }
        return existingPlace
    }

    func isSubPlaceExist(placeKey: String) -> PolygonPlaceDetails? {
        for place in placeOverlays.values {
            if let subPlaces = place.places {
                for subPlace in subPlaces {
                    if subPlace.placeKey == placeKey {
                        // Return the parent place instead of the subPlace
                        return place
                    }
                }
            }
        }
        return nil
    }

    
    private func applyTransparency(distance: Float) {
        print("distanceTrans: \(distance)")
        
        for (overlay, placeDetail) in placeOverlays {
            print("distanceTrans: touch \(placeDetail.touch)")
            let transparency = calculateTransparency(touch: placeDetail.touch, distance: distance, size: placeDetail.size!)
            overlay.opacity = 1.0 - transparency // Set opacity based on calculated
        }
    }

    private func calculateTransparency(touch: Bool, distance: Float, size: Double) -> Float {
        guard touch else {
            return 0.0
        }
        
        switch distance {
        case 500.0...:
            return CoordinatesUtil.getTransparencyForDistanceAbove500(size: size)
        case 200.0..<500.0:
            return CoordinatesUtil.getTransparencyForDistanceBetween200And500(size: size)
        case 100.0..<200.0:
            return CoordinatesUtil.getTransparencyForDistanceBetween100And200(size: size)
        case 50.0..<100.0:
            return CoordinatesUtil.getTransparencyForDistanceBetween50And100(size: size)
        default:
            return CoordinatesUtil.getTransparencyForDistanceBelow50(size: size)
        }
    }
    private func calculateTouches() {
        for overlay in placeOverlays.keys {
            if var placeDetail = placeOverlays[overlay] {
                placeDetail.touch = isPlaceMarkerTouchesOther(placeMarker: placeDetail)
                print("touching: \(placeDetail.touch)")
                placeOverlays[overlay] = placeDetail // Update the dictionary with the modified placeDetail
            }
        }
    }

    func isPlaceMarkerTouchesOther(placeMarker: PolygonPlaceDetails) -> Bool {
        for (_, otherPlaceDetail) in placeOverlays {
            if otherPlaceDetail.placeKey != placeMarker.placeKey {
                if isTwoPlaceTouchesOther(p1: placeMarker, p2: otherPlaceDetail) {
                    return true
                }
            }
        }
        return false
    }

    func isTwoPlaceTouchesOther(p1: PolygonPlaceDetails, p2: PolygonPlaceDetails) -> Bool {
        let distance = twoPlaceMarkerDistance(m1: p1, m2: p2)
        let r1 = p1.size ?? 0.0
        let r2 = p2.size ?? 0.0
        return distance * 1000 < (r1 + r2)
    }

    func twoPlaceMarkerDistance(m1: PolygonPlaceDetails, m2: PolygonPlaceDetails) -> Double {
        return CoordinatesUtil.overlaysDistance(
            lat1: m1.coordinates?.latitude ?? 0.0,
            lat2: m2.coordinates?.latitude ?? 0.0,
            lon1: m1.coordinates?.longitude ?? 0.0,
            lon2: m2.coordinates?.longitude ?? 0.0,
            el1: 0.0,
            el2: 0.0
        )
    }

    func findOldPlaceForPolygon(newPlace: PolygonPlaceDetails) -> PolygonPlaceDetails? {
        let snapshot = placesAccessQueue.sync { self.places }   // S0: guarded read of the shared array
        for oldPlace in snapshot {
            if subPlacesContainOldSubPlaces(newPlaces: newPlace.places!, oldPlaces: oldPlace.places!) {
                return oldPlace
            }
        }
        return nil
    }

    func subPlacesContainOldSubPlaces(newPlaces: [PolygonPlaceDetails], oldPlaces: [PolygonPlaceDetails]) -> Bool {
        let newPlaceKeys = Set(newPlaces.map { $0.placeKey })
        let oldPlaceKeys = Set(oldPlaces.map { $0.placeKey })
        
        for oldPlaceKey in oldPlaceKeys {
            if newPlaceKeys.contains(oldPlaceKey) {
                return true
            }
        }
        return false
    }

    func startCheckInLoading() {
        
        // Show the loading container
//        checkInLoadingContainer.isHidden = false
//        checkInLoadingExtra.alpha = 0.0  // below text line
//        checkInProgressBar.progress = 0
        delegate?.mapManager(self, progress: 0.0)

        placeViewModel.restartCheckInProgressBar()

        blockMapDragging()
        placeViewModel.clearMapPolygonPlaces()
        cancelAllCreationJobs()
        bindingloading = false
        delegate?.mapManagerShowOrbisLoader(isShow: false)
        removeAllGroundOverlaysAndPolygons()

        // Observe check-in progress using Combine
        placeViewModel.$checkInProgress
            .receive(on: DispatchQueue.main) // Ensure UI updates happen on the main thread
            .sink { [weak self] progress in
                guard let self = self, !self.checkInCompleted else { return }
                
                self.removeAllGroundOverlaysAndPolygons()
                
                delegate?.mapManager(self, progress: Float(progress))
                
                /*
                UIView.animate(withDuration: 0.3) {
                    self.checkInProgressBar.setProgress(Float(progress) / 100.0, animated: true)
                }
                
                if progress >= 85 && progress < 100 {
                    UIView.animate(withDuration: 0.25) {
                        self.checkInLoadingExtra.alpha = 1.0
                    }
                }
                 */
            }
            .store(in: &cancellables)
        
        // Start check-in loading process
        Task {
            await self.placeViewModel.startCheckInLoading()
        }
         
         
    }
    
    func applyFocusCameraLock(center: CLLocationCoordinate2D, radius: Double, entryZoom: Float, entryTarget: CLLocationCoordinate2D) {
        guard let mapView = mapView else { return }
        savedMinZoom = mapView.minZoom
        savedMaxZoom = mapView.maxZoom
        let ne = GMSGeometryOffset(center, radius * 1.41421356, 45.0)
        let sw = GMSGeometryOffset(center, radius * 1.41421356, 225.0)
        mapView.cameraTargetBounds = GMSCoordinateBounds(coordinate: sw, coordinate: ne)
        mapView.setMinZoom(entryZoom, maxZoom: savedMaxZoom)
        focusLockCameraPosition = GMSCameraPosition.camera(withTarget: entryTarget, zoom: entryZoom)
    }

    func clearFocusCameraLock() {
        guard let mapView = mapView else { return }
        focusLockCameraPosition = nil
        mapView.cameraTargetBounds = nil
        mapView.setMinZoom(savedMinZoom, maxZoom: savedMaxZoom)
    }

    // Called on camera idle while in focus mode: if the user dragged off the lock view and let go,
    // animate back. Zoom-ins are preserved (min zoom already stops zoom-outs below the entry zoom).
    private func snapBackToFocusLockIfNeeded(position: GMSCameraPosition) {
        guard let lock = focusLockCameraPosition, let mapView = mapView else { return }
        let distance = GMSGeometryDistance(position.target, lock.target)
        guard distance > 10 else { return }   // settled on the lock view — nothing to do
        mapView.animate(to: GMSCameraPosition.camera(withTarget: lock.target,
                                                     zoom: max(position.zoom, lock.zoom)))
    }

    // Explicit focus exit (Android onMapPlacesBack); no-op during the entry fly-to.
    func exitFocusMode() {
        if isFocusCirclecalled { return }
        isGroundOverlayClicked = false
        reRenderPolygons()
        removeFocusedPlaceView()
        enableMapDragging()
    }

    func blockMapDragging() {
        self.delegate?.isEnableMapDragging(isEnabled: false)
    }
    
    func enableMapDragging() {
        self.delegate?.isEnableMapDragging(isEnabled: true)
    }
    
    func updatingMap()  {
        
        if (Constants.lastCheckinPlace != nil && Constants.lastCheckInPolygonCoordinateKey != nil && !placeSheetCheckIn){
            let newPlace = Constants.lastCheckinPlace
            let chekInCoordkey = Constants.lastCheckInPolygonCoordinateKey
            Constants.lastCheckinPlace = nil
            Constants.lastCheckInPolygonCoordinateKey = nil
            timeDelayBoolForGroundOverlay = true
            reRenderPolygons()
            removeFocusedPlaceView()
            isFocusCirclecalled = true
            if let mapView = self.mapView {
                let cameraPosition = mapView.camera
                self.mapView(self.mapView!, idleAt: cameraPosition)
            }
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Perf S1: off-main polygon geometry (OperationViking_Perf5_S1_SPEC.md)

// Value objects crossing the background→main boundary. @unchecked Sendable: the only reachable
// reference-typed field (PolygonPlaceDetails.animator) is nil in transit (first set in Phase C),
// and GMSCoordinateBounds is immutable after construction — no shared mutable state crosses.
private struct PlaceGeoInput: @unchecked Sendable {
    let place: PolygonPlaceDetails
    let placeKey: String
    let isCircle: Bool
    let polygonPoints: [Coordinates]
    let coordinate: CLLocationCoordinate2D?
    let size: Double?
    init(_ p: PolygonPlaceDetails) {
        self.place = p
        self.placeKey = p.placeKey ?? ""
        self.isCircle = p.isCircle()
        self.polygonPoints = p.polygonPoints ?? []
        self.coordinate = p.coordinates?.toCLLocationCoordinate2D()
        self.size = p.size
    }
}

private struct Viewport: @unchecked Sendable {
    let bounds: GMSCoordinateBounds   // frozen immutable corner pair; .contains is pure arithmetic
    let radius: CLLocationDistance
    let factor: CGFloat
    let existingOverlayKeys: Set<String>   // placeKeys drawn or in flight at sweep start — skip recompute
}

private struct PolygonComputation: @unchecked Sendable {
    let place: PolygonPlaceDetails
    let smoothed: [CLLocationCoordinate2D]
    let centroid: CLLocationCoordinate2D
    let size: Double
}

private enum PlaceOutcome: @unchecked Sendable {
    case create(PolygonComputation)           // circles too: empty `smoothed`, Phase C attaches overlay only
    case show(PolygonPlaceDetails)            // overlay exists (maybe detached by an earlier hide) — ensure attached
    case hide(PolygonPlaceDetails)            // zoom size-criteria fail — DETACH but keep the cached overlay
    case none                                 // no overlay and off-screen, or in flight — nothing to do
}

// Cached loader for map overlay images. Two layers the raw-downloader path lacked:
// 1) memoizes the Firebase downloadURL RPC per storage path (was a network round-trip per load),
// 2) loads bytes via SDWebImageManager, which reads/writes the shared memory+disk cache —
//    SDWebImageDownloader alone never touches that cache, so every overlay re-creation
//    re-downloaded its image from the network.
// Completion always delivered on main. Thread-safe (NSCache; SDWebImage APIs are thread-safe).
enum MapImageLoader {
    private static let urlCache = NSCache<NSString, NSURL>()

    static func load(storagePath: String, completion: @escaping (UIImage?) -> Void) {
        resolveURL(storagePath: storagePath) { url in
            guard let url else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            SDWebImageManager.shared.loadImage(with: url, options: [.retryFailed, .continueInBackground], progress: nil) { image, _, error, _, finished, _ in
                // Treat an error as terminal even when finished is false (e.g. cancellation) —
                // otherwise the completion never fires and the caller's in-flight bookkeeping
                // (willBePlaceOverLays entry, loader counter, awaiting continuation) leaks forever.
                guard finished || error != nil else { return }
                DispatchQueue.main.async { completion(image) }
            }
        }
    }

    private static func resolveURL(storagePath: String, completion: @escaping (URL?) -> Void) {
        if let cached = urlCache.object(forKey: storagePath as NSString) {
            completion(cached as URL)
            return
        }
        Storage.storage().reference(withPath: storagePath).downloadURL { url, _ in
            if let url { urlCache.setObject(url as NSURL, forKey: storagePath as NSString) }
            completion(url)
        }
    }
}

extension MapManager {

    #if DEBUG
    fileprivate func assertMain() {
        assert(Thread.isMainThread, "S1 generation token / registry touched off main")
    }
    #else
    fileprivate func assertMain() {}
    #endif

    // Phase B — pure, static, race-free. Branch structure mirrors S0 addGroundOverlayBasedOnBounds.
    fileprivate static func classifyAndCompute(_ p: PlaceGeoInput, _ v: Viewport) -> PlaceOutcome {
        let size = p.isCircle ? p.size : CoordinatesUtil.calculatePolygonRadius(coord: p.polygonPoints)

        var inBounds = false
        if !p.isCircle {
            // Center first — a territory straddling the viewport edge can have every 100th
            // sampled vertex off-screen while its body is visible.
            if let ctr = p.place.polygonCenter, let lat = ctr.latitude, let lng = ctr.longitude,
               v.bounds.contains(CLLocationCoordinate2D(latitude: lat, longitude: lng)) {
                inBounds = true
            } else {
                for i in stride(from: 0, to: p.polygonPoints.count, by: 100)
                where v.bounds.contains(p.polygonPoints[i].toCLLocationCoordinate2D()) {
                    inBounds = true; break
                }
            }
        } else if let c = p.coordinate {
            inBounds = v.bounds.contains(c)
        }

        // Overlays are CACHED GMS objects now, never destroyed for viewport/zoom reasons: destroying
        // and re-creating on every pan-back caused the ~1s vanish-then-reload blink. Zoom hides
        // detach (map=nil) and later re-attach the same overlay instantly; out-of-bounds overlays
        // just stay attached (GMS culls off-screen geometry itself).
        let meets = (v.radius / (size ?? 1.0)) < v.factor
        guard meets else { return .hide(p.place) }
        // Overlay already drawn or in flight: ensure it's attached (may have been zoom-hidden).
        guard !v.existingOverlayKeys.contains(p.placeKey) else { return .show(p.place) }
        // No overlay yet and off-screen: don't build one.
        guard inBounds else { return .none }

        var place = p.place
        place.computeSize()

        if p.isCircle {
            // Circles carry no polygon geometry; Phase C attaches the image overlay only. Without
            // this branch a circle that scrolled out (removed) was never re-created by the sweep.
            let center = p.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
            return .create(PolygonComputation(place: place, smoothed: [], centroid: center, size: place.size ?? 0))
        }

        var smoothed = CoordinatesUtil.chaikin(arr: p.polygonPoints.toCLLocationCoordinate2DArray(), num: 2)
        smoothed = CoordinatesUtil.bspline(poly: &smoothed)
        let centroid = CoordinatesUtil.calculateCentroid(points: smoothed)
        return .create(PolygonComputation(place: place, smoothed: smoothed, centroid: centroid, size: place.size ?? 0))
    }

    // Phase A — main. Reuses the S0 viewport hoist + placesAccessQueue snapshot; bumps epoch; launches Phase B.
    func updateGroundOverlayInBoundsS1() {
        assertMain()
        guard let map = mapView else { return }

        let region = map.projection.visibleRegion()
        var b = GMSCoordinateBounds(coordinate: region.nearLeft, coordinate: region.nearRight)
        b = b.includingCoordinate(region.farLeft).includingCoordinate(region.farRight)
        let viewport = Viewport(bounds: b, radius: map.getRadius(), factor: AppValues.markersVisibilityFactor,
                                existingOverlayKeys: Set(willBePlaceOverLays.compactMap { $0.placeKey }))
        let inputs = placesAccessQueue.sync { self.places }.map(PlaceGeoInput.init)

        // NOTE: no generation bump here. The epoch is now a TEARDOWN token (bumped only by
        // cancelAllCreationJobs — city change / check-in reset). Bumping per sweep made every new
        // sweep discard the previous sweep's in-flight image attaches, so territories could only
        // land when panning paused; with cached overlays a cross-sweep attach is valid work
        // (idempotency is enforced by the willBePlaceOverLays/findOverlay guards on main).
        let generation = currentGeneration
        idleTask?.cancel()   // still cancels the superseded sweep's Phase B compute
        idleTask = Task(priority: .userInitiated) { [weak self, generation, viewport, inputs] in
            guard let self else { return }
            var outcomes: [PlaceOutcome] = []
            outcomes.reserveCapacity(inputs.count)
            for input in inputs {
                if Task.isCancelled { return }
                outcomes.append(MapManager.classifyAndCompute(input, viewport))
            }
            if Task.isCancelled { return }
            await self.applyOutcomes(outcomes, generation: generation)
        }
    }

    // Phase C — main apply, epoch-guarded. Stale (panned-past / torn-down) sweeps drop, attach nothing.
    @MainActor
    fileprivate func applyOutcomes(_ outcomes: [PlaceOutcome], generation: UInt64) {
        guard generation == currentGeneration, mapView != nil else { return }
        let now = Int(Date().timeIntervalSince1970)
        for o in outcomes {
            switch o {
            case .create(let c):
                guard !willBePlaceOverLays.contains(where: { $0.placeKey == c.place.placeKey }) else { continue }
                willBePlaceOverLays.append(c.place)   // atomic on main with the check above — no await between
                attachComputedPolygon(c, generation: generation)
            case .show(let p):
                setOverlayHidden(place: p, hidden: false)
            case .hide(let p):
                setOverlayHidden(place: p, hidden: true)
            case .none:
                break
            }
        }
        lastOverlayUpdatedTime = now
        evictDistantOverlaysIfNeeded()
        checkCenterPlusNearTribe()
    }

    // Phase C attach + cancellable image bridge — reproduces the S0 onResourceLoaded body, provably on main.
    @MainActor
    fileprivate func attachComputedPolygon(_ c: PolygonComputation, generation: UInt64) {
        // Circles have no polygon geometry (empty smoothed) — image overlay only, matching S0.
        let polygon: GMSPolygon? = c.place.isCircle() ? nil : createPolygon(for: c.place, smoothedPoints: c.smoothed)   // GMS build on main
        let diameter = CGFloat(c.size * 2.0)
        let center = CLLocationCoordinate2D(
            latitude: c.place.polygonCenter?.latitude ?? 0,
            longitude: c.place.polygonCenter?.longitude ?? 0)
        let isCheckIn = c.place.places?.contains { $0.placeKey == lastPlaceCreatedKey } ?? false
        let clicked = isGroundOverlayClicked2
        let pts = c.place.polygonPoints ?? []

        overlayLoadDidStart()
        Task { [weak self] in
            guard let self else { return }
            let image = try? await self.loadGroupImage(imageName: c.place.dominantGroup?.imageName ?? "")
            await MainActor.run { [weak self] in
                guard let self else { return }
                defer { self.overlayLoadDidFinish() }
                // CACHE-CRITICAL: every bail-out below (except "overlay already exists") MUST drop
                // the willBePlaceOverLays entry. That entry marks the place as drawn/in-flight; if a
                // failed attach leaves it behind, every later sweep classifies the place as already
                // handled and the territory never renders again for the whole session. The epoch
                // check now only fails on teardown (city change / check-in reset).
                guard generation == self.currentGeneration, let map = self.mapView else {
                    self.willBePlaceOverLays.removeAll { $0.placeKey == c.place.placeKey }
                    return
                }
                // Same use-time dedup/idempotency guards as the S0 onResourceLoaded (MM:1632-1633).
                guard self.willBePlaceOverLays.contains(where: { $0.placeKey == c.place.placeKey }) else { return }
                guard self.findOverlay(for: c.place) == nil else { return }

                let icon = CLHelper.createCustomIconView(for: c.place, with: image)
                let overlay = AnimationsUtil.addGroundOverlayToMap(
                    mapView: map, centerLatLng: center, image: icon,
                    zoomLevel: diameter, isTappable: !clicked,
                    zIndex: Int32(1000 - Float(c.size)))
                guard overlay.map != nil else {
                    // addGroundOverlayToMap leaves .map nil when created during focus mode — release
                    // the entry so the post-focus sweep can re-create the overlay.
                    self.willBePlaceOverLays.removeAll { $0.placeKey == c.place.placeKey }
                    return
                }
                let firstAppearance = self.markAnimatedIfFirstAppearance(placeKey: c.place.placeKey)
                if !clicked, let polygon {
                    if firstAppearance {
                        AnimationsUtil.isAnimatingPolygon = true
                        AnimationsUtil.animatePolygonScaling(
                            polygon: polygon,
                            coordinates: AnimationsUtil.coordinates(from: pts),
                            mapView: map)
                    } else {
                        // Re-entry: full path already built — attach at final size, no scale-in replay.
                        polygon.map = map
                    }
                    self.associatedOverlays[polygon] = overlay
                    self.associatedPolygons[overlay] = polygon
                }
                if isCheckIn { self.handleCheckInSituation(for: overlay) }
                if firstAppearance, let bnds = overlay.bounds {
                    AnimationsUtil.startOverlayAnimation(for: overlay, targetBounds: bnds)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard self != nil else { return }
                    var mp = c.place
                    mp.animator = AnimationsUtil.createPulseAnimation(groundOverlay: overlay, placeDetails: mp)
                    self?.placeOverlays[overlay] = mp
                }
                self.placeOverlays[overlay] = c.place
                // Loader hide is owned by overlayLoadDidFinish (deferred above) — hiding here per
                // attach used to kill the loader while sibling territories were still loading.
            }
        }
    }

    // Async bridge over the cached loader. Stale results are discarded by the caller's generation
    // guard; a nil image falls back to the bundled place-type icon in createCustomIconView.
    fileprivate func loadGroupImage(imageName: String) async throws -> UIImage? {
        let path = Constants.GROUP_PHOTO_STORAGE + Utils.getImageUrl200(imageName: imageName)
        return await withCheckedContinuation { cont in
            MapImageLoader.load(storagePath: path) { image in
                cont.resume(returning: image)
            }
        }
    }
}


