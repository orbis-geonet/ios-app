//
//  GroupRepositories.swift
//  Orbis-iOS
//
//  Created by Kamran on 30/10/2024.
//


import Foundation
import Combine

class GroupRepositories {
    
    private let apiInterface = ApiServiceImplementation()
    private let prefManager = PrefManager ()
    private let groupDao = GroupDao()
    

        func getEvents(placeKey: String, page: Int) -> AnyPublisher<[FeedPost], Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
           // return apiInterface.getEventByGroup(token: token, placeKey: placeKey, pastEvents: false, page: page, size: 25)
            return apiInterface.getEventByGroup(token: token, key: placeKey, pastEvents: false, page: page, size: 25)
        }

        func createGroup(createGroupBody: CreateGroupBody) -> AnyPublisher<GroupDetails, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.createGroup(token: token, createGroupBody: createGroupBody)
        }

        func updateGroup(createGroupBody: CreateGroupBody, groupKey: String) -> AnyPublisher<GroupDetails, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.updateGroup(token: token, groupKey: groupKey, createGroupBody: createGroupBody)
        }

        func getRecommendedGroup(latitude: Double, longitude: Double) -> AnyPublisher<[GroupDetails], Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
           // let location = "\(Constants.location?.longitude ?? 0.0);\(Constants.location?.latitude ?? 0.0)"
            let location = "" //"\(Constants.location?.longitude ?? 0.0);\(Constants.location?.latitude ?? 0.0)"
            return apiInterface.getRecommendedGroup(token: token, coordinates: location, latitude: latitude, longitude: longitude, size: 5)
        }

        func getGroups(latitude: Double, longitude: Double, name: String, page: Int = 0) -> AnyPublisher<[GroupDetails], Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.getGroups(token: token, latitude: latitude, longitude: longitude, name: name, size: 100, page: page)
        }

        func getGroupsWithoutLocation(page: Int = 0) -> AnyPublisher<[GroupDetails], Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.getGroupsWithoutLocation(token: token, size: 50, page: page)
        }

        func getUserGroups(userKey: String, page: Int = 0, orbisLocation: String) -> AnyPublisher<[GroupDetails], Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.getUserGroups(token: token, coordinates: orbisLocation, userKey: userKey, size: 25, page: page)
        }

        func getRatedGroups(latitude: Double, longitude: Double, page: Int = 0) -> AnyPublisher<[GroupDetails], Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.getRatedGroups(token: token, latitude: latitude, longitude: longitude, timePeriod: 1, size: 25, page: page)
        }

        func getGroupFeed(groupKey: String, nextPage: String) -> AnyPublisher<Feed, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.getGroupFeed(token: token, groupKey: groupKey, nextPage: nextPage, size: 20)
        }

        func getGroupFeedFirst(groupKey: String) -> AnyPublisher<Feed, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.getGroupFeedFirst(token: token, groupKey: groupKey, size: 20)
        }

//        func getGroupByKey(groupKey: String, orbisLocation: String) -> AnyPublisher<GroupDetails, Error> {
//            let token = "Bearer \(prefManager.getIdToken() ?? "")"
//            return apiInterface.getGroupByKey(token: token, coordinates: orbisLocation, groupKey: groupKey)
//        }
    
    
    func getGroupByKey(groupKey: String, orbisLocation: String) -> AnyPublisher<GroupDetails, Error> {
        let tokenValue = prefManager.getIdToken() ?? ""
        let token = "Bearer \(tokenValue)"

        print("GroupDetails API - groupKey:", groupKey)
        print("GroupDetails API - orbisLocation:", orbisLocation)
        print("GroupDetails API - has token:", !tokenValue.isEmpty)

        return apiInterface.getGroupByKey(
            token: token,
            coordinates: orbisLocation,
            groupKey: groupKey
        )
    }

        func likePost(postKey: String) -> AnyPublisher<FeedPost, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.likePost(token: token, postKey: postKey)
        }

        func unlikePost(postKey: String) -> AnyPublisher<FeedPost, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.unlikePost(token: token, postKey: postKey)
        }

//        func getGroupMembers(groupKey: String, page: Int) -> AnyPublisher<[User], Error> {
//            let token = "Bearer \(prefManager.getIdToken() ?? "")"
//            return apiInterface.getGroupMembers(token: token, groupKey: groupKey, page: page, size: 100)
//        }
    
    func getGroupMembers(groupKey: String, page: Int) -> AnyPublisher<[User], Error> {
        let tokenValue = prefManager.getIdToken() ?? ""
        let token = "Bearer \(tokenValue)"

        print("GroupMembers API - groupKey:", groupKey)
        print("GroupMembers API - page:", page)
        print("GroupMembers API - has token:", !tokenValue.isEmpty)

        return apiInterface.getGroupMembers(
            token: token,
            groupKey: groupKey,
            page: page,
            size: 100
        )
    }

        func getGroupAdmins(groupKey: String) -> AnyPublisher<[User], Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.getGroupAdmins(token: token, groupKey: groupKey, size: 100, page: 0)
        }

        func addBan(groupKey: String, userKey: String) -> AnyPublisher<Void, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.addBan(token: token, groupKey: groupKey, userKey: userKey)
        }

        func blockGroup(groupKey: String) -> AnyPublisher<Void, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.blockGroup(token: token, groupKey: groupKey)
        }

        func unBlockGroup(groupKey: String) -> AnyPublisher<Void, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.unBlockGroup(token: token, groupKey: groupKey)
        }

        func addAdmin(groupKey: String, userKey: String) -> AnyPublisher<Void, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.addAdmin(token: token, groupKey: groupKey, userKey: userKey)
        }

        func adminRemoveAdmin(groupKey: String, userKey: String) -> AnyPublisher<Void, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.adminRemoveAdmin(token: token, groupKey: groupKey, userKey: userKey)
        }

        func attendEvent(postKey: String) -> AnyPublisher<Void, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.attendEvent(token: token, postKey: postKey)
        }

        func unattendEvent(postKey: String) -> AnyPublisher<Void, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.unattendEvent(token: token, postKey: postKey)
        }

        func getPlaceOwnedByGroup(groupKey: String, latitude: Double, longitude: Double, page: Int) -> AnyPublisher<[PlaceDetails], Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            let location = "\(longitude);\(latitude)"
            //return apiInterface.getPlaceOwnedByGroup(token: token, coordinates: location, groupKey: groupKey, page: page, size: 50)
            return apiInterface.getPlaceOwnedByGroup(token: token, coordinates: location, ownedByGroupKey: groupKey, page: page, size: 50)
        }

        func joinGroup(groupKey: String) -> AnyPublisher<Void, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.joinGroup(token: token, groupKey: groupKey)
        }

        func leaveGroup(groupKey: String) -> AnyPublisher<Void, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.leaveGroup(token: token, groupKey: groupKey)
        }

        func followGroup(groupKey: String) -> AnyPublisher<Void, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.followGroup(token: token, groupKey: groupKey)
        }

        func unfollowGroup(groupKey: String) -> AnyPublisher<Void, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.unfollowGroup(token: token, groupKey: groupKey)
        }
    
        func deleteGroup(groupKey: String) -> AnyPublisher<Void, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.deleteGroup(token: token, groupKey: groupKey)
        }

        func sharePost(postKey: String) -> AnyPublisher<Data, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.sharePost(token: token, postKey: postKey)
        }

        func deletePost(postKey: String) -> AnyPublisher<Void, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.deletePost(token: token, postKey: postKey)
        }

        func getPost(postKey: String) -> AnyPublisher<FeedPost, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.getPost(token: token, postKey: postKey)
        }

        func reportPost(postKey: String, text: String) -> AnyPublisher<Data, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.reportPost(
                token: token,
                postKey: postKey,
                requestBody: text.data(using: .utf8) ?? Data()
            )
        }

        func reportGroup(groupKey: String, text: String) -> AnyPublisher<Data, Error> {
            let token = "Bearer \(prefManager.getIdToken() ?? "")"
            return apiInterface.reportGroup(
                token: token,
                groupKey: groupKey,
                requestBody: text.data(using: .utf8) ?? Data()
            )
        }
    
    //MARK: cachedGroups.
    func getCachedGroups(city: String, loggedIn: Bool) -> [GroupDetails] {
        return groupDao.getCachedGroups(city: city, loggedIn: loggedIn).map { $0.toDomain() }
    }
    
    func cacheGroups(groups: [GroupDetails], city: String, loggedIn: Bool) {
        groupDao.insertGroups(groups: groups.map { $0.toEntity(fromCity: city, fromLoggedInUser: loggedIn) })
    }
    
    func deleteGroupsFromCache(city: String, loggedIn: Bool) {
        groupDao.deleteCachedGroups(city: city, loggedIn: loggedIn)
    }
    
    func modifyGroup(group: GroupDetails, city: String, loggedIn: Bool) {
        groupDao.updateGroup(group: group.toEntity(fromCity: city, fromLoggedInUser: loggedIn))
    }
    
    func modifyGroups(groups: [GroupDetails], city: String, loggedIn: Bool) {
        groupDao.updateGroups(groups: groups.map { $0.toEntity(fromCity: city, fromLoggedInUser: loggedIn) })
    }
    
}
