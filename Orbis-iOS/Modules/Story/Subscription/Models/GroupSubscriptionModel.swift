//
//  GroupSubscriptionModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 06/01/2023.
//

import Foundation

enum GroupSubscriptionType: String {
    case unlimited = "UNLIMITED"
    case interval = "INTERVAL"
    case oneTime = "ONE_TIME"
}

enum GroupSubscriptionPaymentInterval: String {
    case monthly = "MONTH"
    case yearly = "YEAR"
}

enum GroupSubscriptionPaymentFrequency: String, CaseIterable {
    case yearly
    case monthly
    case single
    case installment
    
    var displayIndex: Int {
        switch self {
        case .yearly:
            return 1
        case .monthly:
            return 2
        case .single:
            return 4
        case .installment:
            return 3
        }
    }
    
    var displayText: String {
        switch self {
        case .yearly:
            return "Yearly".localized
        case .monthly:
            return "Monthly".localized
        case .single:
            return "One Time".localized
        case .installment:
            return "Payment in installments".localized
        }
    }
    
    var subscriptionType: GroupSubscriptionType {
        switch self {
        case .yearly:
            return .unlimited
        case .monthly:
            return .unlimited
        case .single:
            return .oneTime
        case .installment:
            return .interval
        }
    }
    
    var paymentInterval: GroupSubscriptionPaymentInterval? {
        switch self {
        case .yearly:
            return .yearly
        case .monthly, .installment:
            return .monthly
        default:
            return .monthly
        }
    }
}

typealias GroupSubscriptions = [GroupSubscriptionModel]

class GroupSubscriptionModel: Codable {
    var subscriptionKey: String?
    var name: String?
    var description: String?
    var groupKey: String?
    var groupName: String?
    var price: Double?
    var originalPrice: Double?
    var currency: String?
    var type: String?
    var period: Int?
    var interval: String?
    var benefit: [String]?
    var imagesName: [String]?
    var isSubscriber: Bool?
    
    enum CodingKeys: String, CodingKey {
        case subscriptionKey
        case name
        case description
        case groupKey
        case groupName
        case price
        case originalPrice
        case currency
        case type
        case period
        case interval
        case benefit
        case imagesName
        case isSubscriber
    }
    
    init(key: String) {
        self.subscriptionKey = key
    }
    
    static func copyFrom(model: GroupSubscriptionModel) -> GroupSubscriptionModel {
        let copyModel = GroupSubscriptionModel(key: model.subscriptionKey!)
        copyModel.name = model.name
        copyModel.description = model.description
        copyModel.groupKey = model.groupKey
        copyModel.groupName = model.groupName
        copyModel.price = model.price
        copyModel.originalPrice = model.originalPrice
        copyModel.currency = model.currency
        copyModel.type = model.type
        copyModel.period = model.period
        copyModel.interval = model.interval
        copyModel.benefit = model.benefit
        copyModel.imagesName = model.imagesName
        copyModel.isSubscriber = model.isSubscriber
        return copyModel
    }
}

typealias GroupConsumedSubscriptions = [GroupConsumedSubscription]

class GroupConsumedSubscription: Codable {
    var subscriptionKey: String?
    var name: String?
    var description: String?
    var groupKey: String?
    var groupName: String?
    var price: Double?
    var originalPrice: Double?
    var currency: String?
    var type: String?
    var period: Int?
    var interval: String?
    var benefit: [String]?
    var imagesName: [String]?
    var isSubscriber: Bool?
    var codes: [String]?
    
    enum CodingKeys: String, CodingKey {
        case subscriptionKey
        case name
        case description
        case groupKey
        case groupName
        case price
        case originalPrice
        case currency
        case type
        case period
        case interval
        case benefit
        case imagesName
        case isSubscriber
        case codes
    }
    
    init(key: String) {
        self.subscriptionKey = key
    }
    
    static func copyFrom(model: GroupConsumedSubscription) -> GroupConsumedSubscription {
        let copyModel = GroupConsumedSubscription(key: model.subscriptionKey!)
        copyModel.name = model.name
        copyModel.description = model.description
        copyModel.groupKey = model.groupKey
        copyModel.groupName = model.groupName
        copyModel.price = model.price
        copyModel.originalPrice = model.originalPrice
        copyModel.currency = model.currency
        copyModel.type = model.type
        copyModel.period = model.period
        copyModel.interval = model.interval
        copyModel.benefit = model.benefit
        copyModel.imagesName = model.imagesName
        copyModel.isSubscriber = model.isSubscriber
        copyModel.codes = model.codes
        return copyModel
    }
}

struct GroupSubscriptionStatistic: Codable {
    var resultList: [GroupSubscriptionStatisticData]?
    var totalNumber: Int?
    var totalAmount: Double?
    
}

struct GroupSubscriptionStatisticData: Codable {
    var columnName: String?
    var number: Int?
    var amount: Double?
}
