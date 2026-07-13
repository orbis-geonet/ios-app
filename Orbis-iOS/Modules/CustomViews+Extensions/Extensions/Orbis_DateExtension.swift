//
//  Orbis_DateExtension.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 18/04/2021.
//

import Foundation

enum DateFormat: String {
    case monthNameDayYear12hrTime = "MMM-dd-yyyy, hh:mm a"
    case monthNameDayYear24hrTime = "MMM-dd-yyyy, HH:mm"
    case postDateTimestampFormat = "MM/dd/yy 'at' HH:mm"
    case eventDateFormat = "MM/dd/yy"
    case eventTimeFormat = "HH:mm"
    case normalDateFormat = "MM/dd/yyyy"
}

extension ISO8601DateFormatter {
    convenience init(_ formatOptions: Options) {
        self.init()
        self.formatOptions = formatOptions
    }
}

extension Formatter {
    static let iso8601withFractionalSeconds = ISO8601DateFormatter([.withInternetDateTime, .withFractionalSeconds])
}

extension Date {
    
    var isoDateString: String {
        return ISOCommonFormatter.shared.string(from: self)
    }
    
    func dateString(_ format: String = "MMM-dd-YYYY, hh:mm a") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
    func dateByAddingYears(_ dYears: Int) -> Date {
        
        var dateComponents = DateComponents()
        dateComponents.year = dYears
        
        return Calendar.current.date(byAdding: dateComponents, to: self)!
    }
    
    func dateByAddingDay(_ day: Int) -> Date {
        
        var dateComponents = DateComponents()
        dateComponents.day = day
        
        return Calendar.current.date(byAdding: dateComponents, to: self)!
    }
    
    static func fromString(dateString: String, format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: dateString)
    }
    
    static func fromString(string: String, with formatter: ISO8601DateFormatter) -> Date? {
        let newDateStr = string.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression)
        return formatter.date(from: newDateStr)
    }
    
    var iso8601withFractionalSeconds: String { return Formatter.iso8601withFractionalSeconds.string(from: self) }
    
    var unixTimestamp: Double {
        return (self.timeIntervalSince1970 * 1_000) // millisecond precision
    }
    
    func timeAgoSinceNow(activeString: String = AppStrings.Messaging.justNow, prefix: String = "") -> String {
        let calendar = Calendar.current
        let now = Date()
        let earliest = (now as NSDate).earlierDate(self)
        let latest = (earliest == now) ? self : now
        let components:DateComponents = (calendar as NSCalendar).components([NSCalendar.Unit.minute , NSCalendar.Unit.hour , NSCalendar.Unit.day , NSCalendar.Unit.weekOfYear , NSCalendar.Unit.month , NSCalendar.Unit.year , NSCalendar.Unit.second], from: earliest, to: latest, options: NSCalendar.Options())
        
        if (components.year! >= 2) {
            return "\(prefix)\(components.year!) \(AppStrings.Messaging.TimeFormat.yearsAgo)"
        } else if (components.year! >= 1){
            return "\(prefix)1 \(AppStrings.Messaging.TimeFormat.yearAgo)"
        } else if (components.month! >= 2) {
            return "\(prefix)\(components.month!) \(AppStrings.Messaging.TimeFormat.monthsAgo)"
        } else if (components.month! >= 1){
            return "\(prefix)1 \(AppStrings.Messaging.TimeFormat.monthAgo)"
        } else if (components.weekOfYear! >= 2) {
            return "\(prefix)\(components.weekOfYear!) \(AppStrings.Messaging.TimeFormat.weeksAgo)"
        } else if (components.weekOfYear! >= 1){
            return "\(prefix)1 \(AppStrings.Messaging.TimeFormat.weekAgo)"
        } else if (components.day! >= 2) {
            return "\(prefix)\(components.day!) \(AppStrings.Messaging.TimeFormat.daysAgo)"
        } else if (components.day! >= 1){
            return "\(prefix)1 \(AppStrings.Messaging.TimeFormat.dayAgo)"
        } else if (components.hour! >= 2) {
            return "\(prefix)\(components.hour!) \(AppStrings.Messaging.TimeFormat.hoursAgo)"
        } else if (components.hour! >= 1){
            return "\(prefix)1 \(AppStrings.Messaging.TimeFormat.hourAgo)"
        } else if (components.minute! >= 2) {
            return "\(prefix)\(components.minute!) \(AppStrings.Messaging.TimeFormat.minutesAgo)"
        } else if (components.minute! >= 1){
            return "\(prefix)1 \(AppStrings.Messaging.TimeFormat.minuteAgo)"
        } else if (components.second! >= 3) {
            return "\(prefix)\(components.second!) \(AppStrings.Messaging.TimeFormat.secondsAgo)"
        } else {
            return activeString
        }
    }
}
