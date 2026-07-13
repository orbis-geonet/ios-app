//
//  EventDetailManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 02/09/2021.
//

import Foundation

class EventDetailManager {
    
    func fetchAttendees(forEvent key: String, page: Int, size: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.post(.eventAttendees, [key]).url
        let parameters: [String: Any] = [
            PlaceNetworkParameterKeys.Fetch.page: page,
            PlaceNetworkParameterKeys.Fetch.limit: size
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
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
                    let users = try decoder.decode(OrbisUsers.self, from: respData)
                    completion(users, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func attendEvent(key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.post(.attendEvent, [key]).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .put, headers: headers, parameterDestination: .methodDependent, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
            }
        })
    }
    
    func cancelAttendEvent(key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.post(.attendEvent, [key]).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: headers, parameterDestination: .methodDependent, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
            }
        })
    }
}
