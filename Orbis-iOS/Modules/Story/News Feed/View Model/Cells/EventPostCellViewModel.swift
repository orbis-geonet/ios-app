//
//  EventPostCellViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 29/03/2021.
//

import Foundation
import UIKit

class EventPostCellViewModel: PostCellViewModel {
    var hasConfirmed: Bool = false
    var onConfirmedUsersFetched: (() -> Void)?
    let manager = EventDetailManager()
    
    private lazy var formatter = ISOCommonFormatter.shared
    
    var users: [OrbisUser] {
        return model.confirmedUsers ?? []
    }
    
    var isAttending: Bool {
        return model.attending == true
    }
    
    var eventTitle: String {
        return model.title ?? ""
    }
    
    var eventDate: String {
        guard let dateStr = model.plannedTime, let date = Date.fromString(string: dateStr, with: formatter) else { return "" }
        let startDate = date.dateString(DateFormat.eventDateFormat.rawValue)
        var eventDate = startDate
        if let endDateStr = model.plannedEndTime, let endDate = Date.fromString(string: endDateStr, with: formatter) {
            let endDateStrVal = endDate.dateString(DateFormat.eventDateFormat.rawValue)
            if startDate != endDateStrVal {
                eventDate = startDate + " - \(endDateStrVal)"
            }
        }
        return eventDate
    }
    
    var eventTime: String {
        guard let startDateStr = model.plannedTime, let startDate = Date.fromString(string: startDateStr, with: formatter) else { return "" }
        guard let endDateStr = model.plannedEndTime, let endDate = Date.fromString(string: endDateStr, with: formatter) else { return "" }
        let startTimeStr = startDate.dateString(DateFormat.eventTimeFormat.rawValue)
        let endTimeStr = endDate.dateString(DateFormat.eventTimeFormat.rawValue)
        return "\(AppStrings.Events.from) \(startTimeStr) \(AppStrings.Events.to) \(endTimeStr)"
    }
    
    var eventDescription: String {
        return model.details ?? ""
    }
    
    var eventImageLink: String {
        return model.mediaUrls?.first ?? ""
    }
    
    func fetchConfirmedUsers() {
        manager.fetchAttendees(forEvent: model.postKey!, page: 0, size: 3) { [weak self] data, err in
            if let users = data as? OrbisUsers {
                self?.model.confirmedUsers = users
                self?.onConfirmedUsersFetched?()
            }
            else if let error = err {
                debugPrint("Error in fetching quick event attendees \(error.localizedDescription)")
            }
        }
    }
}
