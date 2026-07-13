//
//  AdminStripeManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 06/01/2023.
//

import Foundation

class AdminStripeManager {
    
    func getStripeAccountStatus(completion: @escaping responseBlock) {
        let url = GetApiAddress.stripe(.get, []).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
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
                    let stripeStatus = try decoder.decode(StripeAccountStatusModel.self, from: respData)
                    completion(stripeStatus, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func createStripeAccount(completion: @escaping responseBlock) {
        let url = GetApiAddress.stripe(.get, []).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        let params = [
            StripeApiParamKeys.Create.country: AppValues.StripeAccountCreationDefaults.defaultCountry,
            StripeApiParamKeys.Create.businessType: AppValues.StripeAccountCreationDefaults.defaultBusinessType
        ]
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: params, method: .post, headers: headers, isContentJSON: true) { (data, err) in
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
                    let response = try decoder.decode(StripeAccountCreateResponse.self, from: respData)
                    completion(response, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func updateStripeAccount(completion: @escaping responseBlock) {
        let url = GetApiAddress.stripe(.get, []).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        let params = [
            StripeApiParamKeys.Create.country: AppValues.StripeAccountCreationDefaults.defaultCountry,
            StripeApiParamKeys.Create.businessType: AppValues.StripeAccountCreationDefaults.defaultBusinessType
        ]
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: params, method: .put, headers: headers, isContentJSON: true) { (data, err) in
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
                    let response = try decoder.decode(StripeAccountCreateResponse.self, from: respData)
                    completion(response, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func deleteStripeAccount(completion: @escaping responseBlock) {
        let url = GetApiAddress.stripe(.get, []).url
        let headers = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: headers) { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                completion(true, nil)
            }
        }
    }
}
