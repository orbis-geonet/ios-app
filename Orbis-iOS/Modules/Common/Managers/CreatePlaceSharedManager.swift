//
//  CreatePlaceSharedManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 19/05/2021.
//

import Foundation

class CreatePlaceSharedManager {
    static let shared = CreatePlaceSharedManager()
    
    private var blockedNewlyCreatedPlaceIds = [String]()
    var sizeChangeWaitingBuffer = [PlaceSizesChildChangedResult]()
    
    var blockedPlaceIdsCount: Int {
        return blockedNewlyCreatedPlaceIds.count
    }
    
    func newlyCreatedListContains(key: String) -> Bool {
        return blockedNewlyCreatedPlaceIds.contains(key)
    }
    
    func addPlaceIdToNewlyBlockedObserver(placeKey: String) {
        if !blockedNewlyCreatedPlaceIds.contains(placeKey) {
            blockedNewlyCreatedPlaceIds.append(placeKey)
        }
    }
    
    func removePlaceIdFromNewlyBlockedObserver(placeKey: String) {
        blockedNewlyCreatedPlaceIds.removeAll(where: {$0 == placeKey})
    }
}
