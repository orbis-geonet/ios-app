//
//  ApiInterface.swift
//  Orbis-iOS
//
//  Created by Kamran on 30/10/2024.
//


import Foundation
import Combine
import CoreLocation

protocol ApiService {
    
    //MARK: AuthRepository
    func login(loginBody: LoginBody) -> AnyPublisher<UserProfile, Error>
    func signup(signUpBody: SignUpBody) -> AnyPublisher<UserProfile, Error>
    func updateProfile(token: String, profileUpdateBody: ProfileUpdateBody) -> AnyPublisher<UserProfile, Error>
    func refreshToken(requestBody: Data) -> AnyPublisher<Data, Error>
    
    //MARK: PlaceRepository
    // Add other methods as needed
    func createPlace(token: String, createPlaceBody: CreatePlaceBody) -> AnyPublisher<PlaceDetails, Error>
    func ratePlace(token: String, ratePlaceBody: RatePlaceBody) -> AnyPublisher<RatePlaceModel, Error>
    func getEventBy(token: String, key: String, pastEvents: Bool, page: Int, size: Int) -> AnyPublisher<[FeedPost], Error>
    func findPlacesForMap(latitude: Double, longitude: Double, distance: Int, page: Int, size: Int) -> AnyPublisher<[PlaceDetails], Error>
    func findPolygonPlacesForMap(latitude: Double, longitude: Double, distance: Int, page: Int, size: Int) -> AnyPublisher<[PolygonPlaceDetails], Error>
    func findGroupsForMap(token: String, latitude: Double, longitude: Double, distance: Int, page: Int, size: Int) -> AnyPublisher<[String], Error>
    func getPlaceDetails(token: String, placeKey: String) -> AnyPublisher<PlaceDetails, Error>
    func getPolygonPlaceDetails(placeKey: String) -> AnyPublisher<PolygonPlaceDetails, Error>
    func getPolygonPlaceStatus(checkInPolygonCoordinateKey: String) -> AnyPublisher<CheckInStatus, Error>
    func getPlaces(token: String, latitude: Double, longitude: Double, name: String, page: Int, size: Int, distance: Int) -> AnyPublisher<[PlaceDetails], Error>
    func createPost(token: String, postBody: PostBody) -> AnyPublisher<FeedPost, Error>
    func getPlaceFeedFirst(token: String, placeKey: String, size: Int) -> AnyPublisher<Feed, Error>
    func getPlaceFeed(token: String, placeKey: String, size: Int, nextPage: String) -> AnyPublisher<Feed, Error>
    func followPlace(token: String, placeKey: String) -> AnyPublisher<Void, Error>
    func unfollowPlace(token: String, placeKey: String) -> AnyPublisher<Void, Error>
    func updatePlace(token: String, placeKey: String, placeUpdateBody: PlaceUpdateBody) -> AnyPublisher<PlaceDetails, Error>
    func getLocationInfo(token: String, latitude: Double, longitude: Double) -> AnyPublisher<MapCenterAddressResponse, Error>

}

class ApiServiceImplementation: ApiService {
    
    private let baseURL = URL(string: "https://orbisv2-production.uc.r.appspot.com")!

    // Stack-2 session carrying X-Master-Key + LANGUAGE (LANGUAGE captured at init).
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "X-Master-Key": APPKeys.masterKey,
            "LANGUAGE": PrefManager().getLanguage() ?? "dd"
        ]
        return URLSession(configuration: configuration)
    }()

    //MARK: AuthRepositories
    func login(loginBody: LoginBody) -> AnyPublisher<UserProfile, Error> {
        var request = URLRequest(url: baseURL.appendingPathComponent("/login"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(loginBody)
        
        return session.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: UserProfile.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
     
    func signup(signUpBody: SignUpBody) -> AnyPublisher<UserProfile, Error> {
        var request = URLRequest(url: baseURL.appendingPathComponent("/signup"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(signUpBody)
        
        return session.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: UserProfile.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func updateProfile(token: String, profileUpdateBody: ProfileUpdateBody) -> AnyPublisher<UserProfile, Error> {
        var request = URLRequest(url: baseURL.appendingPathComponent("/profile/me"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(profileUpdateBody)
        
        return session.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: UserProfile.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
     
    func refreshToken(requestBody: Data) -> AnyPublisher<Data, Error> {
        var request = URLRequest(url: baseURL.appendingPathComponent("/refresh"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBody

        return session.dataTaskPublisher(for: request)
            .map { $0.data }
            .mapError { $0 as Error } // Map URLError to a general Error type
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    
    //MARK: PlaceRepositories
    
    func createPlace(token: String, createPlaceBody: CreatePlaceBody) -> AnyPublisher<PlaceDetails, Error> {
        var request = URLRequest(url: baseURL.appendingPathComponent("/places"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(createPlaceBody)
        
        return session.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: PlaceDetails.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func ratePlace(token: String, ratePlaceBody: RatePlaceBody) -> AnyPublisher<RatePlaceModel, Error> {
        var request = URLRequest(url: baseURL.appendingPathComponent("/places/rate"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(ratePlaceBody)
        
        return session.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: RatePlaceModel.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func getEventBy(token: String, key: String, pastEvents: Bool, page: Int, size: Int) -> AnyPublisher<[FeedPost], Error> {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("/places/\(key)/events"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [
            URLQueryItem(name: "pastEvents", value: String(pastEvents)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return session.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: [FeedPost].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func findPlacesForMap(latitude: Double, longitude: Double, distance: Int, page: Int, size: Int) -> AnyPublisher<[PlaceDetails], Error> {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("/places/map"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "distance", value: String(distance)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        
        return session.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: [PlaceDetails].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    
    func findPolygonPlacesForMap(latitude: Double, longitude: Double, distance: Int, page: Int, size: Int) -> AnyPublisher<[PolygonPlaceDetails], Error> {
        
        let placeURL = URL(string: "https://orbisv2-production.appspot.com/polygon-calculations/polygons-page")!
        
        print("findPolygonPlacesForMap :latitude \(latitude) and longitude \(longitude)")
        
        var urlComponents = URLComponents(url: placeURL, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "distance", value: String(distance)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        
        /*
        return session.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: [PolygonPlaceDetails].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
         */
        
        return session.dataTaskPublisher(for: request)
//                .tryMap { result -> Data in
//                    guard let httpResponse = result.response as? HTTPURLResponse,
//                          (200...299).contains(httpResponse.statusCode) else {
//                        throw URLError(.badServerResponse)
//                    }
//                    return result.data
//                }
        
            .tryMap { result -> Data in
                guard let httpResponse = result.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                switch httpResponse.statusCode {
                case 200...299:
                    return result.data
                case 401:
                    throw URLError(.userAuthenticationRequired)
                case 404:
                    throw URLError(.fileDoesNotExist)
                case 500...599:
                    throw URLError(.cannotConnectToHost)
                default:
                    throw URLError(.unknown)
                }
            }
                .decode(type: [PolygonPlaceDetails].self, decoder: JSONDecoder())
                .receive(on: DispatchQueue.main)
                .mapError { error -> Error in
                        print("Mapped error: \(error)")
                        return error
                    }
                    .handleEvents(
                        receiveOutput: { response in
                            print("Fetch Polygon Response: \(response)")
                        }
                    )
                .eraseToAnyPublisher()
    }
    
    
    func findGroupsForMap(token: String, latitude: Double, longitude: Double, distance: Int, page: Int, size: Int) -> AnyPublisher<[String], Error> {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("/groups/map"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "distance", value: String(distance)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return session.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: [String].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func getPlaceDetails(token: String, placeKey: String) -> AnyPublisher<PlaceDetails, Error> {
        let url = baseURL.appendingPathComponent("/places/\(placeKey)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return session.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: PlaceDetails.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func getPolygonPlaceDetails(placeKey: String) -> AnyPublisher<PolygonPlaceDetails, Error> {
           let url = baseURL.appendingPathComponent("/polygon-calculations/polygons/\(placeKey)")
           var request = URLRequest(url: url)
           request.httpMethod = "GET"

           return session.dataTaskPublisher(for: request)
               .map { $0.data }
               .decode(type: PolygonPlaceDetails.self, decoder: JSONDecoder())
               .receive(on: DispatchQueue.main)
               .eraseToAnyPublisher()
       }
    
    func getPolygonPlaceStatus(checkInPolygonCoordinateKey: String) -> AnyPublisher<CheckInStatus, Error> {
            let url = baseURL.appendingPathComponent("/polygon-calculations/\(checkInPolygonCoordinateKey)")
            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            return session.dataTaskPublisher(for: request)
                .map { $0.data }
                .decode(type: CheckInStatus.self, decoder: JSONDecoder())
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    
    func getPlaces(token: String, latitude: Double, longitude: Double, name: String, page: Int, size: Int, distance: Int) -> AnyPublisher<[PlaceDetails], Error> {
            var urlComponents = URLComponents(url: baseURL.appendingPathComponent("/places"), resolvingAgainstBaseURL: false)!
            urlComponents.queryItems = [
                URLQueryItem(name: "latitude", value: String(latitude)),
                URLQueryItem(name: "longitude", value: String(longitude)),
                URLQueryItem(name: "name", value: name),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "size", value: String(size)),
                URLQueryItem(name: "distance", value: String(distance))
            ]
            var request = URLRequest(url: urlComponents.url!)
            request.httpMethod = "GET"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            return session.dataTaskPublisher(for: request)
                .map { $0.data }
                .decode(type: [PlaceDetails].self, decoder: JSONDecoder())
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    
    func createPost(token: String, postBody: PostBody) -> AnyPublisher<FeedPost, Error> {
            let url = baseURL.appendingPathComponent("/posts")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(postBody)

            return session.dataTaskPublisher(for: request)
                .map { $0.data }
                .decode(type: FeedPost.self, decoder: JSONDecoder())
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    
    func getPlaceFeedFirst(token: String, placeKey: String, size: Int) -> AnyPublisher<Feed, Error> {
            let url = baseURL.appendingPathComponent("/feed/place/\(placeKey)")
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            urlComponents.queryItems = [
                URLQueryItem(name: "size", value: String(size))
            ]
            request.url = urlComponents.url

            return session.dataTaskPublisher(for: request)
                .map { $0.data }
                .decode(type: Feed.self, decoder: JSONDecoder())
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    
    func getPlaceFeed(token: String, placeKey: String, size: Int, nextPage: String) -> AnyPublisher<Feed, Error> {
            let url = baseURL.appendingPathComponent("/feed/place/\(placeKey)")
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            urlComponents.queryItems = [
                URLQueryItem(name: "size", value: String(size)),
                URLQueryItem(name: "nextPage", value: nextPage)
            ]
            request.url = urlComponents.url

            return session.dataTaskPublisher(for: request)
                .map { $0.data }
                .decode(type: Feed.self, decoder: JSONDecoder())
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    
    func followPlace(token: String, placeKey: String) -> AnyPublisher<Void, Error> {
            let url = baseURL.appendingPathComponent("/places/\(placeKey)/follow")
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            return session.dataTaskPublisher(for: request)
                .tryMap { response in
                    guard let httpResponse = response.response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                        throw URLError(.badServerResponse)
                    }
                    return ()
                }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    
    func unfollowPlace(token: String, placeKey: String) -> AnyPublisher<Void, Error> {
            let url = baseURL.appendingPathComponent("/places/\(placeKey)/follow")
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            return session.dataTaskPublisher(for: request)
                .tryMap { response in
                    guard let httpResponse = response.response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                        throw URLError(.badServerResponse)
                    }
                    return ()
                }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    
    func updatePlace(token: String, placeKey: String, placeUpdateBody: PlaceUpdateBody) -> AnyPublisher<PlaceDetails, Error> {
            let url = baseURL.appendingPathComponent("/places/\(placeKey)")
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = try? JSONEncoder().encode(placeUpdateBody)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            return session.dataTaskPublisher(for: request)
                .map { $0.data }
                .decode(type: PlaceDetails.self, decoder: JSONDecoder())
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    
    func getLocationInfo(token: String, latitude: Double, longitude: Double) -> AnyPublisher<MapCenterAddressResponse, Error> {
        let url = baseURL.appendingPathComponent("/places-info")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if !token.isEmpty{
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude))
        ]
        request.url = urlComponents.url
        
        
        return session.dataTaskPublisher(for: request)
            .map { $0.data }
            .handleEvents(receiveOutput: { data in
                if let dataString = String(data: data, encoding: .utf8) {
                    print("Received data: \(dataString)")
                } else {
                    print("Failed to convert data to a string.")
                }
            })
            .decode(type: MapCenterAddressResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        
    }
    
    //Free API
    func fetchCityDetails(using geocoder: CLGeocoder, latitude: Double, longitude: Double) -> AnyPublisher<MapCenterAddressResponse, Error> {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        return Future<MapCenterAddressResponse, Error> { promise in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    promise(.failure(error))
                } else if let placemark = placemarks?.first {
                    let response = MapCenterAddressResponse(
                        centerCoordinate: CLLocationCoordinate2D(latitude: placemark.location?.coordinate.latitude ?? 0,
                                                                 longitude: placemark.location?.coordinate.longitude ?? 0),
                        suburb: placemark.subLocality,
                        //cityDistrict: placemark.locality,
                        city: placemark.locality,
                        //municipality: placemark.administrativeArea,
                        county: placemark.subAdministrativeArea,
                        stateDistrict: nil, // CLPlacemark doesn't provide direct stateDistrict data
                        //state: placemark.administrativeArea,
                        country: placemark.country
                    )
                    promise(.success(response))
                } else {
                    promise(.success(MapCenterAddressResponse()))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    //MARK: GroupRepositories
    
    func getEventByGroup(token: String, key: String, pastEvents: Bool, page: Int, size: Int) -> AnyPublisher<[FeedPost], Error> {
        var urlComponents = URLComponents(string: "\(baseURL)/groups/\(key)/events")!
        urlComponents.queryItems = [
            URLQueryItem(name: "pastEvents", value: "\(pastEvents)"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "size", value: "\(size)")
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> [FeedPost] in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode([FeedPost].self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func createGroup(token: String, createGroupBody: CreateGroupBody) -> AnyPublisher<GroupDetails, Error> {
        
        guard let url = URL(string: "\(baseURL)/groups") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let requestBody = try JSONEncoder().encode(createGroupBody)
            request.httpBody = requestBody
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> GroupDetails in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode(GroupDetails.self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func updateGroup(token: String, groupKey: String, createGroupBody: CreateGroupBody) -> AnyPublisher<GroupDetails, Error> {
        guard let url = URL(string: "\(baseURL)/groups/\(groupKey)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let requestBody = try JSONEncoder().encode(createGroupBody)
            request.httpBody = requestBody
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> GroupDetails in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode(GroupDetails.self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func getRecommendedGroup(token: String, coordinates: String, latitude: Double, longitude: Double, size: Int) -> AnyPublisher<[GroupDetails], Error> {
        guard var urlComponents = URLComponents(string: "\(baseURL)/groups/recommended") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "latitude", value: "\(latitude)"),
            URLQueryItem(name: "longitude", value: "\(longitude)"),
            URLQueryItem(name: "size", value: "\(size)")
        ]

        guard let url = urlComponents.url else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(coordinates, forHTTPHeaderField: "Orbis-Coordinates")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> [GroupDetails] in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode([GroupDetails].self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func getGroups(token: String, latitude: Double, longitude: Double, name: String, size: Int, page: Int) -> AnyPublisher<[GroupDetails], Error> {
        
        guard var urlComponents = URLComponents(string: "\(baseURL)/groups") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "latitude", value: "\(latitude)"),
            URLQueryItem(name: "longitude", value: "\(longitude)"),
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "size", value: "\(size)"),
            URLQueryItem(name: "page", value: "\(page)")
        ]

        guard let url = urlComponents.url else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> [GroupDetails] in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode([GroupDetails].self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func getGroupsWithoutLocation(token: String, size: Int, page: Int) -> AnyPublisher<[GroupDetails], Error> {
        guard var urlComponents = URLComponents(string: "\(baseURL)/groups") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "size", value: "\(size)"),
            URLQueryItem(name: "page", value: "\(page)")
        ]

        guard let url = urlComponents.url else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> [GroupDetails] in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode([GroupDetails].self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func getUserGroups(token: String, coordinates: String, userKey: String, size: Int, page: Int) -> AnyPublisher<[GroupDetails], Error> {
        guard var urlComponents = URLComponents(string: "\(baseURL)/profile/\(userKey)/groupFollower") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "size", value: "\(size)"),
            URLQueryItem(name: "page", value: "\(page)")
        ]

        guard let url = urlComponents.url else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(coordinates, forHTTPHeaderField: "Orbis-Coordinates")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> [GroupDetails] in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode([GroupDetails].self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func getRatedGroups(token: String, latitude: Double, longitude: Double, timePeriod: Int, size: Int, page: Int) -> AnyPublisher<[GroupDetails], Error> {
        guard var urlComponents = URLComponents(string: "\(baseURL)/groups/rating") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "latitude", value: "\(latitude)"),
            URLQueryItem(name: "longitude", value: "\(longitude)"),
            URLQueryItem(name: "timePeriod", value: "\(timePeriod)"),
            URLQueryItem(name: "size", value: "\(size)"),
            URLQueryItem(name: "page", value: "\(page)")
        ]

        guard let url = urlComponents.url else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> [GroupDetails] in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode([GroupDetails].self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func getGroupFeed(token: String, groupKey: String, nextPage: String, size: Int) -> AnyPublisher<Feed, Error> {
        
        guard var urlComponents = URLComponents(string: "\(baseURL)/feed/group/\(groupKey)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "nextPage", value: nextPage),
            URLQueryItem(name: "size", value: "\(size)")
        ]

        guard let url = urlComponents.url else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Feed in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode(Feed.self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func getGroupFeedFirst(token: String, groupKey: String, size: Int) -> AnyPublisher<Feed, Error> {
        guard var urlComponents = URLComponents(string: "\(baseURL)/feed/group/\(groupKey)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "size", value: "\(size)")
        ]

        guard let url = urlComponents.url else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Feed in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode(Feed.self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func getGroupByKey(token: String, coordinates: String, groupKey: String) -> AnyPublisher<GroupDetails, Error> {
        
        guard let url = URL(string: "\(baseURL)/groups/\(groupKey)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(coordinates, forHTTPHeaderField: "Orbis-Coordinates")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> GroupDetails in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode(GroupDetails.self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func likePost(token: String, postKey: String) -> AnyPublisher<FeedPost, Error> {
        guard let url = URL(string: "\(baseURL)/posts/\(postKey)/like") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> FeedPost in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode(FeedPost.self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func unlikePost(token: String, postKey: String) -> AnyPublisher<FeedPost, Error> {
        guard let url = URL(string: "\(baseURL)/posts/\(postKey)/like") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> FeedPost in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode(FeedPost.self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func getGroupMembers(token: String, groupKey: String, page: Int, size: Int) -> AnyPublisher<[User], Error> {
        
        guard let url = URL(string: "\(baseURL)/groups/\(groupKey)/members?page=\(page)&size=\(size)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> [User] in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode([User].self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func getGroupAdmins(token: String, groupKey: String, size: Int, page: Int) -> AnyPublisher<[User], Error> {
        guard let url = URL(string: "\(baseURL)/groups/\(groupKey)/admins?size=\(size)&page=\(page)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> [User] in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode([User].self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func addBan(token: String, groupKey: String, userKey: String) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(baseURL)/groups/\(groupKey)/banned/\(userKey)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return ()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func blockGroup(token: String, groupKey: String) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(baseURL)/groups/\(groupKey)/block") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return ()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func unBlockGroup(token: String, groupKey: String) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(baseURL)/groups/\(groupKey)/unblock") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return ()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func addAdmin(token: String, groupKey: String, userKey: String) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(baseURL)/groups/\(groupKey)/admins/\(userKey)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return ()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func adminRemoveAdmin(token: String, groupKey: String, userKey: String) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(baseURL)/groups/\(groupKey)/admins/\(userKey)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return ()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func attendEvent(token: String, postKey: String) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(baseURL)/events/\(postKey)/attend") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return ()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func unattendEvent(token: String, postKey: String) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(baseURL)/events/\(postKey)/attend") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return ()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func getPlaceOwnedByGroup(token: String, coordinates: String, ownedByGroupKey: String, page: Int, size: Int) -> AnyPublisher<[PlaceDetails], Error> {
        var urlComponents = URLComponents(string: "\(baseURL)/places")
        urlComponents?.queryItems = [
            URLQueryItem(name: "ownedByGroupKey", value: ownedByGroupKey),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "size", value: "\(size)")
        ]

        guard let url = urlComponents?.url else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(coordinates, forHTTPHeaderField: "Orbis-Coordinates")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return try JSONDecoder().decode([PlaceDetails].self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func joinGroup(token: String, groupKey: String) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(baseURL)/groups/\(groupKey)/members") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return ()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func leaveGroup(token: String, groupKey: String) -> AnyPublisher<Void, Error> {
        
        guard let url = URL(string: "\(baseURL)/groups/\(groupKey)/members") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return ()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func followGroup(token: String, groupKey: String) -> AnyPublisher<Void, Error> {
        
        guard let url = URL(string: "\(baseURL)/groups/\(groupKey)/followers") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return ()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func unfollowGroup(token: String, groupKey: String) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(baseURL)/groups/\(groupKey)/followers") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return ()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func deleteGroup(token: String, groupKey: String) -> AnyPublisher<Void, Error> {
        
        guard let url = URL(string: "\(baseURL)/groups/\(groupKey)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return ()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func sharePost(token: String, postKey: String) -> AnyPublisher<Data, Error> {
        guard let url = URL(string: "\(baseURL)/posts/\(postKey)/share") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func deletePost(token: String, postKey: String) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(baseURL)/posts/\(postKey)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return ()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func getPost(token: String, postKey: String) -> AnyPublisher<FeedPost, Error> {
        guard let url = URL(string: "\(baseURL)/posts/\(postKey)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: FeedPost.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func reportPost(token: String, postKey: String, requestBody: Data) -> AnyPublisher<Data, Error> {
        guard let url = URL(string: "\(baseURL)/posts/\(postKey)/report") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBody

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func reportGroup(token: String, groupKey: String, requestBody: Data) -> AnyPublisher<Data, Error> {
        guard let url = URL(string: "\(baseURL)/groups/\(groupKey)/report") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBody

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    



    
}
