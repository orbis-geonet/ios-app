//
//  OrbisPlaceModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 07/05/2021.
//

import Foundation
import CoreLocation
import GoogleMaps

typealias OrbisPlaces = [OrbisPlace]

extension OrbisPlaces {
    func removingInvalidMapPlaces(with formatter: ISO8601DateFormatter) -> OrbisPlaces {
        return self.filter({$0.calculatedSize(with: formatter) > 0})
    }
}

enum OrbisDaysOfWeek: Int, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var displayIndex: Int {
        switch self {
        case .sunday:
            return 6
        case .monday:
            return 0
        case .tuesday:
            return 1
        case .wednesday:
            return 2
        case .thursday:
            return 3
        case .friday:
            return 4
        case .saturday:
            return 5
        }
    }
    
    var dayName: String {
        switch self {
        case .sunday:
            return "Sunday".localized
        case .monday:
            return "Monday".localized
        case .tuesday:
            return "Tuesday".localized
        case .wednesday:
            return "Wednesday".localized
        case .thursday:
            return "Thursday".localized
        case .friday:
            return "Friday".localized
        case .saturday:
            return "Saturday".localized
        }
    }
}

typealias OrbisPlaceWorkingDays = [OrbisPlaceWorkingHours]

struct OrbisPlaceWorkingHours: Codable {
    var day: String?
    var time: String?
    
    var weekDay: OrbisDaysOfWeek? {
        guard let dayKey = self.day, let dayNum = Int(dayKey) else { return nil }
        return OrbisDaysOfWeek(rawValue: dayNum)
    }
    
    var dayName: String {
        return weekDay?.dayName ?? ""
    }
    
    var startTime: String {
        return time?.split(separator: "-").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    var endTime: String {
        return time?.split(separator: "-").last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    // Convert OrbisPlaceWorkingHours to WorkingHoursModel
        func toWorkingHoursModel() -> WorkingHoursModel {
            return WorkingHoursModel(day: self.day ?? "", time: self.time ?? "")
        }
}

struct OrbisPlace: Codable {
    var coordinates: OrbisLocationModel?
    var name: String?
    var placeKey: String?
    var imageName: String?
    var type: String?
    var userCreatedKey: String?
    var source: String?
    var address: String?
    var description: String?
    var categoryKey: String?
    var cityKey: String?
    var countryKey: String?
    var phone: String?
    var website: String?
    var averageRate: Double?
    var totalRate: Double?
    var countRates: Int?
    var userRate: Double?
    var lastCheckInTimestamp: String?
    var lastSizeChangeTimestamp: String?
    var dominantGroupKey: String?
    var creationServerTimestamp: String?
    var timestamp: String?
    var groupCreatedKey: String?
    var dominantGroup: Group?
    var competingGroups: Groups?
    var googlePlaceId: String?
    var size: Double?
    var lastSize: Double?
    var following: Bool?
    var workingHours: OrbisPlaceWorkingDays?
    var canEdit: Bool?
    var places: [PolygonPlaceDetails]?
    var checkInPolygonCoordinateKey: String?
    
    //MARK: Kamran Variables of PolygonPlaceDetails
    var previousSize: Double? // Make this optional
    var palindromeKey: String?
    var polygonPoints: [Coordinates]?
    var polygonCenter: Coordinates?
    
    // Transient properties that do not require serialization
    var touch: Bool = false
    var sizeCalculated: Bool = false
    var isFocusSelected: Bool = false
    var animator: UIViewPropertyAnimator? = nil  // Swift alternative to ValueAnimator
    //MARK: End of Kamran variables of PolygonPlaceDetails
    var isFollowing: Bool {
        return following == true
    }
    
//    var lastCheckinDate: Date {
//        return Date.fromString(string: lastCheckInTimestamp ?? "") ?? Date().addingTimeInterval(-100000)
//    }
    
    var placeType: OrbisPlaceType {
        return OrbisPlaceType(rawValue: type ?? "") ?? .location
    }
    
    var placeDominantGroup: Group? {
        return dominantGroup ?? competingGroups?.first
    }
    
    enum CodingKeys: String, CodingKey {
        case coordinates, name, placeKey, palindromeKey, type, source, address, description, imageName
        case lastCheckInTimestamp, dominantGroupKey, size, previousSize, dominantGroup, competingGroups
        case following, website, phone, averageRate, totalRate, countRates, userRate, canEdit, workingHours
        case places, polygonPoints, polygonCenter, checkInPolygonCoordinateKey
    }
    
    func lastCheckinDate(with formatter: ISO8601DateFormatter) -> Date {
        Date.fromString(string: lastCheckInTimestamp ?? "", with: formatter) ?? Date().addingTimeInterval(-100_000)
    }
    
    func calculatedSize(with formatter: ISO8601DateFormatter) -> Double {
        guard let lastCheckinTime = Date.fromString(string: lastSizeChangeTimestamp ?? "", with: formatter), let lastSize = self.lastSize else {
            return self.lastSize ?? 0
        }
        let elapsedTime = abs(lastCheckinTime.timeIntervalSince1970 - Date().timeIntervalSince1970) * 1000 //milliseconds
        var placeSize: Double = lastSize
        if (elapsedTime < AppValues.DateTime.millisecondsInDay && placeSize >= 500) {
          placeSize = (placeSize - 500) * ((AppValues.DateTime.millisecondsInDay - elapsedTime) / AppValues.DateTime.millisecondsInDay) + 500
        } else if (placeSize >= 500) {
          placeSize = 500 * (AppValues.DateTime.millisecondsinYear - elapsedTime) / AppValues.DateTime.millisecondsinYear
        } else {
          placeSize = placeSize * (AppValues.DateTime.millisecondsinYear - elapsedTime) / AppValues.DateTime.millisecondsinYear
        }
        if (placeSize < 0) { placeSize = 0.0 }
        return placeSize
    }
    
    func isWithinVisibleRange(mapView: GMSMapView, ofDistance radius: Double, fromCoordinates coordinates: CLLocation) -> Bool {
        guard let lat = self.coordinates?.latitude, let long = self.coordinates?.longitude else { return false}
        let placeLoc = CLLocation(latitude: lat, longitude: long)
        return isWithinVisibleRegion(mapView: mapView) && (placeLoc.distance(from: coordinates) <= radius)
    }
    
    private func isWithinVisibleRegion(mapView: GMSMapView) -> Bool {
        guard let lat = self.coordinates?.latitude, let long = self.coordinates?.longitude else { return false}
        let region = mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(region: region)
        let placeLoc = CLLocation(latitude: lat, longitude: long)
        return bounds.contains(placeLoc.coordinate)
    }
    
    func hasChanged(withRespectToPlace place: OrbisPlace) -> Bool {
        guard place.placeKey == placeKey else { return false }
        let hasCoordinatesChanged = (coordinates?.latitude != place.coordinates?.latitude) || (coordinates?.longitude != place.coordinates?.longitude)
        let hasLastSizeChanged = lastSize != place.lastSize
        let hasLastTimeStampChanged = (self.lastCheckInTimestamp != place.lastCheckInTimestamp) || ( self.lastSizeChangeTimestamp != place.lastSizeChangeTimestamp)
        
        let dominantGroup = self.dominantGroup
        let hasDominantGroupChanged = dominantGroup?.groupKey != place.dominantGroup?.groupKey
        let hasDominantGroupPicChanged = dominantGroup?.imageName != place.dominantGroup?.imageName
        let hasDominantGroupNameChanged = dominantGroup?.name != place.dominantGroup?.name
        let hasDominantGroupColorChanged = (dominantGroup?.colorIndex != place.dominantGroup?.colorIndex) || (dominantGroup?.strokeColorHex != place.dominantGroup?.strokeColorHex)
        
        let placeParamChanged = hasCoordinatesChanged || hasLastSizeChanged || hasLastTimeStampChanged
        let groupParamChanged = hasDominantGroupChanged || hasDominantGroupPicChanged || hasDominantGroupNameChanged || hasDominantGroupColorChanged
        return placeParamChanged || groupParamChanged
    }
    
    mutating func setFollowing(value: Bool) {
        self.following = value
    }

}

//MARK: toPolygon
extension OrbisPlace {
    func toPolygonPlaceDetails() -> PolygonPlaceDetails {
        return PolygonPlaceDetails(
            coordinates: self.coordinates.map { Coordinates(latitude: $0.latitude, longitude: $0.longitude) },
            name: self.name,
            placeKey: self.placeKey,
            palindromeKey: self.palindromeKey,
            type: self.type,
            source: self.source,
            address: self.address,
            description: self.description,
            imageName: self.imageName,
            lastCheckInTimestamp: self.lastCheckInTimestamp,
            lastSizeChangeTimestamp: self.lastSizeChangeTimestamp,
            dominantGroupKey: self.dominantGroupKey,
            size: self.size,
            previousSize: self.previousSize,
            dominantGroup: self.dominantGroup?.toGroupDetails(),
            competingGroups: self.competingGroups?.map { $0.toGroupDetails() },
            following: self.following,
            website: self.website,
            phone: self.phone,
            averageRate: self.averageRate,
            totalRate: self.totalRate,
            countRates: self.countRates,
            userRate: self.userRate,
            canEdit: self.canEdit,
            workingHours: self.workingHours?.map { $0.toWorkingHoursModel() },
            places: self.places,
            polygonPoints: self.polygonPoints,
            polygonCenter: self.polygonCenter,
            touch: self.touch,
            sizeCalculated: self.sizeCalculated,
            isFocusSelected: self.isFocusSelected,
            animator: self.animator
        )
    }
}

//MARK: toPlaceDetails

extension OrbisPlace {
    func toPlaceDetails() -> PlaceDetails {
        return PlaceDetails(
            coordinates: self.coordinates?.toCoordinates(),
            name: self.name ?? "",
            placeKey: self.placeKey ?? "",
            checkInPolygonCoordinateKey: self.checkInPolygonCoordinateKey ?? "",
            type: self.type ?? "",
            source: self.source ?? "",
            address: self.address ?? "",
            description: self.description ?? "",
            imageName: self.imageName ?? "",
            lastCheckInTimestamp: self.lastCheckInTimestamp ?? "",
            dominantGroupKey: self.dominantGroupKey ?? "",
            size: self.size ?? 0.0,
            previousSize: self.lastSize ?? 0.0,
            dominantGroup: self.dominantGroup?.toGroupDetails(),
            competingGroups: self.competingGroups?.map { $0.toGroupDetails() } ?? [],
            following: self.following ?? false,
            website: self.website ?? "",
            phone: self.phone ?? "",
            averageRate: self.averageRate ?? 0.0,
            totalRate: self.totalRate ?? 0.0,
            countRates: self.countRates ?? 0,
            userRate: self.userRate ?? 0.0,
            canEdit: self.canEdit ?? false,
            workingHours: self.workingHours?.map { $0.toWorkingHoursModel() } ?? [],
            touch: false,
            animator: nil
        )
    }
}
 





