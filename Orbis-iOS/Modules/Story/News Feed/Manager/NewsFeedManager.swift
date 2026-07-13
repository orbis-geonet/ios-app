//
//  NewsFeedManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 23/06/2021.
//

import Foundation

class NewsFeedManager {
    
    // MARK:- News Feed Manager
    
    let newsFeedSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    
    func invalidateAllNewsFeedNetworkRequests(completion: @escaping responseBlock) {
        self.newsFeedSessionManager.invalidateAllSessionRequests(completion: completion)
    }
    
    func fetchNewsFeed(longitude: Double, latitude: Double, from: String, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.feed(.newsFeed, []).url
        var parameters: [String: Any] = [
            FeedNetworkParameterKeys.Fetch.longitude: longitude,
            FeedNetworkParameterKeys.Fetch.latitude: latitude,
            FeedNetworkParameterKeys.Fetch.nextPage: from,
            FeedNetworkParameterKeys.Fetch.size: limit
        ]
        if from.isEmpty {
            parameters.removeValue(forKey: FeedNetworkParameterKeys.Fetch.nextPage)
        }
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        newsFeedSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: header, parameterDestination: .queryString, completion: { (data, err) in
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
                    let feedResponse = try decoder.decode(OrbisFeedPaginatedResponse.self, from: respData)
                    completion(feedResponse, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    let newsFeedStoriesSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    
    func invalidateAllNewsFeedStoriesNetworkRequests(completion: @escaping responseBlock) {
        self.newsFeedStoriesSessionManager.invalidateAllSessionRequests(completion: completion)
    }
    
    func fetchNewsStories(seen: Bool, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.feed(.newsStories, []).url
        
        let parameters: [String: Any] = [
            FeedNetworkParameterKeys.Fetch.page: page,
            FeedNetworkParameterKeys.Fetch.seen: seen,
            FeedNetworkParameterKeys.Fetch.size: limit
        ]
        
        
        // Pretty-print the URL and parameters
//            print("\n--- Fetch News Stories ---")
//            print("URL: \(url)")
//            print("Parameters:")
//            for (key, value) in parameters {
//                print("\t\(key): \(value)")
//            }
//            print("----------------------------\n")
        
        
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        newsFeedStoriesSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: header, parameterDestination: .queryString, completion: { (data, err) in
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
                    let stories = try decoder.decode(OrbisStories.self, from: respData)
                    completion(stories, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    // MARK:- Nearby Feed Manager
    
    let nearbyFeedSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    
    func invalidateAllNearbyFeedNetworkRequests(completion: @escaping responseBlock) {
        self.nearbyFeedSessionManager.invalidateAllSessionRequests(completion: completion)
    }
    
    func fetchNearbyFeed(distance: Double, longitude: Double, latitude: Double, from: String, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.feed(.nearbyFeed, []).url
        var parameters: [String: Any] = [
            FeedNetworkParameterKeys.Fetch.distance: distance,
            FeedNetworkParameterKeys.Fetch.longitude: longitude,
            FeedNetworkParameterKeys.Fetch.latitude: latitude,
            FeedNetworkParameterKeys.Fetch.nextPage: from,
            FeedNetworkParameterKeys.Fetch.size: limit
        ]
        if from.isEmpty {
            parameters.removeValue(forKey: FeedNetworkParameterKeys.Fetch.nextPage)
        }
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let header = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .none, accept: .none)
        nearbyFeedSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: header, parameterDestination: .queryString, completion: { (data, err) in
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
                    let nearbyFeed = try decoder.decode(OrbisFeedPaginatedResponse.self, from: respData)
                    completion(nearbyFeed, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    let nearbyStoriesSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    
    func invalidateAllNearbyStoriesNetworkRequests(completion: @escaping responseBlock) {
        self.nearbyStoriesSessionManager.invalidateAllSessionRequests(completion: completion)
    }
    
    func fetchNearbyStories(longitude: Double, latitude: Double, seen: Bool, page: Int, limit: Int, completion: @escaping responseBlock) {
        //let url = GetApiAddress.feed(.nearbyStories, []).url
        let url = GetApiAddress.feed(.newsStories, []).url
        
        print("url is \(url)")
        
        let parameters: [String: Any] = [
            FeedNetworkParameterKeys.Fetch.page: page,
            FeedNetworkParameterKeys.Fetch.seen: seen,
            FeedNetworkParameterKeys.Fetch.longitude: longitude,
            FeedNetworkParameterKeys.Fetch.latitude: latitude,
            FeedNetworkParameterKeys.Fetch.size: limit
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let header = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .none, accept: .none)
        nearbyStoriesSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: header, parameterDestination: .queryString, completion: { (data, err) in
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
                    let stories = try decoder.decode(OrbisStories.self, from: respData)
                    completion(stories, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func markStorySeen(postKey: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.feed(.markStorySeen, [postKey]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .put, headers: header) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        }
    }
}
