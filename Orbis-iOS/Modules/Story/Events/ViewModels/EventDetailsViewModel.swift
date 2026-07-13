//
//  EventDetailsViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 18/04/2021.
//

import Foundation
import Alamofire

class EventDetailsViewModel {
    var model: OrbisFeedPost!
    let manager = EventDetailManager()
    
    private lazy var formatter = ISOCommonFormatter.shared
    
    var hasConfirmed: Bool {
        set {
            model.attending = newValue
        }
        get {
            return model.attending ?? false
        }
    }
    
    init(event: OrbisFeedPost) {
        self.model = event
        initializeConfirmedUserPagination()
    }
    
    var onConfirmedUsersFetched: (() -> Void)?
    var onConfirmedUsersFetchedCompletePagination: (() -> Void)?
    var onConfirmedUsersFetchError: ((Error) -> Void)?
    
    var hasConfirmedPageReachedLast = false
    var confirmedListPage = 0
    var confirmListSize = 20
    
    var userCount: Int {
        return users.count
    }
    
    var confirmedCount: Int {
        return model.confirmedCount ?? users.count
    }
    
    var users = OrbisUsers()
    
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
    
    var eventAddress: String {
        return model.address ?? model.place?.name ?? ""
    }
    
    var eventDescription: String {
        return model.details ?? ""
    }
    
    var eventImageLink: String {
        return model.mediaUrls?.first ?? ""
    }
    
    func getUser(at index: Int) -> OrbisUser {
        return users[index]
    }
    
    func initializeConfirmedUserPagination() {
        users = []
        confirmedListPage = 0
        hasConfirmedPageReachedLast = false
    }
    
    func loadConfirmedUsers() {
        self.manager.fetchAttendees(forEvent: model.postKey!, page: confirmedListPage, size: confirmListSize) { [weak self] (data, err) in
            guard let self = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                        return
                    }
                    if let afError = error as? AFError {
                        if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                            return
                        }
                    }
                    self.onConfirmedUsersFetchError?(error)
                    return
                }
                else {
                    if let items = data as? OrbisUsers {
                        if items.count > 0 {
                            self.users = items
                            self.onConfirmedUsersFetched?()
                            self.confirmedListPage += 1
                            self.hasConfirmedPageReachedLast = false
                        }
                        else {
                            self.hasConfirmedPageReachedLast = true
                            self.onConfirmedUsersFetchedCompletePagination?()
                        }
                    }
                    else {
                        self.onConfirmedUsersFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
    
    func loadMoreConfirmedUsers() {
        self.manager.fetchAttendees(forEvent: model.postKey!, page: confirmedListPage, size: confirmListSize)  { [weak self] (data, err) in
            guard let self = self else { return }
                if let error = err {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled || nsError.description.contains("Code=\(NSURLErrorCancelled)") {
                        return
                    }
                    if let afError = error as? AFError {
                        if afError.responseCode == AFError.explicitlyCancelled.responseCode {
                            return
                        }
                    }
                    self.onConfirmedUsersFetchError?(error)
                    return
                }
                else {
                    if let items = data as? OrbisUsers {
                        if items.count > 0 {
                            self.users.append(contentsOf: items)
                            self.onConfirmedUsersFetched?()
                            self.confirmedListPage += 1
                            self.hasConfirmedPageReachedLast = false
                        }
                        else {
                            self.hasConfirmedPageReachedLast = true
                            self.onConfirmedUsersFetchedCompletePagination?()
                        }
                    }
                    else {
                        self.onConfirmedUsersFetchError?(ResponseError.invalidData)
                        return
                    }
                }
        }
    }
    
    func attendCancelAttendEvent(completion: @escaping responseBlock) {
        if model.attending == true {
            manager.cancelAttendEvent(key: model.postKey!) { [weak self] data, err in
                if let error = err {
                    completion(nil, error)
                }
                else {
                    self?.hasConfirmed = false
                    self?.users.removeAll(where: {$0.userKey == UserSessionManager.shared.currentUser?.userKey})
                    completion(true, nil)
                }
            }
        }
        else {
            manager.attendEvent(key: model.postKey!) { [weak self] data, err in
                if let error = err {
                    completion(nil, error)
                }
                else {
                    self?.hasConfirmed = true
                    if let user = UserSessionManager.shared.currentUser, (self?.users.contains(where: {$0.userKey == user.userKey}) == false) {
                        self?.users.insert(user, at: 0)
                    }
                    completion(true, nil)
                }
            }
        }
    }
}
