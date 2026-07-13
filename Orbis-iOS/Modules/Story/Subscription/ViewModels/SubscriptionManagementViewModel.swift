//
//  SubscriptionManagementViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 08/01/2023.
//

import Foundation

class SubscriptionManagementViewModel {
    var subscription: GroupSubscriptionModel?
    let manager = GroupSubscriptionManager()
    let adminManager = AdminSubscriptionManager()
    
    var statModel: GroupSubscriptionStatistic?
    
    var graphSubscribersStatData: [[String: CGFloat]] {
        let graphData = statModel?.resultList ?? []
        return graphData.map { data in
            return [data.columnName ?? "": (data.number ?? 0).toCGFloat]
        }
    }
    
    var graphRevenueStatData: [[String: CGFloat]] {
        let graphData = statModel?.resultList ?? []
        return graphData.map { data in
            return [data.columnName ?? "": CGFloat(data.amount ?? 0.0)]
        }
    }
    
    var minSubscriberValue: CGFloat {
        return graphSubscribersStatData.compactMap { dict in
            return dict.values.first ?? 0
        }.min() ?? 0
    }
    
    var maxSubscriberValue: CGFloat {
        return graphSubscribersStatData.compactMap { dict in
            return dict.values.first ?? 0
        }.max() ?? 0
    }
    
    var minRevenueValue: CGFloat {
        return graphRevenueStatData.compactMap { dict in
            return CGFloat(floor(dict.values.first ?? 0))
        }.min() ?? 0
    }
    
    var maxRevenueValue: CGFloat {
        return graphRevenueStatData.compactMap { dict in
            return CGFloat(ceil(dict.values.first ?? 0))
        }.max() ?? 0
    }
    
    var groupModel: Group!
    var groupKey: String {
        return groupModel.groupKey ?? ""
    }
    
    init(group: Group) {
        self.groupModel = group
    }
    
    var selectedFilterIndex = 0
    
    var isSubscriptionSinglePurchase: Bool {
        return subscription?.type == GroupSubscriptionType.oneTime.rawValue
    }
    
    var graphFilterValues: [SubscriptionGraphFilterValue] {
        return SubscriptionGraphFilterValue.allCases
    }
    
    var graphFilterValuesCount: Int {
        return graphFilterValues.count
    }
    
    var subscriptionName: String {
        return subscription?.name ?? ""
    }
    
    var totalSubscribers: String {
        return statModel?.totalNumber?.formattedWithSeparator ?? ""
    }
    
    var totalRevenue: String {
        let priceString = statModel?.totalAmount?.rounded(toPlaces: 2).formattedWithSeparator(decimalSeparator: ",", groupingSeparator: ".") ?? "0"
        return AppValues.StripeAccountCreationDefaults.defaultCurrency.toCurrencySymbol + priceString
    }
    
    func fetchStatData(completion: @escaping responseBlock) {
        guard let subsKey = subscription?.subscriptionKey else {
            completion(nil, nil)
            return
        }
        if isSubscriptionSinglePurchase {
            fetchPurchaseStatData(subscriptionKey: subsKey, completion: completion)
            return
        }
        manager.getGroupSubscriptionStatistic(groupKey: groupKey, subscriptionKey: subsKey, type: graphFilterValues[self.selectedFilterIndex]) { [weak self] result, error in
            if let statModel = result as? GroupSubscriptionStatistic {
                self?.statModel = statModel
            }
            completion(result, error)
        }
    }
    
    private func fetchPurchaseStatData(subscriptionKey: String, completion: @escaping responseBlock) {
        manager.getGroupPurchaseStatistic(groupKey: groupKey, subscriptionKey: subscriptionKey, type: graphFilterValues[self.selectedFilterIndex]) { [weak self] result, error in
            if let statModel = result as? GroupSubscriptionStatistic {
                self?.statModel = statModel
            }
            completion(result, error)
        }
    }
}
