//
//  PlaceViewModel.swift
//  Orbis-iOS
//
//  Created by Kamran on 30/10/2024.
//


import SwiftUI
import Combine
import Firebase
import FirebaseStorage
import GoogleMaps
import CoreLocation
import Photos

class PlaceViewModel: ObservableObject {
    // Published properties to automatically update SwiftUI views
        @Published var recommendedGroups: [GroupDetails] = []
        @Published var error: String = ""
        @Published var isLoading: Bool = false
        @Published var placeDetails: PlaceDetails?
        @Published var mapPlaces: [PlaceDetails] = []
        @Published var mapPolygonPlaces: [PolygonPlaceDetails] = []
        @Published var mapGroups: [String] = []
        @Published var newAddedPlace: PlaceDetails?
        @Published var newAddedPolygonPlace: PolygonPlaceDetails?
        @Published var updatedPolygon: (PolygonPlaceDetails, [PolygonPlaceDetails?])?
        @Published var polygonsInUpdate: [PolygonPlaceDetails: [PolygonPlaceDetails?]] = [:]
        @Published var updatedCircle: (PolygonPlaceDetails, PolygonPlaceDetails?)?
        @Published var polygonFocusedPlaces: [PolygonPlaceDetails] = []
        @Published var newFocusedChanges: (PolygonPlaceDetails, PolygonPlaceDetails)?
        @Published var locationInfo: MapCenterAddressResponse?
        @Published var feed: Feed?
        @Published var placeFollowed: Bool = false
        @Published var placeUnfollowed: Bool = false
        @Published var getPost: FeedPost?
        @Published var events: [FeedPost] = []
        @Published var allCities: [String: CLLocationCoordinate2D] = [:]
        @Published var changedFocus: Bool = false
        @Published var locationSharedOrSelected: Bool = false
        @Published var lastLocationSelected: CLLocation?
        @Published var checkInProgress: Int = 1
        @Published var placeRated: RatePlaceModel? // New property added
        @Published var postCreated: FeedPost? = nil
        @Published var fileUpload: Bool = false  // not using.
    
    
    
    //MARK: values to prenvent first time emitting
    @Published var isInitialMapPolygonPlacesLoad = true
    @Published var isInitialPolygonFocusedPlacesLoad = true
    @Published var isInitialNewFocusedChangesLoad = true
    @Published var isInitialNewAddedPlaceLoad = true
    @Published var isInitialUpdatePolygonLoad = true
    @Published var isInitialUpdateCircleLoad = true
    @Published var isInitialLocationInfoLoad = true
    @Published var isInitialAllCitiesLoad = true
    @Published var isInitialNewAddedPolygonPlace = true

    
    private var cancellables = Set<AnyCancellable>()
    var postBody: PostBody? = nil

    var firstNewChange = false
    
    //MARK: Repositories code
    let placeRepositories = PlaceRepository()
    let groupRepositories = GroupRepositories()
    let authRepositories = AuthRepositories()
    
    
    // Async loading for check-in progress
    func startCheckInLoading() async {
        for i in 1...15 {
            await updateCheckInProgress(to: i)
            try? await Task.sleep(nanoseconds: 55 * 1_000_000) // 55 milliseconds
        }
        
        for i in 16...75 {
            await updateCheckInProgress(to: i)
            try? await Task.sleep(nanoseconds: 26 * 1_000_000) // 26 milliseconds
        }
        
        for i in 76...99 {
            await updateCheckInProgress(to: i)
            try? await Task.sleep(nanoseconds: 300 * 1_000_000) // 300 milliseconds
        }
    }
    
    // Helper functions to update progress, complete, and restart
    private func updateCheckInProgress(to value: Int) async {
        await MainActor.run { self.checkInProgress = value }
    }
    
    func completeCheckInProgressBar() {
        Task {
            await updateCheckInProgress(to: 100)
        }
    }
    
    func restartCheckInProgressBar() {
        Task {
            await updateCheckInProgress(to: 1)
        }
    }
    
    //MARK: Data Fetch Section
    func getEvents(placeKey: String, page: Int) {
            isLoading = true
            placeRepositories.getEvents(placeKey: placeKey, page: page)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    switch completion {
                    case .failure(let error):
                        if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                            if self.authRepositories.isSocialLogin() {
                                Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { token, tokenError in
                                    if let token = token {
                                        self.authRepositories.saveIdToken(token: token)
                                        self.getEvents(placeKey: placeKey, page: page)
                                    } else {
                                        self.error = tokenError?.localizedDescription ?? ""
                                    }
                                }
                            } else {
                                self.authRepositories.refreshToken()
                                    .subscribe(on: DispatchQueue.global(qos: .background))
                                    .receive(on: DispatchQueue.main)
                                    .sink(receiveCompletion: { refreshCompletion in
                                        switch refreshCompletion {
                                        case .failure(let refreshError):
                                            self.error = refreshError.localizedDescription
                                        case .finished:
                                            break
                                        }
                                    }, receiveValue: { response in
                                        if let token = String(data: response, encoding: .utf8) {
                                            self.authRepositories.saveIdToken(token: token)
                                            self.getEvents(placeKey: placeKey, page: page)
                                        }
                                    })
                                    .store(in: &self.cancellables)
                            }
                        } else {
                            self.error = error.localizedDescription
                        }
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] events in
                    self?.isLoading = false
                    self?.events = events
                })
                .store(in: &cancellables)
        }
    
    func buildCities(inputStream: InputStream) {
            struct City: Decodable {
                let n: String // name
                let c: String // country
                let l: Double // latitude
                let g: Double // longitude
            }

            DispatchQueue.global(qos: .background).async {
                do {
                    let reader = InputStreamReader(stream: inputStream)
                    let data = try reader.readAll()
                    
                    let cityList = try JSONDecoder().decode([City].self, from: data)
                    var cities: [String: CLLocationCoordinate2D] = [:]

                    for city in cityList {
                        let cityLocation = CLLocationCoordinate2D(latitude: city.l, longitude: city.g)
                        cities["\(city.n), \(city.c)"] = cityLocation
                    }

                    DispatchQueue.main.async {
                        self.allCities = cities
                    }

                } catch {
                    print("Error parsing cities JSON: \(error.localizedDescription)")
                }
            }
        }
    
    func getPost(postKey: String) {
            isLoading = true
        groupRepositories.getPost(postKey: postKey)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    switch completion {
                    case .failure(let error):
                        if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                            if self.authRepositories.isSocialLogin() {
                                Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { token, tokenError in
                                    if let token = token {
                                        self.authRepositories.saveIdToken(token: token)
                                        self.getPost(postKey: postKey)
                                    } else {
                                        self.error = tokenError?.localizedDescription ?? ""
                                    }
                                }
                            } else {
                                self.authRepositories.refreshToken()
                                    .subscribe(on: DispatchQueue.global(qos: .background))
                                    .receive(on: DispatchQueue.main)
                                    .sink(receiveCompletion: { refreshCompletion in
                                        switch refreshCompletion {
                                        case .failure(let refreshError):
                                            self.error = refreshError.localizedDescription
                                        case .finished:
                                            break
                                        }
                                    }, receiveValue: { response in
                                        if let token = String(data: response, encoding: .utf8) {
                                            self.authRepositories.saveIdToken(token: token)
                                            self.getPost(postKey: postKey)
                                        }
                                    })
                                    .store(in: &self.cancellables)
                            }
                        } else {
                            self.error = error.localizedDescription
                        }
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] post in
                    self?.isLoading = false
                    self?.getPost = post
                })
                .store(in: &cancellables)
        }
    
    func findRecommendedGroup(latitude: Double, longitude: Double) {
            isLoading = true
            groupRepositories.getRecommendedGroup(latitude: latitude, longitude: longitude)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self.isLoading = false
                        if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                            self.handleUnauthorizedError(retryAction: {
                                self.findRecommendedGroup(latitude: latitude, longitude: longitude)
                            })
                        } else {
                            self.error = error.localizedDescription
                        }
                    }
                }, receiveValue: { [weak self] groups in
                    self?.isLoading = false
                    self?.recommendedGroups = groups
                })
                .store(in: &cancellables)
        }
    
    func createPlace(createPlaceBody: CreatePlaceBody) {
            isLoading = true
            placeRepositories.createPlace(createPlaceBody: createPlaceBody)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    switch completion {
                    case .failure(let error):
                        if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                            self.handleUnauthorizedError(retryAction: {
                                self.createPlace(createPlaceBody: createPlaceBody)
                            })
                        } else {
                            self.error = error.localizedDescription
                        }
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] place in
                    self?.isLoading = false
                    self?.placeDetails = place
                })
                .store(in: &cancellables)
        }
    
    func ratePlace(ratePlaceBody: RatePlaceBody) {
            isLoading = true
            placeRepositories.ratePlace(ratePlaceBody: ratePlaceBody)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    switch completion {
                    case .failure(let error):
                        if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                            self.handleUnauthorizedError(retryAction: {
                                self.ratePlace(ratePlaceBody: ratePlaceBody)
                            })
                        } else {
                            self.error = error.localizedDescription
                        }
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] ratedPlace in
                    self?.isLoading = false
                    self?.placeRated = ratedPlace
                })
                .store(in: &cancellables)
        }
    
    //MARK: handle Authorization Error
    private func handleUnauthorizedError(retryAction: @escaping () -> Void) {
            if authRepositories.isSocialLogin() {
                Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { [weak self] token, error in
                    guard let self = self else { return }
                    if let token = token {
                        self.authRepositories.saveIdToken(token: token)
                        retryAction()
                    } else {
                        self.error = error?.localizedDescription ?? ""
                    }
                }
            } else {
                authRepositories.refreshToken()
                    .subscribe(on: DispatchQueue.global(qos: .background))
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { [weak self] completion in
                        guard let self = self else { return }
                        if case .failure(let error) = completion {
                            self.error = error.localizedDescription
                        }
                    }, receiveValue: { [weak self] response in
                        guard let self = self else { return }
                        if let token = String(data: response, encoding: .utf8) {
                            self.authRepositories.saveIdToken(token: token)
                            retryAction()
                        }
                    })
                    .store(in: &cancellables)
            }
        }
    
    //MARK: not using for now
    func findPlacesForMap(latitude: Double, longitude: Double, page: Int = 0) {
            isLoading = true
            placeRepositories.findPlacesForMap(latitude: latitude, longitude: longitude, page: page)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    switch completion {
                    case .failure(let error):
                        if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                            self.handleUnauthorizedError(retryAction: {
                                self.findPlacesForMap(latitude: latitude, longitude: longitude, page: page)
                            })
                        } else {
                            self.error = error.localizedDescription
                        }
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] places in
                    self?.isLoading = false
                    self?.mapPlaces = places
                })
                .store(in: &cancellables)
        }
    func findGroupsForMap(latitude: Double, longitude: Double, page: Int = 0) {
            isLoading = true
            placeRepositories.findGroupsForMap(latitude: latitude, longitude: longitude, page: page)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    switch completion {
                    case .failure(let error):
                        if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                            self.handleUnauthorizedError(retryAction: {
                                self.findGroupsForMap(latitude: latitude, longitude: longitude, page: page)
                            })
                        } else {
                            self.error = error.localizedDescription
                        }
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] groups in
                    self?.mapGroups = groups
                })
                .store(in: &cancellables)
        }
    //MARK: End of Unused Methods
    
    func clearMapPolygonPlaces() {
            mapPolygonPlaces = []
        }
    
    //MARK: End of Unused Methods
    
    func findPolygonPlacesForMap(latitude: Double, longitude: Double, page: Int = 0) {
            isLoading = true
            placeRepositories.findPolygonPlacesForMap(latitude: latitude, longitude: longitude, page: page)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    switch completion {
                    case .failure(let error):
                        if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                            self.handleUnauthorizedError(retryAction: {
                                self.findPolygonPlacesForMap(latitude: latitude, longitude: longitude, page: page)
                            })
                        } else {
                            self.error = error.localizedDescription
                        }
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] polygonPlaces in
                    if polygonPlaces.count == 0 {
                        print("polygonPlaces count is zero \(polygonPlaces.count)")
                    }
                    self?.isLoading = false
                    self?.mapPolygonPlaces = polygonPlaces
                })
                .store(in: &cancellables)
        }
    
    



    //MARK: not using for now
    func updatePolygon(parentPlace: PolygonPlaceDetails, polygonSubPlace: PolygonPlaceDetails) {
            if polygonsInUpdate[parentPlace] == nil || polygonsInUpdate[parentPlace]?.isEmpty == true {
                polygonsInUpdate[parentPlace] = []
            }
            placeRepositories.getPolygonPlaceDetails(placeKey: polygonSubPlace.placeKey!)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    switch completion {
                    case .failure(let error):
                        if (error as NSError).domain == NSURLErrorDomain, (error as NSError).code == NSURLErrorCannotDecodeContentData {
                            self.polygonsInUpdate[parentPlace]?.append(nil)
                            if self.polygonsInUpdate[parentPlace]?.count == parentPlace.places?.count {
                                self.updatedPolygon = (parentPlace, self.polygonsInUpdate[parentPlace]!)
                            }
                        } else {
                            self.isLoading = false
                            self.error = error.localizedDescription
                        }
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] polygonDetail in
                    guard let self = self else { return }
                    self.polygonsInUpdate[parentPlace]?.append(polygonDetail)
                    if self.polygonsInUpdate[parentPlace]?.count == parentPlace.places?.count {
                        self.updatedPolygon = (parentPlace, self.polygonsInUpdate[parentPlace]!)
                    }
                })
                .store(in: &cancellables)
        }
    func updateCircle(polygonSubPlace: PolygonPlaceDetails) {
            placeRepositories.getPolygonPlaceDetails(placeKey: polygonSubPlace.placeKey!)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    switch completion {
                    case .failure(let error):
                        if (error as NSError).domain == NSURLErrorDomain, (error as NSError).code == NSURLErrorCannotDecodeContentData {
                            self.updatedCircle = (polygonSubPlace, nil)
                        } else {
                            self.isLoading = false
                            self.error = error.localizedDescription
                        }
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] polygonDetail in
                    guard let self = self else { return }
                    self.updatedCircle = (polygonSubPlace, polygonDetail)
                })
                .store(in: &cancellables)
        }
    //MARK: End of Unused Methods
    
    func getUpdatedFocusedPolygonPlace(placeKey: String) {
        placeRepositories.getPolygonPlaceDetails(placeKey: placeKey)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                        self.handleUnauthorizedError(retryAction: {
                            self.getUpdatedFocusedPolygonPlace(placeKey: placeKey)
                        })
                    } else {
                        self.error = error.localizedDescription
                    }
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] polygonDetail in
                guard let self = self else { return }
                var updatedPolygonDetail = polygonDetail
                if let index = self.polygonFocusedPlaces.firstIndex(where: { $0.placeKey == placeKey }) {
                    updatedPolygonDetail.isFocusSelected = true
                    self.polygonFocusedPlaces[index] = updatedPolygonDetail
                    self.changedFocus = false
                }
            })
            .store(in: &cancellables)
    }
    
    func getNewPlace(placeKey: String) {
            isLoading = true
            placeRepositories.getPlaceDetails(placeKey: placeKey)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    switch completion {
                    case .failure(let error):
                        if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                            self.handleUnauthorizedError(retryAction: {
                                self.getNewPlace(placeKey: placeKey)
                            })
                        } else {
                            self.error = error.localizedDescription
                        }
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] placeDetails in
                    self?.isLoading = false
                    self?.newAddedPlace = placeDetails
                })
                .store(in: &cancellables)
        }
    
    func askPolygonMapUpdate(checkInPolygonCoordinateKey: String, place: PlaceDetails) {
            placeRepositories.getPolygonPlaceStatus(checkInPolygonCoordinateKey: checkInPolygonCoordinateKey)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    switch completion {
                    case .failure(let error):
                        if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                            self.handleUnauthorizedError(retryAction: {
                                self.askPolygonMapUpdate(checkInPolygonCoordinateKey: checkInPolygonCoordinateKey, place: place)
                            })
                        } else {
                            self.error = error.localizedDescription
                        }
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] status in
                    guard let self = self else { return }
                    if status.status == "DONE" {
                        self.newAddedPlace = place
                    } else {
                        self.askPolygonMapUpdate(checkInPolygonCoordinateKey: checkInPolygonCoordinateKey, place: place)
                    }
                })
                .store(in: &cancellables)
        }
    
    func findPolygonPlace(placeKey: String) {
            isLoading = true
            placeRepositories.getPolygonPlaceDetails(placeKey: placeKey)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    switch completion {
                    case .failure(let error):
                        if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                            self.handleUnauthorizedError(retryAction: {
                                self.findPolygonPlace(placeKey: placeKey)
                            })
                        } else {
                            self.error = error.localizedDescription
                        }
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] polygonPlace in
                    self?.newAddedPolygonPlace = polygonPlace
                })
                .store(in: &cancellables)
        }

    func getPlaces(latitude: Double, longitude: Double, name: String, page: Int, distance: Int = 1) {
            isLoading = true
            placeRepositories.getPlaces(latitude: latitude, longitude: longitude, name: name, page: page, distance: distance)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    switch completion {
                    case .failure(let error):
                        if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                            self.handleUnauthorizedError(retryAction: {
                                self.getPlaces(latitude: latitude, longitude: longitude, name: name, page: page)
                            })
                        } else {
                            self.error = error.localizedDescription
                        }
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] places in
                    self?.mapPlaces = places
                })
                .store(in: &cancellables)
        }
    
    func uploadEventImage(context: UIViewController, uri: URL) {
            isLoading = true
            let data: Data
            do {
                data = try Data(contentsOf: uri)
            } catch {
                self.isLoading = false
                self.error = "Failed to read image data"
                return
            }

            let type = (uri.pathExtension.isEmpty ? "jpg" : uri.pathExtension)
            let imageName = UUID().uuidString + "." + type
            let path = "\(Constants.EVENT_STORAGE)\(imageName)"
            
            let metadata = StorageMetadata()
            metadata.contentType = {
                switch type.lowercased() {
                case "png": return "image/png"
                case "tiff": return "image/tiff"
                case "webp": return "image/webp"
                default: return "image/jpeg"
                }
            }()

            let storage = Storage.storage().reference().child(path)
        storage.putData(data, metadata: metadata) { [weak self] (metadata: StorageMetadata?, error: Error?) in
            guard let self = self else { return }
            self.isLoading = false
            if let error = error {
                self.error = error.localizedDescription
            } else {
                self.postBody?.mediaUrls.append(imageName)
                self.createPost()
            }
        }

        }
    
    func uploadPostImage(context: UIViewController, uris: [URL], position: Int = 0) {
            guard position < uris.count else {
                isLoading = false
                if postBody?.checkin == true {
                    createCheckinPost()
                } else {
                    createPost()
                }
                return
            }

            isLoading = true
            let uri = uris[position]
            guard let image = UIImage(contentsOfFile: uri.path) else {
                self.error = "Failed to load image."
                self.uploadPostImage(context: context, uris: uris, position: position + 1)
                return
            }

            let data = image.jpegData(compressionQuality: 1.0) ?? Data()
            let imageName = UUID().uuidString + ".jpg"
            let path = "posts/images/\(imageName)"
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"

            let storageRef = Storage.storage().reference().child(path)
            storageRef.putData(data, metadata: metadata) { [weak self] _, error in
                guard let self = self else { return }
                if let error = error {
                    self.error = error.localizedDescription
                    self.uploadPostImage(context: context, uris: uris, position: position + 1)
                } else {
                    self.postBody?.mediaUrls.append(imageName)
                    self.uploadPostImage(context: context, uris: uris, position: position + 1)
                }
            }
        }
    
    func uploadAudioPost(file: URL) {
            isLoading = true
            let audioName = file.lastPathComponent
            let path = "posts/audios/\(audioName)"
            print("uploadPath: \(path)")
            let metadata = StorageMetadata()
            metadata.contentType = "audio/wav"

            let storage = Storage.storage().reference().child(path)
            storage.putFile(from: file, metadata: metadata) { [weak self] metadata, error in
                guard let self = self else { return }
                if let error = error {
                    self.isLoading = false
                    self.error = error.localizedDescription
                    print("Upload failed: \(error.localizedDescription)")
                    return
                }

                self.postBody?.mediaUrls.append(audioName)
                try? FileManager.default.removeItem(at: file)

                if self.postBody?.checkin == true {
                    self.createCheckinPost()
                } else {
                    self.createPost()
                }
            }
        }
    
    func uploadVideoPost(context: UIViewController, uri: URL) {
        isLoading = true
        guard let mimeType = uri.mimeType() else {
            print("Error determining MIME type")
            error = "Could not determine video type"
            isLoading = false
            return
        }

        let videoName = UUID().uuidString + "." + (mimeType == "video/mp4" ? "mp4" : "mov")
        let path = "posts/videos/\(videoName)"
        print("uploadPath: \(path)")

        let storage = Storage.storage().reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = mimeType

        storage.putFile(from: uri, metadata: metadata) { [weak self] (metadata: StorageMetadata?, error: Error?) in
            guard let self = self else { return }
            self.isLoading = false

            if let error = error {
                print("Upload failed: \(error.localizedDescription)")
                self.error = error.localizedDescription
                return
            }

            self.postBody?.mediaUrls.append(videoName)
            if self.postBody?.checkin == true {
                self.createCheckinPost()
            } else {
                self.createPost()
            }
        }
    }

    func createPost(checkinPost: FeedPost? = nil) {
            postBody?.type = postBody?.subType ?? ""
            postBody?.checkin = false
            isLoading = true
            placeRepositories.createPost(postBody: postBody!)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    switch completion {
                    case .failure(let error):
                        if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                            self.handleUnauthorizedError(retryAction: {
                                self.createPost()
                            })
                        } else {
                            self.error = error.localizedDescription
                        }
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] post in
                    guard let self = self else { return }
                    self.isLoading = false
                    self.postCreated = checkinPost ?? post
                })
                .store(in: &cancellables)
        }
    
    func createCheckinPost() {
            postBody?.type = "CHECK_IN"
            isLoading = true
            placeRepositories.createPost(postBody: postBody!)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    switch completion {
                    case .failure(let error):
                        if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                            self.handleUnauthorizedError(retryAction: {
                                self.createCheckinPost()
                            })
                        } else {
                            self.error = error.localizedDescription
                        }
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] post in
                    guard let self = self else { return }
                    self.followPlace(placeKey: self.postBody?.placeKey ?? "")
                    if !(self.postBody?.subType.isEmpty ?? true) {
                        self.createPost(checkinPost: post)
                    } else {
                        self.postCreated = post
                    }
                })
                .store(in: &cancellables)
        }
    
    func getPlaceFeedFirst(placeKey: String) {
        isLoading = true
        placeRepositories.getPlaceFeedFirst(placeKey: placeKey)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                switch completion {
                case .failure(let error):
                    if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                        self.handleUnauthorizedError(retryAction: {
                            self.getPlaceFeedFirst(placeKey: placeKey)
                        })
                    } else {
                        self.error = error.localizedDescription
                    }
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] feed in
                self?.isLoading = false
                self?.feed = feed
            })
            .store(in: &cancellables)
    }

    func getPlaceFeed(placeKey: String, nextPage: String) {
        isLoading = true
        placeRepositories.getPlaceFeed(placeKey: placeKey, nextPage: nextPage)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                switch completion {
                case .failure(let error):
                    if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                        self.handleUnauthorizedError(retryAction: {
                            self.getPlaceFeed(placeKey: placeKey, nextPage: nextPage)
                        })
                    } else {
                        self.error = error.localizedDescription
                    }
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] feed in
                self?.isLoading = false
                self?.feed = feed
            })
            .store(in: &cancellables)
    }
    
    func getLocationInfo(latitude: Double, longitude: Double) {
        placeRepositories.getLocationInfo(latitude: latitude, longitude: longitude)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                switch completion {
                case .failure(let error):
                    self.locationInfo = nil
                    if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                        self.handleUnauthorizedError(retryAction: {
                            self.getLocationInfo(latitude: latitude, longitude: longitude)
                        })
                    } else {
                        self.error = error.localizedDescription
                    }
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] locationInfo in
                var mlocationInfo = locationInfo
                var coordinate2D = CLLocationCoordinate2D()
                coordinate2D.latitude = latitude
                coordinate2D.longitude = longitude
                mlocationInfo.centerCoordinate = coordinate2D
                self?.locationInfo = mlocationInfo
               
            })
            .store(in: &cancellables)
    }

    func getCapturedImage(context: UIViewController, selectedPhotoUri: URL) -> UIImage? {
        let asset = PHAsset.fetchAssets(withALAssetURLs: [selectedPhotoUri], options: nil).firstObject
        
        if let asset = asset {
            let imageManager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.deliveryMode = .highQualityFormat
            
            var image: UIImage?
            imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { result, _ in
                image = result
            }
            return image
        } else {
            return nil
        }
    }

    
    func followPlace(placeKey: String) {
            isLoading = true
            placeRepositories.followPlace(placeKey: placeKey)
                .subscribe(on: DispatchQueue.global(qos: .background))
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    switch completion {
                    case .failure(let error):
                        if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                            self.handleUnauthorizedError(retryAction: {
                                self.followPlace(placeKey: placeKey)
                            })
                        } else {
                            self.error = error.localizedDescription
                        }
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] _ in
                    self?.isLoading = false
                    self?.placeFollowed = true
                })
                .store(in: &cancellables)
        }
    
    func unfollowPlace(placeKey: String) {
        isLoading = true
        placeRepositories.unfollowPlace(placeKey: placeKey)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                switch completion {
                case .failure(let error):
                    if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                        self.handleUnauthorizedError(retryAction: {
                            self.unfollowPlace(placeKey: placeKey)
                        })
                    } else {
                        self.error = error.localizedDescription
                    }
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] _ in
                self?.isLoading = false
                self?.placeUnfollowed = true
            })
            .store(in: &cancellables)
    }

    func updatePlace(placeUpdateBody: PlaceUpdateBody, placeKey: String) {
        isLoading = true
        placeRepositories.updatePlace(placeUpdateBody: placeUpdateBody, placeKey: placeKey)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                switch completion {
                case .failure(let error):
                    if let httpError = error as? URLError, httpError.code == .userAuthenticationRequired {
                        self.handleUnauthorizedError(retryAction: {
                            self.updatePlace(placeUpdateBody: placeUpdateBody, placeKey: placeKey)
                        })
                    } else {
                        self.error = error.localizedDescription
                    }
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] placeDetails in
                self?.isLoading = false
                self?.placeDetails = placeDetails
            })
            .store(in: &cancellables)
    }

    func uploadPlaceImage(context: UIViewController, resultUri: URL, selectedImage: UIImage, placeKey: String) {
        isLoading = true
        var placeUpdateBody = PlaceUpdateBody()

        let type = resultUri.mimeType() ?? "jpg"
        if type.isEmpty {
            error = "Unknown file type"
            isLoading = false
            return
        }


        let imageName = UUID().uuidString + "." + type
        let path = "PLACE_PICTURES/\(imageName)"
        print("uploadPath: \(path)")

        guard let imageData = selectedImage.jpegData(compressionQuality: type == "png" ? 1.0 : 0.8) else {
            error = "Failed to process image data"
            isLoading = false
            return
        }

        let metadata = StorageMetadata()
        metadata.contentType = "image/\(type)"

        let storageRef = Storage.storage().reference().child(path)
        storageRef.putData(imageData, metadata: metadata) { [weak self] _, error in
            guard let self = self else { return }
            if let error = error {
                self.isLoading = false
                self.error = error.localizedDescription
                print("Image upload failed: \(error.localizedDescription)")
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    self.isLoading = false
                    self.error = error.localizedDescription
                    print("Failed to get download URL: \(error.localizedDescription)")
                    return
                }

                guard let url = url else {
                    self.isLoading = false
                    self.error = "Invalid download URL"
                    return
                }

                placeUpdateBody.imageName = imageName
                self.updatePlace(placeUpdateBody: placeUpdateBody, placeKey: placeKey)
            }
        }
    }
    
    func clearFocusedPolygonPlaces() {
        changedFocus = false
        polygonFocusedPlaces = []
        newFocusedChanges = nil
    }
    
    func setFocusedListPolygon(places: [PolygonPlaceDetails]) {
            if polygonFocusedPlaces.isEmpty {
                polygonFocusedPlaces = places
            }
            // Block updates from UI without using clearFocusedPolygonPlaces() first
        }
    
    //MARK: not using for now
    func updateFocusedPolygon() {
        // Iterate over the list and check for focused places
        for place in polygonFocusedPlaces {
            if place.isFocusSelected {
                getUpdatedFocusedPolygonPlace(placeKey: place.placeKey!)
            }
        }
    }

    //MARK: End of Unused Methods
    
    func changeFocusedPlace(position: Int) {
        
        guard position < polygonFocusedPlaces.count else { return }

        var focusedList = polygonFocusedPlaces

        if focusedList[position].isFocusSelected {
            return
        }

        var oldPlaceIndex: Int?

        // Iterate over the list and update the focus state
        for i in 0..<focusedList.count {
            if focusedList[i].isFocusSelected {
                oldPlaceIndex = i
            }
            focusedList[i].isFocusSelected = (i == position)
        }

        // Indicate that the focus has changed
        changedFocus = true
        polygonFocusedPlaces = focusedList

        // If an old place was previously focused, update its state and set the new focused changes
        if let oldPlaceIndex = oldPlaceIndex {
            var oldPlace = focusedList[oldPlaceIndex] // Make a mutable copy
            oldPlace.isFocusSelected = false
            newFocusedChanges = (oldPlace, focusedList[position])
        }
    }

    
    func changeFocusedPlace(selectedPlace: PolygonPlaceDetails) {
        // Return if the selected place is already focused
        if selectedPlace.isFocusSelected {
            return
        }
        
        var mPolygonFocusedPlaces = polygonFocusedPlaces
        
        var mSelectedPlace = selectedPlace

        var oldPlace: PolygonPlaceDetails?
        
        // Iterate over the list to update the focused state
        for i in 0..<polygonFocusedPlaces.count {
            if polygonFocusedPlaces[i].isFocusSelected {
                oldPlace = polygonFocusedPlaces[i]
                oldPlace?.isFocusSelected = false
                mPolygonFocusedPlaces[i].isFocusSelected = false
                
                //print(polygonFocusedPlaces[i].isFocusSelected)

                
            }
            if polygonFocusedPlaces[i].placeKey == selectedPlace.placeKey {
                mPolygonFocusedPlaces[i].isFocusSelected = true
                mSelectedPlace.isFocusSelected = true
                
                //print(polygonFocusedPlaces[i].isFocusSelected)
                
            }
        }
        
        
        // Indicate that the focus has changed
        changedFocus = true
        
        // Trigger update for the focused list
        polygonFocusedPlaces = mPolygonFocusedPlaces
        
        // If an old place was previously focused, set the new focused changes
        if let oldPlace = oldPlace {
            newFocusedChanges = (oldPlace, mSelectedPlace)
        }
    }
    



    func setLastCitySelected(loc: CLLocationCoordinate2D) {
        let customLocation = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
        lastLocationSelected = customLocation
    }
    
    func setLastCitySelected(loc: CLLocation) {
        lastLocationSelected = loc
    }
}


import UniformTypeIdentifiers

extension URL {
    func mimeType() -> String? {
        let pathExtension = self.pathExtension
        if #available(iOS 14.0, *) {
            if let uti = UTType(filenameExtension: pathExtension),
               let mimeType = uti.preferredMIMEType {
                return mimeType
            }
        } else {
            // Fallback on earlier versions
        }
        return nil
    }
}
