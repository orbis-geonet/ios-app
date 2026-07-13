//
//  GroupDao.swift
//  Orbis-iOS
//
//  Created by Kamran on 02/11/2024.
//


import RealmSwift

class GroupDao {
    
    // Remove the shared `realm` instance; instead, initialize it per method
    private func getRealm() -> Realm {
        return try! Realm() // Ensure each thread gets its own Realm instance
    }
    
    func getCachedGroups(city: String, loggedIn: Bool) -> [GroupEntity] {
        let realm = getRealm() // Get a thread-safe Realm instance
        let results = realm.objects(GroupEntity.self)
            .filter("city == %@ AND fromLoggedUser == %@", city, loggedIn)
        return Array(results)
    }

    func insertGroups(groups: [GroupEntity]) {
        let realm = getRealm() // Get a thread-safe Realm instance
        do {
            try realm.write {
                realm.add(groups, update: .modified)
            }
        } catch {
            print("Error inserting groups: \(error)")
        }
    }

    func deleteCachedGroups(city: String, loggedIn: Bool) {
        let realm = getRealm() // Get a thread-safe Realm instance
        let results = realm.objects(GroupEntity.self)
            .filter("city == %@ AND fromLoggedUser == %@", city, loggedIn)
        do {
            try realm.write {
                realm.delete(results)
            }
        } catch {
            print("Error deleting cached groups: \(error)")
        }
    }

    func updateGroups(groups: [GroupEntity]) {
        let realm = getRealm() // Get a thread-safe Realm instance
        do {
            try realm.write {
                for group in groups {
                    realm.add(group, update: .modified)
                }
            }
        } catch {
            print("Error updating groups: \(error)")
        }
    }

    func updateGroup(group: GroupEntity) {
        let realm = getRealm() // Get a thread-safe Realm instance
        do {
            try realm.write {
                realm.add(group, update: .modified)
            }
        } catch {
            print("Error updating group: \(error)")
        }
    }
}

