//
//  Int+Formatter.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 30/03/2021.
//

import Foundation

extension Array {
    subscript (randomPick n: Int) -> [Element] {
        var indices = [Int](0..<count)
        var randoms = [Int]()
        for _ in 0..<n {
            randoms.append(indices.remove(at: Int(arc4random_uniform(UInt32(indices.count)))))
        }
        return randoms.map { self[$0] }
    }
}

extension Formatter {
    static func withSeparator(decimalSeparator: String, groupingSeparator: String) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = decimalSeparator
        formatter.groupingSeparator = groupingSeparator
        formatter.minimumFractionDigits = 2
        return formatter
    }
    
    static func withIntegerSeparator(groupingSeparator: String) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = groupingSeparator
        return formatter
    }
    
    static func withSeparator(decimalSeparator: String, groupingSeparator: String, places: Int = 2) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = decimalSeparator
        formatter.groupingSeparator = groupingSeparator
        formatter.minimumFractionDigits = places
        return formatter
    }
}

extension Double {
    var formattedWithSeparator: String {
        let lngCode = UIUtil.getCurrentLanguageCode()
        var decimalSeparator = "."
        var groupingSeparator = ","
        if lngCode == "it" || lngCode == "fr" || lngCode == "pt" {
            decimalSeparator = ","
            groupingSeparator = "."
        }
        return Formatter.withSeparator(decimalSeparator: decimalSeparator, groupingSeparator: groupingSeparator).string(for: self) ?? ""
    }
    
    func formattedWithSeparator(decimalSeparator: String, groupingSeparator: String) -> String {
        return Formatter.withSeparator(decimalSeparator: decimalSeparator, groupingSeparator: groupingSeparator).string(for: self) ?? ""
    }
    
    func asDurationString(style: DateComponentsFormatter.UnitsStyle) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second, .nanosecond]
        formatter.unitsStyle = style
        guard let formattedString = formatter.string(from: self) else { return "" }
        return formattedString
    }
    
    func toDurationString() -> String {
        var val = self
        if self.isNaN {
            val = 0
        }
        let minute = Int(val) / 60
        let second = Int(val) % 60
        
        // return formated string
        return String(format: "%02i:%02i", minute, second)
    }
    
    func epochToChatDateString() -> String {
        let date = Date(timeIntervalSince1970: self/1000)
        let calendar = Calendar.current
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        else if calendar.isDateInToday(date) { return "Today" }
        return date.dateString("MMM d yyyy")
    }
    
    func epochToChatTimeString() -> String {
        let date = Date(timeIntervalSince1970: self/1000)
        let timeString = date.dateString("hh:mm a")
        return timeString
    }
    
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    var roundedString: String {
        return "\(self.rounded(toPlaces: 2).stringWithoutZeroFraction)"
    }
    
    var stringWithoutZeroFraction: String {
        return truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
    
    func roundedStringWithoutZeroFraction(toPlaces places: Int = 2) -> String {
        return truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self.rounded(toPlaces: places))
    }
    
    static func getQuantifier(for value: Double) -> String {
        let divident = Int(value / 1000)
        if divident < 1000 {
            return "K"
        }
        else if divident >= 1000 && divident < 1000000 {
            return "M"
        }
        else if divident >= 1000000 && divident < 1000000000 {
            return "B"
        }
        else {
            return "T"
        }
    }
    
    func formattedForLargeNumber(toDecimal place: Int = 2) -> String {
        let lngCode = UIUtil.getCurrentLanguageCode()
        var decimalSeparator = "."
        var groupingSeparator = ","
        var places = self.truncatingRemainder(dividingBy: 1) == 0 ? 0 : place
        if lngCode == "it" || lngCode == "fr" || lngCode == "pt" {
            decimalSeparator = ","
            groupingSeparator = "."
        }
        if self >= 10000 {
            let quantifier = Double.getQuantifier(for: self)
            var shortVal: Double = 0
            switch quantifier {
            case "K":
                shortVal = self / 1000
            case "M":
                shortVal = self / 1000000
            case "B":
                shortVal = self / 1000000000
            case "T":
                shortVal = self / 1000000000000
            default:
                shortVal = 0
            }
            places = shortVal.truncatingRemainder(dividingBy: 1) == 0 ? 0 : place
            if let numStr = Formatter.withSeparator(decimalSeparator: decimalSeparator, groupingSeparator: groupingSeparator, places: places).string(for: shortVal.rounded(toPlaces: places)) {
                return numStr + " \(quantifier)"
            }
            return "n/a"
        }
        return Formatter.withSeparator(decimalSeparator: decimalSeparator, groupingSeparator: groupingSeparator, places: places).string(for: self.rounded(toPlaces: places)) ?? "n/a"
    }
}

extension Int {
    var formattedWithSeparator: String {
        let lngCode = UIUtil.getCurrentLanguageCode()
        var groupingSeparator = ","
        if lngCode == "it" || lngCode == "fr" || lngCode == "pt" {
            groupingSeparator = "."
        }
        return Formatter.withIntegerSeparator(groupingSeparator: groupingSeparator).string(from: NSNumber(value: self)) ?? ""
    }
}
