//
//  PurchaseCodePopupViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 21/08/2023.
//

import Foundation

class PurchaseCodePopupViewModel {
    var model: UserPurchaseModel!
    
    init(model: UserPurchaseModel!) {
        self.model = model
    }
    
    var viewTitle: String {
        return AppStrings.Subscription.purchasedCodesText
    }
    
    private var codes: [String] {
        return self.model.codes ?? []
    }
    
    var count: Int {
        return codes.count
    }
    
    func getCode(at index: Int) -> String {
        return codes[index]
    }
}
