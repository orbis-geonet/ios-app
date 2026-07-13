//
//  OrbisPlaceDetailManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 14/06/2021.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage

class OrbisPlaceDetailManager {
    
    let placeFeedSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    let placeEventSessionManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    
    func syncPlaceDetail(forPlace key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.place(.details, [key]).url
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .get, headers: headers) { (data, err) in
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
                    let place = try decoder.decode(OrbisPlace.self, from: respData)
                    completion(place, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func updatePlaceData(placeKey key: String, withParam parameter: [String: Any], completion: @escaping responseBlock) {
        let url = GetApiAddress.place(.details, [key]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: parameter, method: .put, headers: header, isContentJSON: true) { (data, err) in
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
                    let place = try decoder.decode(OrbisPlace.self, from: respData)
                    completion(place, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func ratePlace(placeKey: String, rating: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.place(.ratePlace, []).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        let parameter: [String: Any] = [
            PlaceDomainParameterKeys.Rate.placeKey: placeKey,
            PlaceDomainParameterKeys.Rate.rate: rating
        ]
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: parameter, method: .post, headers: header, isContentJSON: true) { (data, err) in
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
    
    func uploadPlaceImage(withName name: String, image: UIImage, completion: @escaping responseBlock) {
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.placePictures.rawValue)
        let imageData = image.sd_imageData()!
        let imageName = name + imageData.fileExtension
        let fileRef = storageRef.child(imageName)
        // Create file metadata including the content type
        let metadata = StorageMetadata()
        metadata.contentType = imageData.mimeType
        let _ = fileRef.putData(imageData, metadata: metadata) { metadata, err in
            if let error = err {
                completion(nil, error)
                return
            }
            guard let _ = metadata else {
                completion(nil, ResponseError.invalidData)
                return
            }
            let imageThumbRef = Database.database().reference().child(FirebaseRTDBNode.placeProPics.rawValue).child(String(imageName.split(separator: ".").first!))
            self.observeThumbnailGeneration(forRef: imageThumbRef, imageName: imageName, completion: completion)
        }
    }
    
    private func observeThumbnailGeneration(forRef ref: DatabaseReference, imageName: String, completion: @escaping responseBlock) {
        ref.observe(.value) { snapshot in
            if let data = snapshot.value, let arrayData = data as? [String: Any] {
                var generatedThumbnails = 0
                for (_, value) in arrayData {
                    if let thumbData = value as? [String: Any], let generatedValue = thumbData["generated"] as? Bool {
                        if generatedValue == true {
                            generatedThumbnails += 1
                        }
                    }
                }
                if generatedThumbnails >= 3 {
                    ref.removeAllObservers()
                    completion(imageName, nil)
                }
            }
        }
    }
    
    func reportPlace(key: String, text: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.place(.report, [key]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: ["reportText": text], method: .post, headers: header, isContentJSONString: true) { data, err in
            if let error = err {
                debugPrint("Error reporting place \(error.localizedDescription)")
                completion(nil, error)
            }
            else {
                completion(true, nil)
            }
        }
    }
    
    func fetchPlaceFeed(placeKey key: String, from: String, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.place(.fetchFeed, ["\(key)"]).url
        var parameters: [String: Any] = [
            GroupNetworkParameterKeys.Fetch.nextPage: from,
            GroupNetworkParameterKeys.Fetch.size: limit
        ]
        if from.isEmpty {
            parameters.removeValue(forKey: GroupNetworkParameterKeys.Fetch.nextPage)
        }
        let headers = NetworkRequestManager.shared.getHeader(authorized: UserSessionManager.shared.currentUser != nil, contentType: .none, accept: .none)
        placeFeedSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
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
                    let placeFeed = try decoder.decode(OrbisFeedPaginatedResponse.self, from: respData)
                    completion(placeFeed, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
    
    func followPlace(placeKey key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.place(.followUnfollow, ["\(key)"]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .put, headers: header, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        })
    }
    
    func unfollowPlace(key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.place(.followUnfollow, ["\(key)"]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .none, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: header, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
                return
            }
        })
    }
    
    
    func fetchPlaceEvents(placeKey key: String, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.place(.events, ["\(key)"]).url
        let parameters: [String: Any] = [
            GroupNetworkParameterKeys.Fetch.page: page,
            GroupNetworkParameterKeys.Fetch.size: limit
        ]
        let headers = NetworkRequestManager.shared.getHeader(authorized: UserSessionManager.shared.currentUser != nil, contentType: .none, accept: .none)
        placeEventSessionManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
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
                    let placeEvents = try decoder.decode(OrbisFeedPosts.self, from: respData)
                    completion(placeEvents, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        })
    }
}
