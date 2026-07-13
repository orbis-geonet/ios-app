//
//  StartSceneViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 11/08/2021.
//

import UIKit
import Lottie
import CoreLocation


class StartSceneViewController: OrbisLocalizableViewController {
    
    // MARK: - Properties
    private var locationManager: CLLocationManager?
    private var hasHandledLocationAuthorization = false // Prevent multiple calls
    private var hasRouted = false // Ensure we leave the splash exactly once
   
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Route unconditionally; never gate the splash on config fetch or the location callback.
        setupLocationManager()
        checkLocationPermission()
        openNextScreen()

        AppFirebaseConfigManager.shared.fetchAppConfig { _, _ in }
    }
    
    private func openNextScreen() {
        guard !hasRouted else { return }
        hasRouted = true
        if UserSessionManager.shared.hasOnboardingBeenShown {
            openMapView()
        }
        else {
            UserSessionManager.shared.setOnboardingShown()
            openOnboardingScene()
        }
    }
    
    private func openOnboardingScene() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showOnboardingScene()
        }
    }
    
    private func showOnboardingScene() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                        let delegate = windowScene.delegate as? SceneDelegate, let window = delegate.window else { return }
        let homeNavVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "homeNavVC") as! UINavigationController
        let onboardingVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "onboardingVC") as! OnboardingViewController
        homeNavVC.viewControllers = [onboardingVC]
        window.rootViewController = homeNavVC
        window.makeKeyAndVisible()
    }
    
    private func openMapView() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showMapScene()
        }
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
    
    
    // MARK: - Location Manager Setup
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // MARK: - Check Location Permission
    private func checkLocationPermission() {
        
        guard let locationManager = locationManager else {
            return
        }
        
        let status = CLLocationManager.authorizationStatus()
        
        switch status {
        case .notDetermined:
            // Request permission only once
            locationManager.requestWhenInUseAuthorization()
            
        case .restricted, .denied:
            
            handleLocationAuthorizationChange(status)
            
        case .authorizedWhenInUse, .authorizedAlways:
            
            handleLocationAuthorizationChange(status)
            
        @unknown default:
            handleLocationAuthorizationChange(status)
        }
    }
    
    // MARK: - Location Authorization Update
    private func handleLocationAuthorizationChange(_ status: CLAuthorizationStatus) {
        // Prevent multiple calls to openNextScreen
        guard !hasHandledLocationAuthorization else {
            print("Authorization already handled. Skipping.")
            // Call openNextScreen regardless of status
            openNextScreen()
            return
        }
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location permission granted.")
            // Call openNextScreen regardless of status
            openNextScreen()
        case .denied, .restricted:
            print("Location permission denied.")
            // Call openNextScreen regardless of status
            openNextScreen()
        default:
            print("Location status: \(status)")
        }
        
        hasHandledLocationAuthorization = true
        
        
        // Remove location manager, no need to track anymore
        locationManager?.delegate = nil
        locationManager = nil
    }
}

// MARK: - CLLocationManagerDelegate
extension StartSceneViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
       
        if status == .notDetermined {
            return
        }
        
        print("Location authorization changed to: \(status)")
        handleLocationAuthorizationChange(status)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with error: \(error.localizedDescription)")
    }
}
