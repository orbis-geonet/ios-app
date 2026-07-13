//
//  CreatePostViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 07/04/2021.
//

import Foundation
import CoreLocation
import UIKit

class CreatePostModel {
    var publisher: OrbisUser?
    var groupPublisher: Group?
    var type: OrbisPostType?
    var title: String?
    var description: String?
    var subType: OrbisPostType?
    var checkin: OrbisPlace?
    var images: [UIImage]?
    var imagesData: [Data]?
    var videos: [String]?
    var audio: OrbisVoice?
    var address: String?
    var plannedTime: String?
    var plannedEndTime: String?
    
    var toOrbisFeedPost: OrbisFeedPost {
        var post = OrbisFeedPost(key: "\(Date().timeIntervalSince1970)")
        post.group = groupPublisher
        post.place = checkin
        post.user = publisher
        post.type = self.type?.rawValue ?? ""
        post.details = self.description
        post.pendingPostImages = self.images
        post.pendingPostImagesData = self.imagesData
        post.pendingPostVideos = self.videos
        post.isPendingPost = true
        post.address = address
        post.plannedTime = plannedTime
        post.plannedEndTime = plannedEndTime
        post.title = title
        return post
    }
}

class CreatePostViewModel {
    var model = CreatePostModel()
    var createdPost:OrbisFeedPost?
    let manager = CreatePostManager()
    var selfUser: OrbisUser? {
        return UserSessionManager.shared.currentUser
    }
//    var userLocation: CLLocationCoordinate2D! {
//        return UserSessionManager.shared.userCurrentLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
//    }
    var userLocation: CLLocationCoordinate2D! {
        return Constants.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
    private let recommendedListLimit = 5
    var recommendedGroups = Groups()
    var dropDownUserList: OrbisUsers {
        if allowSelfPublisher && postPlace == nil {
            return (selfUser != nil) ? [selfUser!] : []
        }
        return []
    }
    var allowSelfPublisher: Bool = false
    var isCheckinPost = false
    var isEventModelPhotoMode = false
    let groupDetailManager = GroupDetailManager()
    
    init(defaultPublisherGroup: Group?, isSelfPublisher: Bool = false, selectedPlace: OrbisPlace? = nil, allowUserPublisher: Bool = false) {
        model = CreatePostModel()
        self.type = .textPost
        self.allowSelfPublisher = allowUserPublisher
        if let group = defaultPublisherGroup {
            self.groupPublisher = group
            self.publisher = nil
        }
        else {
            self.groupPublisher = nil
            self.publisher = isSelfPublisher ? selfUser : nil
        }
        self.postPlace = selectedPlace
        if selectedPlace != nil {
            self.publisher = nil
            isCheckinPost = true
        }
    }
    
    func createPostFromModel() {
        var post = OrbisFeedPost(key: "\(Date().timeIntervalSince1970)")
        post.details = self.postDescription
        post.type = self.type.rawValue
        self.createdPost = post
    }
    
    var postImagesCount: Int {
        return postImages.count
    }
    
    var postImagesData: [Data] {
        get {
            return model.imagesData ?? []
        }
        set {
            model.imagesData = newValue
        }
    }
    
    var postImages: [UIImage] {
        get {
            return model.images ?? []
        }
        set {
            model.images = newValue
        }
    }
    
    var postAudio: OrbisVoice? {
        get {
            return model.audio
        }
        set {
            model.audio = newValue
        }
    }
    
    var postVideo: [String]? {
        get {
            return model.videos
        }
        set {
            model.videos = newValue
        }
    }
    
    var publisher: OrbisUser? {
        get {
            return model.publisher
        }
        set {
            model.publisher = newValue
        }
    }
    
    var groupPublisher: Group? {
        get {
            return model.groupPublisher
        }
        set {
            model.groupPublisher = newValue
        }
    }
    
    var type: OrbisPostType {
        get {
            return model.type ?? .checkinPost
        }
        set {
            model.type = newValue
        }
    }
    
    var postDescription: String {
        get {
            return model.description ?? ""
        }
        set {
            model.description = newValue
        }
    }
    
    var subType: OrbisPostType {
        get {
            return model.subType ?? .checkinPost
        }
        set {
            model.subType = newValue
        }
    }
    
    var postPlace: OrbisPlace? {
        get {
            return model.checkin
        }
        set {
            model.checkin = newValue
            if newValue == nil {
                self.publisher = (allowSelfPublisher && groupPublisher == nil) ? selfUser : nil
            }
            else {
                self.publisher = nil
                if groupPublisher == nil {
                    groupPublisher = newValue?.dominantGroup
                }
            }
        }
    }
    
    var postPlaceName: String {
        return postPlace?.name ?? ""
    }
    
    var eventAddress: String {
        get {
            return model.address ?? ""
        }
        set {
            model.address = newValue
        }
    }
    
    var eventTitle: String {
        get {
            return model.title ?? ""
        }
        set {
            model.title = newValue
        }
    }
    
    private var eventStartTime: String {
        get {
            return model.plannedTime ?? ""
        }
        set {
            model.plannedTime = newValue
        }
    }
    
    private var eventEndTime: String {
        get {
            return model.plannedEndTime ?? ""
        }
        set {
            model.plannedEndTime = newValue
        }
    }
    
    var selectedEventDate: Date?
    var selectedEventStartTime: Date?
    var selectedEventEndTime: Date?
    
    var eventDate: String = "" {
        didSet {
            computeEventTime()
        }
    }
    
    var startTime: String = "" {
        didSet {
            computeEventTime()
        }
    }
    
    var endTime: String = "" {
        didSet {
            computeEventTime()
        }
    }
    
    private func computeEventTime() {
        guard !eventDate.isEmpty else {
            self.eventStartTime = ""
            self.eventEndTime = ""
            return
        }
        let dateFormat = "MM/dd/yy HH:mm"
        var eventStartDateStr = eventDate
        var eventEndDateStr = eventDate
        if let eventStartDate = selectedEventStartTime {
            eventStartDateStr = eventStartDate.dateString("MM/dd/yy")
        }
        if let eventEndDate = selectedEventEndTime {
            eventEndDateStr = eventEndDate.dateString("MM/dd/yy")
        }
        let startDateStr = eventStartDateStr + " \(startTime)"
        let endDateStr = eventEndDateStr + " \(endTime)"
        guard let startDate = Date.fromString(dateString: startDateStr, format: dateFormat), let endDate = Date.fromString(dateString: endDateStr, format: dateFormat) else {
            self.eventStartTime = ""
            self.eventEndTime = ""
            return
        }
        eventStartTime = startDate.isoDateString
        eventEndTime = endDate.isoDateString
    }
    
    
    private var publisherPlaceholder: String {
        return (allowSelfPublisher && postPlace == nil) ?  AppStrings.Post.chooseGroupOrUser : AppStrings.Post.chooseGroup
    }
    
    var publisherName: String {
        return publisher?.userDisplayName ?? groupPublisher?.name ?? publisherPlaceholder
    }
    
    var publisherProPicLink: String {
        return publisher?.proPicLink ?? groupPublisher?.imageName ?? ""
    }
    
    var groupBaseColor: UIColor {
        guard let _ = groupPublisher else { return .clear }
        if let strokeColor = groupPublisher?.strokeColorHexString {
            return UIColor.hexStringToUIColor(hex: strokeColor)
        }
        return groupPublisher?.baseColor ?? .clear
    }
    
    var publisherBorderWidth: CGFloat {
        if let _ = groupPublisher {
            return 3.toCGFloat.relativeToIphone8Width()
        }
        return 0
    }
    
    var toCreateParams: [String: Any] {
        var params = [String: Any]()
        params[PostParameterKeys.Create.type] = self.type.rawValue
        params[PostParameterKeys.Create.subType] = self.subType.rawValue
        params[PostParameterKeys.Create.details] = self.postDescription
        params[PostParameterKeys.Create.groupKey] = self.groupPublisher?.groupKey
        params[PostParameterKeys.Create.placeKey] = self.postPlace?.placeKey
        if self.type == .checkinPost {
            params[PostParameterKeys.Create.checkin] = !(self.postPlace?.placeKey ?? "").isEmpty
        }
        else {
            params[PostParameterKeys.Create.checkin] = isCheckinPost ? !(self.postPlace?.placeKey ?? "").isEmpty : false
        }
        let locationParam = [
            PostParameterKeys.Create.longitude: userLocation.longitude,
            PostParameterKeys.Create.latitude: userLocation.latitude
        ]
        
        params[PostParameterKeys.Create.coordinates] = locationParam
        params[PostParameterKeys.Create.title] = eventTitle
        params[PostParameterKeys.Create.address] = eventAddress
        params[PostParameterKeys.Create.plannedTime] = eventStartTime
        params[PostParameterKeys.Create.plannedEndTime] = eventEndTime
        return params
    }
    
    func validateFields(completion: @escaping responseBlock) {
        if publisher == nil && groupPublisher == nil {
            completion(nil, ValidationErrors.emptyPostPublisher)
            return
        }
        switch self.type {
        case .textPost:
            if !postDescription.isValidField {
                completion(nil, ValidationErrors.emptyPostDescription)
                return
            }
            completion(true, nil)
        case .imagePost:
            if postImages.count == 0 {
                completion(nil, ValidationErrors.noImageSelected)
                return
            }
            completion(true, nil)
        case .audioPost:
            if postAudio == nil {
                completion(nil, ValidationErrors.noPostAudio)
                return
            }
            completion(true, nil)
        case .videoPost:
            if postVideo == nil || postVideo?.count == 0 {
                completion(nil, ValidationErrors.noPostVideo)
                return
            }
            completion(true, nil)
        case .checkinPost:
            if postPlace == nil || (postPlace?.placeKey ?? "").isEmpty {
                completion(nil, ValidationErrors.noPostCheckinPlace)
                return
            }
            completion(true, nil)
        case .eventPost:
            if eventTitle.isEmpty {
                completion(nil, ValidationErrors.emptyEventTitle)
                return
            }
            if eventAddress.isEmpty {
                completion(nil, ValidationErrors.emptyPlaceName)
                return
            }
            if eventDate.isEmpty || eventStartTime.isEmpty || eventEndTime.isEmpty {
                completion(nil, ValidationErrors.invalidOrEmptyEventDate)
                return
            }
            if postDescription.isEmpty {
                completion(nil, ValidationErrors.emptyEventDetails)
                return
            }
            completion(true, nil)
        default:
            completion(true, nil)
        }
    }
    
    func fetchRichTextDataIfAny(completion: @escaping responseBlock) {
        guard type != .eventPost else {
            completion(nil, nil)
            return
        }
        let text = postDescription
        let urls = text.fetchContainingUrls
        guard let firstUrl = urls.first else {
            completion(true, nil)
            return
        }
        let slp = SwiftLinkPreview(session: URLSession.shared,
                       workQueue: SwiftLinkPreview.defaultWorkQueue,
                       responseQueue: DispatchQueue.main,
                           cache: DisabledCache.instance)
        slp.preview(firstUrl) { success in
            completion(success, nil)
        } onError: { err in
            debugPrint("Error \(err.localizedDescription)")
            completion(nil, err)
        }
    }
    
    func tryCreatePost(completion: @escaping responseBlock) {
        if type == .checkinPost && !postDescription.isEmpty {
            type = .checkinPost
            subType = .textPost
        }
        if type == .checkinPost && postDescription.isEmpty {
            type = .checkinPost
            subType = .checkinPost
        }
        var createParam = toCreateParams
        self.validateFields { [weak self] valid, val_err in
            guard let self = self else { return}
            if let valError = val_err {
                completion(nil, valError)
            }
            else {
                self.fetchRichTextDataIfAny { [weak self] data, err in
                    guard let self = self else { return }
                    if let richData = data as? Response {
                        let richDataParam: [String: String] = [
                            PostParameterKeys.Create.RichLinkData.canonicalUrl: richData.canonicalUrl ?? "",
                            PostParameterKeys.Create.RichLinkData.description: richData.description ?? "",
                            PostParameterKeys.Create.RichLinkData.imageUrl: richData.image ?? "",
                            PostParameterKeys.Create.RichLinkData.originalUrl: richData.url?.absoluteString ?? "",
                            PostParameterKeys.Create.RichLinkData.title: richData.title ?? ""
                        ]
                        createParam[PostParameterKeys.Create.richLinkData] = richDataParam
                    }
                    if self.type == .imagePost {
                        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
                        let url = GetApiAddress.post(.fetchCreate, []).url
                        if let isCheckin = createParam[PostParameterKeys.Create.checkin] as? Bool, isCheckin == true {
                            OrbisSharedCreatePostManager.shared.createImagesPost(pendingPost: self.model.toOrbisFeedPost, parameters: createParam, url: url, headers: header, completion: completion)
                            return
                        }
                        else {
                            OrbisSharedCreatePostManager.shared.createImagesPost(pendingPost: self.model.toOrbisFeedPost, parameters: createParam, url: url, headers: header)
                            completion(true, nil)
                            return
                        }
                    }
                    else if self.type == .audioPost {
                        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
                        let url = GetApiAddress.post(.fetchCreate, []).url
                        if let isCheckin = createParam[PostParameterKeys.Create.checkin] as? Bool, isCheckin == true {
                            OrbisSharedCreatePostManager.shared.createAudioPost(audio: self.postAudio!, pendingPost: self.model.toOrbisFeedPost, parameters: createParam, url: url, headers: header, completion: completion)
                            return
                        }
                        else {
                            OrbisSharedCreatePostManager.shared.createAudioPost(audio: self.postAudio!,pendingPost: self.model.toOrbisFeedPost, parameters: createParam, url: url, headers: header)
                            completion(true, nil)
                            return
                        }
                        
                    }
                    else if self.type == .videoPost {
                        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
                        let url = GetApiAddress.post(.fetchCreate, []).url
                        if let isCheckin = createParam[PostParameterKeys.Create.checkin] as? Bool, isCheckin == true {
                            OrbisSharedCreatePostManager.shared.createVideoPost(videos: self.postVideo!, pendingPost: self.model.toOrbisFeedPost, parameters: createParam, url: url, headers: header, completion: completion)
                            return
                        }
                        else {
                            OrbisSharedCreatePostManager.shared.createVideoPost(videos: self.postVideo!,pendingPost: self.model.toOrbisFeedPost, parameters: createParam, url: url, headers: header)
                            completion(true, nil)
                            return
                        }
                        
                    }
                    else if self.type == .eventPost {
                        if self.postImagesData.count > 0 {
                            let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
                            let url = GetApiAddress.post(.fetchCreate, []).url
                            OrbisSharedCreatePostManager.shared.createEventPostWithImage(pendingPost: self.model.toOrbisFeedPost, parameters: createParam, url: url, headers: header, completion: completion)
                            return
                        }
                        else {
                            self.manager.createPost(paramters: createParam) {
                                data, error in
                                if let error = error {
                                    completion(nil, error)
                                    return
                                }
                                completion(data, nil)
                            }
                            return
                        }
                    }
                    else {
                        if let isCheckin = createParam[PostParameterKeys.Create.checkin] as? Bool, isCheckin == true {
                            self.manager.createPost(paramters: createParam) {
                                [weak self] data, error in
                                if let error = error {
                                    completion(nil, error)
                                    return
                                }
                                if let isCheckin = createParam[PostParameterKeys.Create.checkin] as? Bool, isCheckin, let pendingPost = self?.model.toOrbisFeedPost, let place = pendingPost.place, let placeKey = place.placeKey {
                                    CreatePlaceSharedManager.shared.addPlaceIdToNewlyBlockedObserver(placeKey: placeKey)
                                }
                                completion(data, nil)
                            }
                            return
                        }
                        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
                        let url = GetApiAddress.post(.fetchCreate, []).url
                        OrbisSharedCreatePostManager.shared.createNormalPost(pendingPost: self.model.toOrbisFeedPost, parameters: createParam, url: url, headers: header)
                        completion(true, nil)
                        return
                    }
                }
            }
        }
    }
    
    func loadRecommendedGroups(completion: @escaping responseBlock) {
        manager.fetchRecommendedGroupList(location: userLocation, limit: recommendedListLimit) { [weak self] data, err in
            if let groups = data as? Groups {
                self?.recommendedGroups = groups
                completion(true, nil)
            }
            else {
                completion(nil, err ?? ResponseError.invalidData)
            }
        }
    }
    
    func fetchGroupDetails(withKey key: String, completion: @escaping responseBlock) {
        groupDetailManager.syncGroupDetail(forGroup: key, completion: completion)
    }
}
