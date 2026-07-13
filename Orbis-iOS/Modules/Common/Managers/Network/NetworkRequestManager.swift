//
//  NetworkRequestManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 23/04/2021.
//

import Foundation
import Alamofire
import UIKit
import SwiftyJSON
import JWTDecode

typealias responseBlock = (_ result:Any?, _ error: Error?) -> ()

enum ParameterContentType: String {
    case formURLEncoded = "application/x-www-form-urlencoded"
    case plainText = "text/plain"
    case multipartForm = "multipart/form-data"
    case json = "application/json"
    case none = ""
}

enum NetLog {
    static var enabled = true
    static func log(_ s: @autoclosure () -> String) {
        #if DEBUG
        if enabled { print("🌐 \(s())") }
        #endif
    }
}

// Adds X-Master-Key + LANGUAGE to every request (Android SwaggerApiClient parity).
final class OrbisRequestInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var request = urlRequest
        request.setValue(APPKeys.masterKey, forHTTPHeaderField: "X-Master-Key")
        request.setValue(PrefManager().getLanguage() ?? "dd", forHTTPHeaderField: "LANGUAGE")
        NetLog.log("→ \(request.httpMethod ?? "?") \(request.url?.path ?? "") | X-Master-Key \(request.value(forHTTPHeaderField: "X-Master-Key") != nil ? "SENT" : "MISSING")")
        completion(.success(request))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        completion(.doNotRetry)
    }
}

class NetworkRequestManager {
    static let shared = NetworkRequestManager(session: NetworkRequestManager.makeSession())

    var sessionManager: Session!

    var isTokenRefreshing = false

    init(session: Session) {
        self.sessionManager = session
    }

    static func makeSession() -> Session {
        let configuration = URLSessionConfiguration.default
        // Idle timer per request (resets while bytes flow, so large uploads are unaffected). The
        // 60s default left UI like the nearby-tribe card stuck on "Loading" for a minute on a
        // dead connection before its failure fallback could run.
        configuration.timeoutIntervalForRequest = 15
        return Alamofire.Session(configuration: configuration, interceptor: OrbisRequestInterceptor())
    }

    static func getNewSession() -> Session {
        return makeSession()
    }
    
    func getHeader(authorized: Bool = false, contentType: ParameterContentType, accept: ParameterContentType, attachLocation: Bool = true) -> [String : String] {
        var headers: [String : String] = [:]
        if accept == .none {
            headers = [
                "Content-Type": contentType.rawValue
            ]
        }
        else {
            headers =  [
                "Content-Type": contentType.rawValue,
                "Accept": accept.rawValue
            ]
        }
        if authorized {
            if let token = UserSessionManager.shared.currentUser?.idToken {
                headers["Authorization"] = "Bearer \(token)"
            }
        }
        if contentType == .multipartForm {
            headers.removeValue(forKey: "Content-Type")
        }
        if attachLocation {
            if let loc = UserSessionManager.shared.userCurrentLocation {
                headers["Orbis-Coordinates"] = "\(loc.longitude);\(loc.latitude)"
            }
        }
        return headers
    }
    
    private func getPostString(params:[String:Any]) -> String {
        var data = [String]()
        for(key, value) in params
        {
            data.append(key + "=\(value)")
        }
        return data.map { String($0) }.joined(separator: "&")
    }
    
    private func convertErrorResponseToLocalError(data: Data) -> GenericError? {
        let decoder = JSONDecoder()
        do {
            let error = try decoder.decode(OrbisErrorMessage.self, from: data)
            return GenericError(title: nil, description: error.message ?? "", code: error.code ?? 2021)
        } catch {
            return nil
        }
    }
    
    func invalidateAllSessionRequests(completion: @escaping responseBlock) {
        sessionManager.session.getTasksWithCompletionHandler { (datatsk, uploadtsk, dwnloadtsk) in
            datatsk.forEach({$0.cancel()})
            uploadtsk.forEach({$0.cancel()})
            dwnloadtsk.forEach({$0.cancel()})
            completion(true, nil)
        }
    }
    
    func multipartPostRequest(toUrl urlLink: String, imageKey: String, imageData: Data, parameters: Parameters?, fileName: String, method: HTTPMethod, headers: [String: String], completion: @escaping responseBlock) {
        let imageName = "\(fileName).jpg"
        sessionManager.upload(multipartFormData: { (multipartFormData) in
            if let parameter = parameters {
                for (key, value) in parameter {
                    multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as String)
                }
            }
            multipartFormData.append(imageData, withName: imageKey, fileName: imageName, mimeType: "image/jpg")
        }, to: urlLink, usingThreshold: UInt64.init(), method: method, headers: HTTPHeaders(headers)).validate().responseData { (respdata) in
            switch respdata.result {
            case .success(let data):
                completion(data, nil)
                break
            case .failure(let error):
                completion(nil, error)
                break
            }
        }
    }
    
    private func refreshTokenIfNecessary(hardRefresh: Bool = false, completion: @escaping responseBlock) {
        guard let user = UserSessionManager.shared.currentUser else {
            completion(true, nil)
            return
        }
        do {
            let jwt = try decode(jwt: user.idToken!)
            user.tokenExpiryTimestamp = jwt.expiresAt
            let shouldRefresh = jwt.expired || hardRefresh
            guard shouldRefresh else {
                completion(true, nil)
                return
            }
            let url = GetApiAddress.auth(.refreshToken).url
            let refreshToken = user.refreshToken!
            let header = ["Content-Type": ParameterContentType.json.rawValue]
            let ApiRequest = sessionManager.request(url, method: .post, parameters: [:], encoding: refreshToken , headers:  HTTPHeaders(header))
            ApiRequest.validate().response { (response) in
                switch response.result {
                case .success(_):
                    guard let respData = response.data else {
                        // force user logout
                        completion(nil, ResponseError.invalidData)
                        return
                    }
                    let newToken = String(data: respData, encoding: .utf8)
                    user.idToken = newToken
                    UserSessionManager.shared.saveUsertoDefaults(user: user, completion: completion)
                case .failure(let error):
                    // force user logout
                    completion(nil, error)
                    break
                }
            }
        }
        catch {
            // Force Logout User
            completion(nil, error)
            return
        }
    }
    
    func processApiRequest(urlLink: String, parameters: Parameters, method: HTTPMethod,  headers: [String: String], parameterDestination: URLEncoding.Destination? = nil, isContentJSON: Bool = false, isContentArrayJSON: Bool = false, isRefreshTokenApi: Bool = false, isContentJSONString: Bool = false, completion: @escaping responseBlock) {
        self.refreshTokenIfNecessary { [weak self] (data, err) in
            guard let self = self else { return }
            let destination: URLEncoding.Destination = parameterDestination ?? .methodDependent
            var updatedHeaders = headers
            if updatedHeaders.contains(where: {$0.key == "Authorization"}) {
                updatedHeaders["Authorization"] = "Bearer \(UserSessionManager.shared.currentUser?.idToken ?? "")"
            }
            var ApiRequest = self.sessionManager.request(urlLink, method: method, parameters: parameters, encoding: URLEncoding(destination: destination) , headers: HTTPHeaders(headers))
            if isContentJSON {
                ApiRequest = self.sessionManager.request(urlLink, method: method, parameters: parameters, encoding: JSONEncoding.default , headers:  HTTPHeaders(headers))
            }
            else if isContentArrayJSON {
                ApiRequest = self.sessionManager.request(urlLink, method: method, parameters: parameters, encoding: ArrayJSONEncoding(options: .prettyPrinted) , headers:  HTTPHeaders(headers))
            }
            else if isContentJSONString {
                let stringEncoding = parameters.first?.value as? String ?? ""
                ApiRequest = self.sessionManager.request(urlLink, method: method, parameters: [:], encoding: stringEncoding , headers:  HTTPHeaders(headers))
            }
            ApiRequest.validate().responseJSON { (response) in
                NetLog.log("← \(response.request?.httpMethod ?? "?") \(response.request?.url?.path ?? "") | \(response.response?.statusCode ?? -1) | \(response.data?.count ?? 0)b")
                switch response.result {
                case .success(let data):
                    if let dataString = String(data: response.data ?? Data(), encoding: .utf8) {
                       // debugPrint("API Response in String: \(dataString)")
                    }
                    completion(response.data ?? data, nil)
                    break
                case .failure(let error):
                    debugPrint("-------API RESPONSE ERROR-------\nError in url (\(response.request?.url?.absoluteString ?? "nA")\n response: \(error.localizedDescription))")
                    if response.response?.statusCode == 200 || response.response?.statusCode == 201 {
                        debugPrint("Status Code 200 is Accepted so bypassing response...")
                        if let data = response.data {
                            completion(data, nil)
                        }
                        else {
                            completion(true, nil)
                        }
                        return
                    }
                    if response.response?.statusCode == 204 {
                        debugPrint("Status Code 204 is Accepted so bypassing response...")
                        if let data = response.data {
                            completion(data, nil)
                        }
                        else {
                            completion(true, nil)
                        }
                        return
                    }
                    if response.response?.statusCode == NSURLErrorTimedOut {
                        completion(nil, HTTPError.timeout)
                        return
                    }
                    if response.response?.statusCode == 401, urlLink != GetApiAddress.auth(.refreshToken).url, headers.keys.contains("Authorization") {
                        guard !self.isTokenRefreshing else {
                            let newHeader = UserSessionManager.replaceAuthorizationValueInHeader(header: headers)
                            self.processApiRequest(urlLink: urlLink, parameters: parameters, method: method, headers: newHeader, completion: completion)
                            return
                        }
                        self.isTokenRefreshing = true
                        self.refreshTokenIfNecessary(hardRefresh: true) { [weak self] (data, err) in
                            if let _ = err {
                                // force user logout
                                UserSessionManager.shared.signout(forceSignout: true, completion: completion)
//                                completion(nil, error)
                            }
                            else {
                                let newHeader = UserSessionManager.replaceAuthorizationValueInHeader(header: headers)
                                self?.processApiRequest(urlLink: urlLink, parameters: parameters, method: method, headers: newHeader, completion: completion)
                            }
                            self?.isTokenRefreshing = false
                        }
                        return
                    }
                    if urlLink == GetApiAddress.auth(.refreshToken).url, response.response?.statusCode == 401 {
                        // force user logout
                        UserSessionManager.shared.signout(forceSignout: true, completion: completion)
                        return
                    }
                    if response.response?.statusCode == 400, let respData = response.data {
                        if let jsonError = self.convertErrorResponseToLocalError(data: respData) {
                            completion(nil, jsonError)
                            break
                        }
                        else {
                            completion(nil, error)
                            break
                        }
                    }
                    if let respData = response.data {
                        if let jsonError = self.convertErrorResponseToLocalError(data: respData) {
                            completion(nil, jsonError)
                            break
                        }
                        else {
                            completion(nil, error)
                            break
                        }
                    }
                    completion(nil, error)
                    break
                }
            }
        }
    }
}

let networkRequestArrayParametersKey = "arrayParametersKey"

/// Extenstion that allows an array be sent as a request parameters
extension Array {
    /// Convert the receiver array to a `Parameters` object.
    func asParameters() -> Parameters {
        return [networkRequestArrayParametersKey: self]
    }
}


/// Convert the parameters into a json array, and it is added as the request body.
/// The array must be sent as parameters using its `asParameters` method.
public struct ArrayJSONEncoding: ParameterEncoding {
    
    /// The options for writing the parameters as JSON data.
    public let options: JSONSerialization.WritingOptions
    
    
    /// Creates a new instance of the encoding using the given options
    ///
    /// - parameter options: The options used to encode the json. Default is `[]`
    ///
    /// - returns: The new instance
    public init(options: JSONSerialization.WritingOptions = []) {
        self.options = options
    }
    
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()
        
        guard let parameters = parameters,
              let array = parameters[networkRequestArrayParametersKey] else {
            return urlRequest
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: array, options: options)
            
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            urlRequest.httpBody = data
            
        } catch {
            throw AFError.parameterEncodingFailed(reason: .jsonEncodingFailed(error: error))
        }
        
        return urlRequest
    }
}
