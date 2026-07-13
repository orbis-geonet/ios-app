//
//  PlaceScheduleUpdateViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 14/08/2023.
//

import Foundation

class PlaceScheduleUpdateViewModel {
    var place: OrbisPlace!
    private let manager = OrbisPlaceDetailManager()
    
    var isUpdating = false
    var onPlaceDetailUpdateError: ((Error) -> Void)?
    var onPlaceDetailUpdateSuccess: ((OrbisPlace) -> Void)?
    
    private var placeOpeningSchedules: OrbisPlaceWorkingDays {
        return place.workingHours?.filter({ $0.weekDay != nil }).sorted(by: { $0.weekDay!.displayIndex < $1.weekDay!.displayIndex }) ?? []
    }
    
    var weekDays: [OrbisDaysOfWeek]!
    
    init(model: OrbisPlace) {
        self.place = model
        self.weekDays = OrbisDaysOfWeek.allCases.sorted(by: { $0.displayIndex < $1.displayIndex })
    }
    
    var viewTitle: String {
        return AppStrings.Places.updateScheduleTitle
    }
    
    var errorMessage: String {
        return AppErrorStrings.fixHighlightedError
    }
    
    var editActionTitle: String {
        return AppStrings.save
    }
    
    var count: Int {
        return weekDays.count
    }
    
    func getItem(at index: Int) -> OrbisPlaceWorkingHours {
        let weekday = weekDays[index]
        if let existingWorkingHours = placeOpeningSchedules.first(where: {$0.weekDay?.rawValue == weekday.rawValue}) {
            return existingWorkingHours
        }
        return OrbisPlaceWorkingHours(day: String(weekday.rawValue))
    }
    
    func updateDayTime(model: OrbisPlaceWorkingHours, time: String, isCloseTime: Bool) {
        var existingSchedule = place.workingHours ?? []
        var updatedModel = model
        let scheduleTime = isCloseTime ? "\(model.startTime) - \(time)" : "\(time) - \(model.endTime)"
        updatedModel.time = scheduleTime
        if let index = existingSchedule.firstIndex(where: { $0.weekDay?.rawValue == model.weekDay?.rawValue }) {
            existingSchedule[index] = updatedModel
        } else {
            existingSchedule.append(updatedModel)
        }
        place.workingHours = existingSchedule.sorted(by: { $0.weekDay!.rawValue < $1.weekDay!.rawValue })
    }
    
    func checkIfValidScheduleEntries() -> Bool {
        var isValid = true
        for schedule in placeOpeningSchedules {
            if (schedule.startTime.isEmpty && !schedule.endTime.isEmpty) || (!schedule.startTime.isEmpty && schedule.endTime.isEmpty) {
                isValid = false
                break
            }
        }
        return isValid
    }
}

extension PlaceScheduleUpdateViewModel {
    
    func updatePlaceSchedule() {
        var dictValues: [[String: Any]] = []
        placeOpeningSchedules.forEach { hours in
            dictValues.append((try? hours.toDictionary()) ?? [:])
        }
        let param: [String: Any] = [PlaceDomainParameterKeys.Update.workingHours: dictValues]
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
