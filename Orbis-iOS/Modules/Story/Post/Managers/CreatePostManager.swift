//
//  CreatePostManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 04/05/2021.
//

import Foundation
import CoreLocation

class CreatePostManager {
    
    func fetchRecommendedGroupList(location: CLLocationCoordinate2D, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.group(.recommendedGroups, []).url
        let parameters: [String: Any] = [
            GroupNetworkParameterKeys.Fetch.latitude: location.latitude,
            GroupNetworkParameterKeys.Fetch.longitude: location.longitude,
            GroupNetworkParameterKeys.Fetch.size: limit
        ]
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
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
    
    func createPost(paramters: [String: Any], feedPost: OrbisFeedPost? = nil , completion: @escaping responseBlock) {
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        let url = GetApiAddress.post(.fetchCreate, []).url
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: paramters, method: .post, headers: header, isContentJSON: true) { (data, err) in
            if let error = err {
                completion(nil, error)
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, ResponseError.invalidData)
                    return
                }
                
                // Print response as a string for debugging
//                if let responseString = String(data: respData, encoding: .utf8) {
//                    print("Response String: \(responseString)")
//                } else {
//                    print("Failed to convert response data to string")
//                }
                
                //first go for subType
                if let specificValue = paramters["subType"] as? String, !specificValue.isEmpty, specificValue != paramters["type"] as! String {
                      // print("Value for 'specificKey': \(specificValue)")
                    var updatedParameter = paramters
                    updatedParameter["type"] = specificValue
                    updatedParameter["checkin"] = false
                    updatedParameter["subType"] = nil
                    
                    let decoder = JSONDecoder()
                    let post = try? decoder.decode(OrbisFeedPost.self, from: respData)
                    //we need to call here normal post
                    self.createPost(paramters: updatedParameter,feedPost: post, completion: completion)
                    
                    return
                   }
                
                /*
                if let specificValue = paramters["details"] as? String, !specificValue.isEmpty {
                      // print("Value for 'specificKey': \(specificValue)")
                    var updatedParameter = paramters
                    updatedParameter["type"] = "TEXT"
                    updatedParameter["checkin"] = false
                    updatedParameter["subType"] = nil
                    
                    if Thread.isMainThread {
                        //we need to call here normal post
                        self.createPost(paramters: updatedParameter,feedPost: feedPost, completion: completion)
                    }else{
                        DispatchQueue.main.async {
                            self.createPost(paramters: updatedParameter,feedPost: feedPost, completion: completion)
                        }
                    }
                    updatedParameter["detials"] = nil
                    return
                   }
                 */
                 
                
                let decoder = JSONDecoder()
                do {
                    if (feedPost == nil) {
                        let post = try decoder.decode(OrbisFeedPost.self, from: respData)
                        completion(post, nil)
                    }else {
                        //send checkInPost
                        completion(feedPost, nil)
                    }
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
}
