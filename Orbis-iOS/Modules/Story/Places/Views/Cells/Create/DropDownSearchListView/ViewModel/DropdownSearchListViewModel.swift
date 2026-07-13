//
//  DropdownSearchListViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 04/04/2021.
//

import Foundation

class DropdownSearchListViewModel {
    var users = OrbisUsers()
    var groups = Groups()
    
    init(users: OrbisUsers, groups: Groups) {
        self.users = users
        self.groups = groups
    }
    
    var sectionCount: Int {
        return 2
    }
    
    func count(inSection section: Int) -> Int {
        if section == 0 {
            return users.count
        }
        else if section == 1 {
            return groups.count
        }
        return 0
    }
    
    func getUser(at index: Int) -> OrbisUser {
        return users[index]
    }
    
    func getGroup(at index: Int) -> Group {
        return groups[index]
    }
}
