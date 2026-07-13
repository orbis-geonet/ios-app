//
//  AppEnvironmentManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 04/10/2021.
//

import Foundation

enum AppEnvironment: String {
    case staging
    case production
}

class AppEnvironmentManager {
    static let shared = AppEnvironmentManager()
    var environment: AppEnvironment = .staging
    
    enum Keys {
        enum Plist {
            static let environtmentType = "OrbisAppEnvironment"
        }
    }
    
    // MARK: - Plist values
    private let environmentType: AppEnvironment = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        guard let envType = dict[AppEnvironmentManager.Keys.Plist.environtmentType] as? String else {
            fatalError("Environment type not set in plist for this environment")
        }
        switch envType {
        case "Staging":
            return .staging
        case "Production":
            return .production
        default:
            return .staging
        }
    }()
    
    func setAppEnvironmentBasedOnConfiguration() {
        environment = environmentType
    }
}
