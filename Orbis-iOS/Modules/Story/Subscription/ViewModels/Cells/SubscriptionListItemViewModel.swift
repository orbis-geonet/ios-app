//
//  SubscriptionListItemViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 07/01/2023.
//

import Foundation

class SubscriptionListItemViewModel {
    var model: GroupSubscriptionModel!
    var group: Group!
    
    init(model: GroupSubscriptionModel, group: Group) {
        self.model = model
        self.group = group
    }
    
    var name: String {
        return model.name ?? ""
    }
    
    var description: String {
        return model.description ?? ""
    }
    
    var isSubscriptionSinglePurchase: Bool {
        return model.type == GroupSubscriptionType.oneTime.rawValue
    }
    
    private var totalPrice: Double {
        return model.price ?? 0
    }
    
    var hasAttachments: Bool {
        return (model.imagesName?.count ?? 0) >= 1
    }
    
    private var paymentPrice: Double {
        guard let type = model.type else { return totalPrice }
        guard let subscriptionType = GroupSubscriptionType(rawValue: type) else { return totalPrice }
        switch subscriptionType {
        case .interval:
            guard let period = model.period, period >= AppValues.Subscription.installmentMinPeriod else { return totalPrice }
            return totalPrice / Double(period)
        default:
            return totalPrice
        }
    }
    
    var price: String {
        return paymentPrice.rounded(toPlaces: 2).formattedWithSeparator(decimalSeparator: ",", groupingSeparator: ".")
    }
    
    var paymentDurationString: String {
        guard let type = model.type else { return AppStrings.Subscription.durationMonthlyText }
        guard let subscriptionType = GroupSubscriptionType(rawValue: type) else { return AppStrings.Subscription.durationMonthlyText }
        switch subscriptionType {
        case .unlimited:
            guard let interval = model.interval, let subsInterval = GroupSubscriptionPaymentInterval(rawValue: interval) else { return AppStrings.Subscription.durationMonthlyText }
            switch subsInterval {
            case .monthly:
                return AppStrings.Subscription.durationMonthlyText
            case .yearly:
                return AppStrings.Subscription.durationYearlyText
            }
        case .interval:
            return AppStrings.Subscription.durationMonthlyText
        case .oneTime:
            return ""
        }
    }
    
    var paymentInfoExtra: String {
        guard let type = model.type else { return "" }
        guard let subscriptionType = GroupSubscriptionType(rawValue: type) else { return "" }
        switch subscriptionType {
        case .interval:
            guard let period = model.period, period >= AppValues.Subscription.installmentMinPeriod else { return "" }
            let totalString = currency + " " + totalPrice.rounded(toPlaces: 2).formattedWithSeparator(decimalSeparator: ",", groupingSeparator: ".")
            return String(format: AppStrings.Subscription.paymentInstallmentExtraInfo, "\(period)", totalString)
        default:
            return ""
        }
    }
    
    var currency: String {
        return model.currency?.uppercased().toCurrencySymbol ?? ""
    }
    
    var benefits: [String] {
        return model.benefit ?? []
    }
    
    var benefitsCount: Int {
        return benefits.count
    }
    
    var isMainAdmin: Bool {
        return group.isMainAdmin ?? false
    }
    
    var isSubscriber: Bool {
        return model.isSubscriber ?? false
    }
}
