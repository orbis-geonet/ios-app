//
//  AppDelegate.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/03/2021.
//

import UIKit
import IQKeyboardManager
import Toast_Swift
import GoogleMaps
import GooglePlaces
import Firebase
import FBSDKCoreKit
import GoogleSignIn
import FirebaseDynamicLinks
import GoogleMobileAds
import BranchSDK
import FirebaseRemoteConfig

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    /// set orientations you want to be allowed in this property by default
    var orientationLock = UIInterfaceOrientationMask.portrait
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //MARK: - Bypass onboarding screen
        UserSessionManager.shared.setOnboardingShown()
        UserSessionManager.shared.setLoginOnboardingShown()
        
        AppEnvironmentManager.shared.setAppEnvironmentBasedOnConfiguration()
        configureSocialMediaSDK(application, didFinishLaunchingWithOptions: launchOptions)
        initializeIQKeyboardManager()
        initializeFirebase()
        initializeGoogleMap()
        configureToastManager()
        registerForPushNotifications()
        MobileAds.shared.start(completionHandler: nil)
        
        let activityKey = NSString(string: "UIApplicationLaunchOptionsUserActivityKey")
        if let userActivityDict = launchOptions?[.userActivityDictionary] as? [NSObject : AnyObject], let userActivity = userActivityDict[activityKey] as? NSUserActivity, let webPageUrl = userActivity.webpageURL {
            
            DynamicLinks.dynamicLinks().handleUniversalLink(webPageUrl) { (dynamiclink, error) in
                if let link = dynamiclink {
                    self.handleDeeplink(link: link)
                }
            }
            
        }
        
        //See Branch Logs
        if AppEnvironmentManager.shared.environment == .staging {
            Branch.setUseTestBranchKey(true)
            Branch.getInstance().enableLogging()
        }
        
        // This version of `initSession` includes the source UIScene in the callback
        BranchScene.shared().initSession(launchOptions: launchOptions, registerDeepLinkHandler: { (params, error, scene) in
            guard let data = params as? [String: AnyObject] else { return }
            debugPrint("Branch data = \(data)")
            if let partnerKey = data[SignupParamKeys.partnerKey] as? String {
                UserSessionManager.shared.setBranchPartnerKey(key: partnerKey)
            }
        })
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
            self.handleDeeplink(link: dynamicLink)
            return true
        }
        let index = String(describing: url).index(String(describing: url).startIndex, offsetBy: 1)
        if String(String(describing: url)[...index]) == "fb"{
            return ApplicationDelegate.shared.application(app, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplication.OpenURLOptionsKey.annotation])
        }
        if Auth.auth().canHandle(url) {
            return true
        }
        let handled = GIDSignIn.sharedInstance.handle(url)
        if handled {
            return true
        }
        return false
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        let handled = DynamicLinks.dynamicLinks()
            .handleUniversalLink(userActivity.webpageURL!) { dynamiclink, error in
                if let link = dynamiclink {
                    self.handleDeeplink(link: link)
                }
            }
        return handled
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
//    func applicationDidBecomeActive(_ application: UIApplication) {
//        verifyVersion()
//    }
    
    // MARK:- Social Media Configuration
    
    private func configureSocialMediaSDK(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        // FBSDK configuration
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        // GID configuration
        // Initialize sign-in
        
//        GIDSignIn.sharedInstance. clientID =
//        GIDSignIn.sharedInstance.delegate = self
    }

    // MARK:- Initialize IQKeyboardManager
    
    private func initializeIQKeyboardManager() {
        IQKeyboardManager.shared().isEnabled = true
//        IQKeyboardManager.shared().isEnableAutoToolbar = false
        //IQKeyboardManager.shared().toolbarDoneBarButtonItemText = "Done"
        
        IQKeyboardManager.shared().toolbarDoneBarButtonItemText = "Close".localized //NSLocalizedString("KeyboardDoneButtonText", comment: "Text for the toolbar Done button")

      
        IQKeyboardManager.shared().shouldResignOnTouchOutside = true
        IQKeyboardManager.shared().keyboardDistanceFromTextField = CGFloat(15).relativeToIphone8Width()
    }
    
    //MARK:- Initialize Firebase
    
    private func initializeFirebase() {
        FirebaseApp.configure()
    }
    
    // MARK:- Initialize Google Map
    
    private func initializeGoogleMap() {
        GMSServices.provideAPIKey(APPKeys.ApiKeys.googleAPIKey)
        GMSPlacesClient.provideAPIKey(APPKeys.ApiKeys.googleAPIKey)
    }
    
    // MARK:- Initialize Toast
    
    private func configureToastManager() {
        var toastStyle = ToastStyle()
        toastStyle.messageFont = UIFont(name: "Roboto-Regular", size: CGFloat(14).relativeToIphone8Width())!
        toastStyle.titleFont = UIFont(name: "Roboto-Medium", size: CGFloat(16).relativeToIphone8Width())!
        ToastManager.shared.style = toastStyle
        ToastManager.shared.isQueueEnabled = true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return orientationLock
    }
    
    // MARK:- Handle App Deeplink
    
    func handleDeeplink(link: DynamicLink) {
        DynamicLinkUIManager.shared.handleDeeplink(link: link)
    }
}

//extension AppDelegate: GIDSignInDelegate {
//    
//    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
//        if let error = error {
//            print("\(error.localizedDescription)")
//            NotificationCenter.default.post(
//                name: Notification.Name(rawValue: AppNotificationKeys.googleSignInResult),
//                object: error)
//        } else {
//            let googleUser = GoogleUser()
//            googleUser.googleId = user.userID
//            googleUser.token = user.authentication.accessToken
//            googleUser.idToken = user.authentication.idToken
//            googleUser.fullName = user.profile.name
//            googleUser.fname = user.profile.givenName
//            googleUser.lname = user.profile.familyName
//            googleUser.email = user.profile.email
//            googleUser.profilePictureUrl = user.profile.imageURL(withDimension: 100)?.absoluteString
//            GoogleUser.shared = googleUser
//            NotificationCenter.default.post(
//                name: Notification.Name(rawValue: AppNotificationKeys.googleSignInResult),
//                object: googleUser)
//        }
//    }
//    
//}

extension AppDelegate: MessagingDelegate, UNUserNotificationCenterDelegate {
    func registerForPushNotifications() {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (bool, err) in
                if let error = err {
                    print("error in accessing notification rights: \(error.localizedDescription)")
                }
                else {
                    DispatchQueue.main.async(execute: {
                        UIApplication.shared.registerForRemoteNotifications()
                    })
                }
            }
            Messaging.messaging().delegate = self

        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            DispatchQueue.main.async(execute: {
                UIApplication.shared.registerForRemoteNotifications()
            })

        }
    }

    func updateFirestorePushTokenIfNeeded() {
        if let token = Messaging.messaging().fcmToken {
            updateUserFirebaseToken(token: token)
        }
    }

    fileprivate func updateUserFirebaseToken(token: String) {
        guard UserSessionManager.shared.currentUser != nil else {
            print("User not logged it")
            return
        }
        UserSessionManager.shared.updateFirebaseToken(fcmToken: token, shouldAddToken: true) { (data, err) in
            if let error = err {
                debugPrint("Error in updating firebase token. \(error.localizedDescription)")
            }
            else {
                if let boolVal = data as? Bool, !boolVal {
                    debugPrint("FCM Token not changed....!!")
                }
                else {
                    debugPrint("FCM Token has been updated successfully")
                }
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("User Info = ",notification.request.content.userInfo)
        completionHandler([.alert,.sound])
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data){
        Messaging.messaging().apnsToken = deviceToken
        if AppEnvironmentManager.shared.environment == .production {
            Messaging.messaging().setAPNSToken(deviceToken, type: .prod)
        }
        else {
            Messaging.messaging().setAPNSToken(deviceToken, type: .sandbox)
        }
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        updateFirestorePushTokenIfNeeded()
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("didFailToRegisterForRemoteNotificationsWithError: \(error.localizedDescription)")
    }

    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UNNotificationSetting) {
        application.registerForRemoteNotifications()
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        handlePushNotification(userInfo: userInfo)
//        createLocalNotification(userInfo: userInfo, identifier: "IOU-Money-Data-notification-\(Date().timeIntervalSince1970)")
        completionHandler(.newData)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        handlePushNotificationTap(notification: response.notification)
        completionHandler()
    }


    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        handlePushNotification(userInfo: userInfo)
    }
    

    fileprivate func handlePushNotificationTap(notification: UNNotification) {
        let data = notification.request.content.userInfo
        guard let userInfo = data as? [String: Any], let notifObj = OrbisPushNotifObject.initFrom(userInfo: userInfo), notifObj.isValid else { return }
        PushNotificationUIManager.shared.goToNotificationContentView(notif: notifObj)
    }

    fileprivate func handlePushNotification(userInfo: [AnyHashable: Any]) {
        print("Received notification: \(userInfo)")
        Messaging.messaging().appDidReceiveMessage(userInfo)
        UNUserNotificationCenter.current().getNotificationSettings(){ (setttings) in
            switch setttings.authorizationStatus{
            case .notDetermined:
                print("Not Determined")

            case .denied:
                print("Denied")

            case .authorized, .provisional:
                print("Authorized")
                // Do what's neeeded to do
            case .ephemeral:
                print("Emphemeral")
            @unknown default:
                fatalError()
            }
        }
    }
}



extension AppDelegate {
    func setupRemoteConfig(){
        let remoteConfig = RemoteConfig.remoteConfig()
        let defaults : [String : Any] = [
            ForceUpdateChecker.IS_FORCE_UPDATE_REQUIRED : false,
            ForceUpdateChecker.FORCE_UPDATE_CURRENT_VERSION : "3.3.2(2)",
            ForceUpdateChecker.FORCE_UPDATE_STORE_URL : "https://apps.apple.com/us/app/orbis-digital-tribes/id1453025529"
        ]

        let expirationDuration = 0

        remoteConfig.setDefaults(defaults as? [String : NSObject])

        remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) { (status, error) in
            if status == .success {
                remoteConfig.activate()
            } else {
                print("Error: \(error?.localizedDescription ?? "No error available.")")
            }
        }
    }

    func goToAppStore(action: UIAlertAction) {
        let appId = "1453025529"
        UIApplication.shared.openAppStore(for: appId)
    }

    //4
//    func verifyVersion() {
//        setupRemoteConfig()        
//        if ForceUpdateChecker().check() == .shouldUpdate {
//            let alert = UIAlertController(title: "New Version Available",
//                                          message: "There is a new version available to download, please update your app to latest version.",
//                                          preferredStyle: .alert)
//            let action = UIAlertAction(title: "Update", style: .default, handler: goToAppStore)
//            alert.addAction(action)
//            window?.rootViewController?.present(alert, animated: true)
//        }
//    }
//    func verifyVersion() {
//        let remoteConfig = RemoteConfig.remoteConfig()
//        let expirationDuration = 0
//        
//        remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) { status, error in
//            if status == .success {
//                remoteConfig.activate { _, _ in
//                    print("RemoteConfig activated successfully")
//                    self.checkForUpdate()
//                }
//            } else {
//                print("Error fetching remote config: \(error?.localizedDescription ?? "Unknown error")")
//                self.checkForUpdate() // Fallback to defaults
//            }
//        }
//    }
//
//    private func checkForUpdate() {
//        if ForceUpdateChecker().check() == .shouldUpdate {
//            DispatchQueue.main.async {
//                let alert = UIAlertController(
//                    title: "New Version Available",
//                    message: "There is a new version available to download, please update your app.",
//                    preferredStyle: .alert
//                )
//                let action = UIAlertAction(title: "Update", style: .default, handler: self.goToAppStore)
//                alert.addAction(action)
//                
//                if let topVC = UIApplication.shared.connectedScenes
//                    .compactMap({ $0 as? UIWindowScene })
//                    .flatMap({ $0.windows })
//                    .first(where: { $0.isKeyWindow })?.rootViewController {
//                    topVC.present(alert, animated: true)
//                }
//            }
//        }
//    }
}
