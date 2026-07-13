//
//  UserPurchaseModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 21/08/2023.
//

import Foundation

typealias UserPurchases = [UserPurchaseModel]

struct UserPurchaseModel: Codable {
    var name: String?
    var groupKey: String?
    var groupName: String?
    var price: Double?
    var currency: String?
    var number: Int?
    var codes: [String]?
}

typealias GroupPurchases = [GroupPurchaseModel]

struct GroupPurchaseModel: Codable {
    var name: String?
    var group: Group?
    var user: GroupSubscriber?
    var price: Double?
    var currency: String?
    var number: Int?
    var codes: [String]?
    
    var toGroupSubscriber: GroupSubscriber {
        let subscriber = self.user ?? GroupSubscriber()
        subscriber.codes = self.codes
        return subscriber
    }
    
    var toUserPurchaseModel: UserPurchaseModel {
        var model = UserPurchaseModel()
        model.name = self.name
        model.groupKey = self.group?.groupKey
        model.groupName = self.group?.name
        model.price = self.price
        model.currency = self.currency
        model.number = self.number
        model.codes = self.codes
        return model
    }
}
