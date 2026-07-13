//
//  PlaceRatePopupViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 13/08/2023.
//

import Foundation

class PlaceRatePopupViewModel {
    let model: OrbisPlace!
    let manager = OrbisPlaceDetailManager()
    var isLoading = false
    
    var onPlaceRateError: ((Error) -> Void)?
    var onPlaceRateSuccess: (() -> Void)?
    
    init(place: OrbisPlace) {
        self.model = place
    }
    
    var userRating: Double {
        return model.userRate ?? 0
    }
    
    func ratePlace(withRating rating: Int) {
        isLoading = true
        manager.ratePlace(placeKey: self.model.placeKey!, rating: rating) { [weak self] (data, err) in
            self?.isLoading = false
            if let error = err {
                self?.onPlaceRateError?(error)
                return
            }
            self?.onPlaceRateSuccess?()
        }
    }
}
