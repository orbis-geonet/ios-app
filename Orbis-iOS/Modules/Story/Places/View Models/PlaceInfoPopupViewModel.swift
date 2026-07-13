//
//  PlaceInfoPopupViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 14/08/2023.
//

import Foundation
import UIKit

enum PlaceInfoPopupViewType: String {
    case address
    case telephone
    case schedule
    case website
    
    var viewTitle: String {
        switch self {
        case .address:
            return AppStrings.Places.placeAddressLabel
        case .telephone:
            return AppStrings.Places.placeTelephoneLabel
        case .schedule:
            return AppStrings.Places.placeScheduleLabel
        case .website:
            return AppStrings.Places.placeWebsiteLabel
        }
    }
    
    var viewActionTitle: String {
        switch self {
        case .address:
            return AppStrings.Places.openInGoogleMaps
        case .telephone:
            return AppStrings.Places.callTitle
        case .schedule:
            return ""
        case .website:
            return AppStrings.Places.gotoWebsite
        }
    }
    
    var isViewActionHidden: Bool {
        switch self {
        case .schedule:
            return true
        default:
            return false
        }
    }
    
    var editActionTitle: String {
        return AppStrings.update
    }
}

class PlaceInfoPopupViewModel {
    var viewType: PlaceInfoPopupViewType!
    var place: OrbisPlace!
    private let manager = OrbisPlaceDetailManager()
    
    var isUpdating = false
    var onPlaceDetailUpdateError: ((Error) -> Void)?
    var onPlaceDetailUpdateSuccess: ((OrbisPlace) -> Void)?
    
    var placeOpeningSchedules: OrbisPlaceWorkingDays {
        return place.workingHours?.filter({ $0.weekDay != nil }).sorted(by: { $0.weekDay!.displayIndex < $1.weekDay!.displayIndex }) ?? []
    }
    
    init(viewType: PlaceInfoPopupViewType, model: OrbisPlace) {
        self.viewType = viewType
        self.place = model
    }
    
    var viewTitle: String {
        return viewType.viewTitle
    }
    
    var viewContentPlaceholder: String {
        switch viewType {
        case .address:
            return AppStrings.Places.placeAddressPlaceholder
        case .telephone:
            return AppStrings.Places.placeTelephonePlaceholder
        case .schedule:
            return ""
        case .website:
            return AppStrings.Places.placeWebsitePlaceholder
        case .none:
            return ""
        }
    }
    
    var viewEditContentType: TextEditContentType {
        switch viewType {
        case .address:
            return .address
        case .telephone:
            return .telephone
        case .website:
            return .website
        default:
            return .freeText
        }
    }
    
    var isViewActionHidden: Bool {
        switch viewType {
        case .schedule:
            return viewType.isViewActionHidden
        case .address:
            return viewType.isViewActionHidden || (place.address ?? "").isEmpty
        case .telephone:
            return viewType.isViewActionHidden || (place.phone ?? "").isEmpty
        case .website:
            return viewType.isViewActionHidden || (place.website ?? "").isEmpty
        case .none:
            return true
        }
    }
    
    var viewActionTitle: String {
        return viewType.viewActionTitle
    }
    
    var isEditActionHidden: Bool {
        guard let _ = UserSessionManager.shared.currentUser else {
            return true
        }
        return !(place.canEdit ?? true)
    }
    
    var editActionTitle: String {
        return viewType.editActionTitle
    }
    
    var contentItemCount: Int {
        switch viewType {
        case .schedule:
            return placeOpeningSchedules.count
        case .address:
            return (place.address ?? "").isEmpty ? 0 : 1
        case .telephone:
            return (place.phone ?? "").isEmpty ? 0 : 1
        case .website:
            return (place.website ?? "").isEmpty ? 0 : 1
        case .none:
            return 0
        }
    }
    
    func getContentItem(at index: Int) -> String {
        switch viewType {
        case .address:
            return place.address ?? ""
        case .telephone:
            return place.phone ?? ""
        case .schedule:
            return ""
        case .website:
            return place.website ?? ""
        case .none:
            return ""
        }
    }
    
    func getDaySchedule(at index: Int) -> OrbisPlaceWorkingHours? {
        guard placeOpeningSchedules.count > index else { return nil }
        return placeOpeningSchedules[index]
    }
    
    var fieldParameterName: String {
        switch viewType {
        case .address:
            return PlaceDomainParameterKeys.Update.address
        case .telephone:
            return PlaceDomainParameterKeys.Update.phone
        case .website:
            return PlaceDomainParameterKeys.Update.website
        default:
            return ""
        }
    }
}

extension PlaceInfoPopupViewModel {
    
    func updatePlaceInfo(withContent text: String) {
        let param: [String: Any] = [fieldParameterName: text]
        isUpdating = true
        manager.updatePlaceData(placeKey: self.place.placeKey!, withParam: param) { [weak self] (data, err) in
            self?.isUpdating = false
            if let error = err {
                self?.onPlaceDetailUpdateError?(error)
                return
            }
            if let place = data as? OrbisPlace {
                self?.place = place
                self?.onPlaceDetailUpdateSuccess?(place)
            }
            else {
                self?.onPlaceDetailUpdateError?(ResponseError.invalidData)
            }
        }
    }
}
