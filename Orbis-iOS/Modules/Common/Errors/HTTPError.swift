//
//  NetworkError.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 23/04/2021.
//

import Foundation

enum HTTPError: Error {
    case unknownError
    case notAuthorized
    case notFound
    case timeout
}

extension HTTPError:CustomStringConvertible {
    var description: String{
        switch self {
        case .notFound:
            return "Not found".localized
        case .notAuthorized:
            return "Not authorized".localized
        case .timeout:
            return "Request timeout".localized
        default:
            return "An error occurred".localized
        }
    }
}

enum AlamofireErrorCodes: Int {
    case canceled = -999
}
