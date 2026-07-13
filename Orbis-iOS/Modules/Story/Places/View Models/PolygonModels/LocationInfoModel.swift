//
//  LocationInfoModel.swift
//  Orbis-iOS
//
//  Created by Kamran on 30/10/2024.
//


import Foundation
import CoreLocation

struct LocationInfoModel: Codable {
    var centerCoordinate: CLLocationCoordinate2D?
    var suburb: String?
    var cityDistrict: String?
    var city: String?
    var municipality: String?
    var county: String?
    var stateDistrict: String?
    var state: String?
    var country: String?
    
    var isValid: Bool {
        return (cityDistrict?.isEmpty == false) || (suburb?.isEmpty == false) || (city?.isEmpty == false) || (municipality?.isEmpty == false) || (county?.isEmpty == false) || (country?.isEmpty == false) || (stateDistrict?.isEmpty == false) || (state?.isEmpty == false)
    }
    
    enum CodingKeys: String, CodingKey {
        case city
        case municipality
        case country
        case county
        case cityDistrict
        case suburb
        case state
        case stateDistrict
    }
    
    func getPlaceName(zoom: Float) -> String {
        let minZoomForCountry: Float = AppValues.isCurrentDeviceOld ? 7 : 8
        if (zoom <= minZoomForCountry) {
            return country ?? ""
        } else if ((zoom > minZoomForCountry) && (zoom <= (minZoomForCountry + 1))) {
            if state?.isEmpty == false {
                return "\(state ?? "")"
            } else {
                return "\(stateDistrict ?? country ?? "")"
            }
        } else if ((zoom > (minZoomForCountry + 1)) && (zoom <= (minZoomForCountry + 1.5))) {
            if county?.isEmpty == false {
                return "\(county ?? "")"
            } else {
                return "\(stateDistrict ?? state ?? country ?? "")"
            }
        } else if ((zoom > (minZoomForCountry + 1.5)) && (zoom <= (minZoomForCountry + 2.0))) {
            if municipality?.isEmpty == false {
                return "\(municipality ?? "")"
            } else {
                return "\(county ?? state ?? stateDistrict ?? country ?? "")"
            }
        } else if ((zoom > (minZoomForCountry + 2.0)) && (zoom <= (minZoomForCountry + 2.5))) {
            if city?.isEmpty == false {
                return "\(city ?? "")"
            } else {
                return "\(cityDistrict ?? municipality ?? county ?? state ?? stateDistrict ?? country ?? "")"
            }
        } else {
            if suburb?.isEmpty == false {
                return "\(suburb ?? "")"
            } else {
                return "\(cityDistrict ?? city ??  municipality ?? county ?? state ?? stateDistrict ?? country ?? "")"
            }
        }
    }

}
