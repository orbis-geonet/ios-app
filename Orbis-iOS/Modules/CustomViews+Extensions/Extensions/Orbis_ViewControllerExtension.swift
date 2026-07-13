//
//  ViewControllerExtension.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/03/2021.
//

import UIKit

extension UIViewController {
    /**
     Shows an alert with a title and a message
     */
    func showAlert(title: String, message:String, shouldPopView:Bool = false, shouldPopViewToRoot: Bool = false, shouldDismissView: Bool = false, completion:(() -> Void)? = nil) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        // show the alert with a "ok" button that will close the alert
        let okAction = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default) { (action)-> Void in
            if shouldDismissView {
                self.dismiss(animated: true, completion: nil)
            }
            else if shouldPopView {
                if shouldPopViewToRoot {
                    _ = self.navigationController?.popToRootViewController(animated: true)
                }
                else {
                    _ = self.navigationController?.popViewController(animated: true)
                }
            }
            completion?()
        }
        alertController.addAction(okAction)
        
        // show alert controller
        self.present(alertController, animated: true, completion: nil)
    }
    
    func navigateToLocatonSettingScreen(title: String, message:String, shouldPopView:Bool = false, shouldPopViewToRoot: Bool = false, shouldDismissView: Bool = false, completion:(() -> Void)? = nil) {
        
        
//        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
//        
//        // show the alert with a "ok" button that will close the alert
//        let okAction = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default) { (action)-> Void in
//            if shouldDismissView {
//                self.dismiss(animated: true, completion: nil)
//            }
//            else if shouldPopView {
//                if shouldPopViewToRoot {
//                    _ = self.navigationController?.popToRootViewController(animated: true)
//                }
//                else {
//                    _ = self.navigationController?.popViewController(animated: true)
//                }
//            }
//            completion?()
//        }
//        alertController.addAction(okAction)
//        
//        // show alert controller
//        self.present(alertController, animated: true, completion: nil)
        
        
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }

    
    
    
    
    func showConfirmationAlert(title: String, message: String, okBtnTitle: String, cancelBtnTitle: String, completion:((Bool) -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        // show the alert with a "ok" button that will close the alert
        let okAction = UIAlertAction(title: okBtnTitle, style: UIAlertAction.Style.default) { (action)-> Void in
            completion?(true)
        }
        let cancelAction = UIAlertAction(title: cancelBtnTitle, style: UIAlertAction.Style.default) { (action)-> Void in
            completion?(false)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        
        // show alert controller
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showToastMessage(message: String) {
        DispatchQueue.main.async {
            [weak self] in
            guard let self = self else { return }
            guard self.isViewLoaded else { return }
            UIUtil.showGlobalToast(message: message)
        }
        
    }
    
    func showOrbisLoader(disableUserInteraction: Bool = false, isWhiteLoader: Bool = false) {
        DispatchQueue.main.async {
            if disableUserInteraction {
                self.view.isUserInteractionEnabled = !disableUserInteraction
            }
            if(isWhiteLoader) {
                self.view.showWhiteOrbisLoader()
            } else {
                self.view.showOrbisLoader()
            }
        }
    }
    
    func hideOrbisLoader() {
        DispatchQueue.main.async {
            self.view.isUserInteractionEnabled = true
            self.view.hideOrbisLoader()
        }
    }
    
    func handleError(error: Error, defaultMessage: String? = nil) {
        if let emptyFieldError = error as? ValidationErrors {
            self.showToastMessage(message: emptyFieldError.description)
        }
        else if let groupError = error as? OrbisGroupError {
            self.showToastMessage(message: groupError.description)
        }
        else if let responseError = error as? ResponseError {
            showToastMessage(message: responseError.description)
        }
        else if let commonError = error as? CommonError {
            showToastMessage(message: commonError.description)
        }
        else if let genericError = error as? GenericError {
            self.showToastMessage(message: genericError.errorDescription!)
        }
        else if let warningError = error as? GenericWarningError {
            self.showAlert(title: warningError.title ?? AppStrings.warning, message: warningError.errorDescription!)
        }
        else if let msg = defaultMessage {
            showToastMessage(message: msg)
        }
        else {
            self.showAlert(title: AppStrings.error, message: AppErrorStrings.couldNotCompleteReq)
        }
    }
}
