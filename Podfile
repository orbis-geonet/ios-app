# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

def shared_pods
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  pod 'IQKeyboardManager'
  pod 'Toast-Swift'
  pod 'Tabman'
  pod 'KMPlaceholderTextView'
  pod 'GoogleMaps'
  pod 'GooglePlaces'
  pod 'ExpandableLabel'
  pod 'PryntTrimmerView' # for YPImagePicker
  pod 'SteviaLayout' # for YPImagePicker
  pod 'HWPanModal'
  pod 'SkyFloatingLabelTextField'
  pod 'GrowingTextView'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics'
  pod 'Firebase/Auth'
  pod 'Firebase/Storage'
  pod 'FirebaseUI/Storage'
  pod 'Firebase/Database'
  pod 'Firebase/Messaging'
  pod 'Firebase/Firestore'
  pod 'Firebase/DynamicLinks'
  pod 'Firebase/RemoteConfig'
  pod 'Alamofire'
  pod 'SDWebImage'
  pod 'SwiftyJSON'
  pod 'lottie-ios'
  pod 'JWTDecode'
  pod 'FBSDKLoginKit', '16.1.0'
  pod 'GoogleSignIn'
  pod 'CodableFirebase'
  pod 'ActiveLabel'
  pod 'AMRAudioSwift', :git => 'https://github.com/teambition/AMRAudioSwift.git'
  pod 'SZAVPlayer'
#  pod 'Google-Mobile-Ads-SDK'
  pod 'Google-Mobile-Ads-SDK'
  pod 'TPKeyboardAvoiding', '~> 1.3'
  pod 'StripePaymentSheet', '~> 23.2.0'
  pod 'BranchSDK'
  pod 'Cosmos'
  pod 'RealmSwift', '~> 10.40.0' 
end

target 'Orbis-iOS' do
  # Pods for Orbis-iOS
  shared_pods
end

target 'Orbis-iOS-Staging' do
  # Pods for Orbis-iOS
  shared_pods
end

# Post-install script to modify build settings
post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
  end

  installer.pods_project.targets.each do |target|
    # ✅ Disable App Extension API restriction for RealmSwift
    if target.name == 'RealmSwift'
      target.build_configurations.each do |config|
        config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'NO'
      end
    end

    # ✅ Fix warnings in BoringSSL-GRPC
    if target.name == 'BoringSSL-GRPC'
      target.source_build_phase.files.each do |file|
        if file.settings && file.settings['COMPILER_FLAGS']
          flags = file.settings['COMPILER_FLAGS'].split
          flags.reject! { |flag| flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
          file.settings['COMPILER_FLAGS'] = flags.join(' ')
        end
      end
    end
  end
end