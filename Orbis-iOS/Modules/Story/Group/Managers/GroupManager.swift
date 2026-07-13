//
//  GroupManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 30/03/2021.
//

import Foundation
import UIKit
import CoreLocation

typealias GroupSearchResult = (groups: Groups, searchText: String)

class GroupManager {
    static let shared = GroupManager()
    let names = ["Amantes De Pizza", "Dominos Pizza", "Chicken Station", "Fast Food Cafe", "The Green Hub", "Purple Haze", "Lord of Drinks"]
    let descriptionList = [
        "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor",
        "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolorLorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolorLorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor",
        "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.",
        "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod."
    ]
    private let colors = [
        UIColor(named: AppColors.appBlue.rawValue)!,
        UIColor(named: AppColors.appPink.rawValue)!,
        UIColor(named: AppColors.appPurple.rawValue)!,
        UIColor(named: AppColors.appOrange.rawValue)!,
        UIColor(named: AppColors.appLightGreen.rawValue)!
    ]
    
    func getRandomGroupList(desiredCount: Int? = nil) -> Groups {
        let count = (desiredCount == nil) ? Int.random(in: 5...10) : desiredCount!
        var i = 0
        var groups = Groups()
        while i < count {
            let groupBaseColor = colors.randomElement()!
            var name = names.randomElement()!
            while groups.contains(where: {$0.name == name}) {
                name += "1"
            }
            var indicatorIcon: String = ""
            if i == 0 {
                indicatorIcon = "group-fire-ic"
            }
            else if i == 1 {
                indicatorIcon = "group-increase-ic"
            }
            else if i == 2 {
                indicatorIcon = "group-decrease-ic"
            }
            else if i == 3 {
                indicatorIcon = "group-constant-ic"
            }
            let group = Group(name: name, propicLink: "https://i.pravatar.cc/300", baseColor: groupBaseColor, indicatorIconName: indicatorIcon, description: descriptionList.randomElement()!, places: Int.random(in: 5...20), members: Int.random(in: 1000...8000))
            groups.append(group)
            i += 1
        }
        return groups
    }
    
    func getRandomNearByGroups() -> Groups {
        let count = Int.random(in: 1...4)
        var i = 0
        var groups = Groups()
        while i < count {
            var groupBaseColor = colors.randomElement()!
            while groups.contains(where: {$0.baseColor == groupBaseColor}) {
                groupBaseColor = colors.randomElement()!
            }
            var name = names.randomElement()!
            while groups.contains(where: {$0.name == name}) {
                name += "1"
            }
            var indicatorIcon: String = ""
            if i == 0 {
                indicatorIcon = "group-fire-ic"
            }
            else if i == 1 {
                indicatorIcon = "group-increase-ic"
            }
            else if i == 2 {
                indicatorIcon = "group-decrease-ic"
            }
            else if i == 3 {
                indicatorIcon = "group-constant-ic"
            }
            let group = Group(name: name, propicLink: "https://i.pravatar.cc/300", baseColor: groupBaseColor, indicatorIconName: indicatorIcon, description: descriptionList.randomElement()!, places: Int.random(in: 5...20), members: Int.random(in: 1000...8000))
            groups.append(group)
            i += 1
        }
        return groups
    }
    
    let groupFetchSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    
    func invalidateAllNetworkRequests(completion: @escaping responseBlock) {
        self.groupFetchSessionManager.invalidateAllSessionRequests(completion: completion)
    }
    
    func fetchRankedGroupList(location: CLLocationCoordinate2D, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.rankedGroups, []).url
        let parameters: [String: Any] = [
            GroupNetworkParameterKeys.Fetch.latitude: location.latitude,
            GroupNetworkParameterKeys.Fetch.longitude: location.longitude,
            GroupNetworkParameterKeys.Fetch.size: limit
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
        groupFetchSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, ResponseError.invalidData)
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let groups = try decoder.decode(Groups.self, from: respData)
                    completion(groups, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func fetchGroupList(location: CLLocationCoordinate2D, searchText: String, showMembers: Bool, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.fetchCreate, []).url
        let parameters: [String: Any] = [
            GroupNetworkParameterKeys.Fetch.latitude: location.latitude,
            GroupNetworkParameterKeys.Fetch.longitude: location.longitude,
            GroupNetworkParameterKeys.Fetch.name: searchText,
            GroupNetworkParameterKeys.Fetch.listMembers: showMembers,
            GroupNetworkParameterKeys.Fetch.page: page,
            GroupNetworkParameterKeys.Fetch.size: limit
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
        groupFetchSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, ResponseError.invalidData)
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let groups = try decoder.decode(Groups.self, from: respData)
                    let tuple: GroupSearchResult = (groups: groups, searchText: searchText)
                    completion(tuple, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
}
