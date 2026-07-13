//
//  UIView+Extension.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/03/2021.
//

import UIKit

extension UIView {
    
    func setViewVisibility(hidden: Bool, duration: TimeInterval, completion: ((Bool) -> Void)?) {
        UIView.transition(with: self, duration: duration, options: .transitionCrossDissolve, animations: { [weak self] in
            self?.isHidden = hidden
            }, completion: completion)
    }
    
    func setRadius(radius: CGFloat? = nil) {
        self.layer.cornerRadius = radius ?? self.frame.width / 2;
        self.layer.masksToBounds = true;
    }
    
    func setRounded() {
        let radius = self.frame.width / 2
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
    
}

extension UIView {
    
    func showOrbisLoader(withSize size: CGFloat = 100, clearBackground: Bool = true, useFullScreen: Bool = true) {
        let size = size.relativeToIphone8Width()
        let appLoader = UIUtil.getAppLoader(height: size, width: size)
        appLoader.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        if clearBackground {
            appLoader.backgroundColor = .clear
        }
        else {
            appLoader.backgroundColor = .white
        }
        appLoader.tintColor = .systemPink
        appLoader.setRadius(radius: CGFloat(10).relativeToIphone8Width())
        appLoader.tag = AppElementTags.appLoaderTag
        self.hideOrbisLoader()
        appLoader.center = self.center
        self.addSubview(appLoader)
        appLoader.translatesAutoresizingMaskIntoConstraints = false
        appLoader.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        if let window = self.window {
            let windowSafeAreaVerticalOffset = window.safeAreaInsets.top + window.safeAreaInsets.bottom
            let windowActualHeight = window.height - windowSafeAreaVerticalOffset
            let diff = self.height - windowActualHeight
            appLoader.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: (useFullScreen ? diff/2 : 0)).isActive = true
        }
        else {
            appLoader.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        }
        appLoader.widthAnchor.constraint(equalToConstant: size).isActive = true
        appLoader.heightAnchor.constraint(equalToConstant: size).isActive = true
        self.bringSubviewToFront(appLoader)
        appLoader.play()
    }
    
    func showWhiteOrbisLoader(withSize size: CGFloat = 100, clearBackground: Bool = true, useFullScreen: Bool = true) {
        let size = size.relativeToIphone8Width()
        let appLoader = UIUtil.getWhiteAppLoader(height: size, width: size)
        appLoader.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        if clearBackground {
            appLoader.backgroundColor = .clear
        }
        else {
            appLoader.backgroundColor = .white
        }
        appLoader.setRadius(radius: CGFloat(10).relativeToIphone8Width())
        appLoader.tag = AppElementTags.appLoaderTag
        self.hideOrbisLoader()
        appLoader.center = self.center
        self.addSubview(appLoader)
        appLoader.translatesAutoresizingMaskIntoConstraints = false
        appLoader.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        if let window = self.window {
            let windowSafeAreaVerticalOffset = window.safeAreaInsets.top + window.safeAreaInsets.bottom
            let windowActualHeight = window.height - windowSafeAreaVerticalOffset
            let diff = self.height - windowActualHeight
            appLoader.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: (useFullScreen ? diff/2 : 0)).isActive = true
        }
        else {
            appLoader.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        }
        appLoader.widthAnchor.constraint(equalToConstant: size).isActive = true
        appLoader.heightAnchor.constraint(equalToConstant: size).isActive = true
        self.bringSubviewToFront(appLoader)
        appLoader.play()
    }
    
    //MARK: Imageview loader
    func showOrbisLoader(on view: UIView, withSize size: CGFloat = 100, clearBackground: Bool = true, useFullScreen: Bool = true) {
            
            let loaderSize = size.relativeToIphone8Width()
            
            // Check if a loader already exists on the view by its accessibilityIdentifier
            if let existingLoader = view.subviews.first(where: { $0.accessibilityIdentifier == "OrbisLoader" }) {
                // Reuse the existing loader
                existingLoader.isHidden = false
                return
            }
            
            // Create a new loader if none exists
            let appLoader = UIUtil.getAppLoader(height: loaderSize, width: loaderSize)
            appLoader.backgroundColor = clearBackground ? .clear : UIColor.black.withAlphaComponent(0.3)
            appLoader.tintColor = .systemPink
            appLoader.setRadius(radius: CGFloat(10).relativeToIphone8Width())
            appLoader.accessibilityIdentifier = "OrbisLoader" // Set an identifier for future reference
            
            // Add loader to the specified view
            view.addSubview(appLoader)
            appLoader.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                appLoader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                appLoader.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                appLoader.widthAnchor.constraint(equalToConstant: loaderSize),
                appLoader.heightAnchor.constraint(equalToConstant: loaderSize)
            ])
            
            appLoader.play()
        }

    
    func hideOrbisLoader() {
        while let appLoader = self.viewWithTag(AppElementTags.appLoaderTag) {
            appLoader.removeFromSuperview()
        }
    }
    
    func hideOrbisLoader(withTag tag: Int) {
        while let appLoader = self.viewWithTag(cellPendingPostLoaderTag) {
            appLoader.removeFromSuperview()
        }
    }
    //ImageView hideLoader
    func hideOrbisLoader(from view: UIView, remove: Bool = false) {
            // Look for the loader by its accessibilityIdentifier
            if let existingLoader = view.subviews.first(where: { $0.accessibilityIdentifier == "OrbisLoader" }) {
                if remove {
                    // Remove the loader from the superview
                    existingLoader.removeFromSuperview()
                } else {
                    // Simply hide the loader
                    existingLoader.isHidden = true
                }
            }
        }
}
