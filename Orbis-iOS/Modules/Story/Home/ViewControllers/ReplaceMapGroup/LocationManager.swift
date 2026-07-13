//
//  LocationManager.swift
//  Orbis-iOS
//
//  Created by Kamran on 25/10/2024.
//
import CoreLocation
import Combine

protocol LocationManagerDelegate: AnyObject {
    func didUpdateLocation(_ location: CLLocation)
    func didUpdateLocationAuthorization(_ isAuthorized: Bool)
    func showLocationPermissionAlert()
}

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let geoCoder = CLGeocoder()
    private var cancellables = Set<AnyCancellable>()
    weak var delegate: LocationManagerDelegate?

    var locationPermissionDenied = CurrentValueSubject<Bool, Never>(false)

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocationPermissions() {
        locationManager.requestAlwaysAuthorization()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    func enableLocationService(shouldShowAlert: Bool = true) {
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            
            guard CLLocationManager.locationServicesEnabled() else {
                if shouldShowAlert {
                    self.delegate?.showLocationPermissionAlert()
                }
                return
            }
            if #available(iOS 14.0, *) {
                switch self.locationManager.authorizationStatus {
                case .authorizedAlways, .authorizedWhenInUse:
                    self.locationPermissionDenied.send(false)
                case .notDetermined:
                    self.locationManager.requestAlwaysAuthorization()
                case .denied, .restricted:
                    self.locationPermissionDenied.send(true)
                default:
                    break
                }
            } else {
                // Fallback on earlier versions
                if shouldShowAlert {
                    self.locationManager.requestAlwaysAuthorization()
                }
            }
        }
    }
    
    private func checkLocationAuthorization() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                print("Location access denied or restricted")
            case .authorizedWhenInUse, .authorizedAlways:
                print("Location access granted")
            @unknown default:
                print("Unknown authorization status")
            }
        }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationPermissionDenied.send(false)
            delegate?.didUpdateLocationAuthorization(true)
        case .denied, .restricted:
            locationPermissionDenied.send(true)
            delegate?.didUpdateLocationAuthorization(false)
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        delegate?.didUpdateLocation(location)
        stopUpdatingLocation()
    }

    func fetchCityName(for location: CLLocation, completion: @escaping (String?) -> Void) {
        geoCoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                completion(placemark.locality)
            } else {
                completion(nil)
            }
        }
    }
    
    
    /*
    func fetchCountryAndCityName(for location: CLLocation, completion: @escaping (_ country: String?, _ city: String?) -> Void) {
        let geoCoder = CLGeocoder() // Create an instance of CLGeocoder
        geoCoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Error reverse geocoding location: \(error.localizedDescription)")
                completion(nil, nil)
                return
            }
            
            guard let placemark = placemarks?.first else {
                print("No placemarks found for location")
                completion(nil, nil)
                return
            }
            
            // Extract the city and country from the placemark
            let city = placemark.locality
            let country = placemark.country
            
            // Return the city and country separately
            completion(country, city)
        }
    }
     */
    
    func fetchCountryAndCityName(for location: CLLocation, completion: @escaping (_ country: String?, _ city: String?) -> Void) {
        let geoCoder = CLGeocoder() // Create an instance of CLGeocoder
        geoCoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Error reverse geocoding location: \(error.localizedDescription)")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else {return}
                    completion(nil, nil) // Return on the main thread
                }
                return
            }
            
            guard let placemark = placemarks?.first else {
                print("No placemarks found for location")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else {return}

                    completion(nil, nil) // Return on the main thread
                }
                return
            }
            
            // Extract the city and country from the placemark
            let city = placemark.locality
            let country = placemark.country
            
            // Return the city and country separately on the main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {return}

                completion(country, city)
            }
        }
    }


}
