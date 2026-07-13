//
//  ResponseError.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 23/04/2021.
//

import Foundation

enum ResponseError: Error {
    case invalidData
    case emptyData
    case contactAdmin
    case requestFailed
}

extension ResponseError:CustomStringConvertible {
    var description: String{
        switch self {
        case .invalidData:
            return "Data is invalid".localized
        case .emptyData:
            return "Null response data".localized
        case .contactAdmin:
            return "Contact administrator".localized
        case .requestFailed:
            return "Your request has failed.".localized
        }
    }
}

enum CommonError: Error {
    case emptyData
    case emptyUserLocation
    case invalidUser
    case invalidDataFormat
    case uploadFailed
}

extension CommonError:CustomStringConvertible {
    var description: String{
        switch self {
        case .invalidUser:
            return "User is invalid"
        case .emptyUserLocation:
            return "Invalid current location data"
        case .invalidDataFormat:
            return "Could not process your request. Please contact app admin."
        case .emptyData:
            return "Empty data returned"
        case .uploadFailed:
            return "Upload has failed. Please try again or contact app admin"
        }
    }
}
