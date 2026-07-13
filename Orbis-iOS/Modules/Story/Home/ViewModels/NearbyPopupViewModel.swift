//
//  NearbyPopupViewModel.swift
//  Orbis-iOS
//
//  Created by Zohaib Ahmad on 12/06/2026.
//

import Foundation
import Foundation
import Combine


import Foundation

struct NearbyTribePopupData {
    let group: Group
    let memberImageUrls: [String]
}

final class NearbyPopupViewModel {

    private let manager = GroupDetailManager()

    // Main-thread confined (all callers + dispatchGroup.notify run on main). The popup refires on
    // every crosshair closest-tribe change, so revisits must be free: successful results are cached
    // per groupKey for the session, and concurrent requests for the same tribe coalesce onto one
    // network fetch instead of stacking duplicates while the user pans back and forth.
    private var cache: [String: NearbyTribePopupData] = [:]
    private var pending: [String: [(Result<NearbyTribePopupData, Error>) -> Void]] = [:]

    // Card shows at most 3 member avatars; small page instead of the old limit=200 (which decoded
    // two hundred user records per popup). 10 leaves headroom for members without an imageName.
    private static let memberFetchLimit = 10

    func fetchPopupData(
        groupKey: String,
        fallbackGroup: Group? = nil,
        completion: @escaping (Result<NearbyTribePopupData, Error>) -> Void
    ) {
        if let cached = cache[groupKey] {
            completion(.success(cached))
            return
        }

        if pending[groupKey] != nil {
            pending[groupKey]?.append(completion)
            return
        }
        pending[groupKey] = [completion]

        var fetchedGroup: Group?
        var fetchedMembers: OrbisUsers?
        var membersError: Error?

        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        manager.syncGroupDetail(forGroup: groupKey) { data, error in
            if error == nil {
                fetchedGroup = data as? Group
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        manager.fetchGroupMembers(forGroup: groupKey, page: 0, limit: Self.memberFetchLimit) { data, error in
            if let error {
                membersError = error
            } else {
                fetchedMembers = data as? OrbisUsers
            }
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self else { return }
            let waiters = self.pending.removeValue(forKey: groupKey) ?? []

            // Members are what the card is missing without a fetch (avatars); the group header is
            // already rendered from local place data. So: members failed -> report failure (caller
            // retries); members OK but group detail failed -> degrade to the local fallback group
            // instead of throwing the avatars away. Only a FULL success is cached.
            let result: Result<NearbyTribePopupData, Error>
            if let members = fetchedMembers {
                let imageUrls = members
                    .compactMap { $0.imageName }
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .prefix(3)
                if let group = fetchedGroup {
                    let data = NearbyTribePopupData(group: group, memberImageUrls: Array(imageUrls))
                    self.cache[groupKey] = data
                    result = .success(data)
                } else if let group = fallbackGroup {
                    result = .success(NearbyTribePopupData(group: group, memberImageUrls: Array(imageUrls)))
                } else {
                    result = .failure(ResponseError.invalidData)
                }
            } else {
                result = .failure(membersError ?? ResponseError.invalidData)   // not cached — retried
            }

            for waiter in waiters { waiter(result) }
        }
    }

    func cancel() {
        // no-op for now
    }
}
