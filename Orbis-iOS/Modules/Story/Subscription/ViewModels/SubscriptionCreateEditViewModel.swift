//
//  SubscriptionCreateEditViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 06/01/2023.
//

import Foundation
import UIKit
import FirebaseStorage
import FirebaseDatabase

class SubscriptionCreateEditViewModel {
    var model: GroupSubscriptionModel!
    let stripeManager = AdminStripeManager()
    let subscriptionManager = AdminSubscriptionManager()
    let manager = CreateGroupManager()
    let originalModel: GroupSubscriptionModel!
    
    var feeCommission: SubscriptionCommisionInfo = SubscriptionCommisionInfo()
    
    var isEditMode = false
    var groupKey: String!
    
    var availablePaymentFrequencies: DropDownOptionList = []
    
    var installmentPeriod: Int? {
        get {
            return model.period
        }
        set {
            model.period = newValue
        }
    }
    
    var installmentPeriodText: String {
        if let period = self.installmentPeriod {
            return String(period)
        }
        return ""
    }
    
    init(groupKey: String) {
        self.groupKey = groupKey
        model = GroupSubscriptionModel(key: "")
        self.originalModel = GroupSubscriptionModel.copyFrom(model: model)
        self.currency = AppValues.StripeAccountCreationDefaults.defaultCurrency
        self.originalModel.currency = AppValues.StripeAccountCreationDefaults.defaultCurrency
        generateAvailablePaymentFrequncies()
    }
    
    init(groupKey: String, model: GroupSubscriptionModel) {
        self.groupKey = groupKey
        isEditMode = true
        self.model = model
        self.originalModel = GroupSubscriptionModel.copyFrom(model: self.model)
        generateAvailablePaymentFrequncies()
    }
    
    private func generateAvailablePaymentFrequncies() {
        let options = GroupSubscriptionPaymentFrequency.allCases.sorted(by: { $0.displayIndex < $1.displayIndex })
        var list = DropDownOptionList()
        options.forEach { freq in
            list.append(DropDownOptionItem(id: freq.rawValue, displayName: freq.displayText))
        }
        self.availablePaymentFrequencies = list
    }
    
    func updatePaymentFrequency(option: DropDownOptionItem) -> Bool {
        guard let id = option.id, let paymentFreq = GroupSubscriptionPaymentFrequency(rawValue: id) else {
            return false
        }
        if paymentFreq.subscriptionType != .interval {
            self.installmentPeriod = nil
        }
        model.type = paymentFreq.subscriptionType.rawValue
        model.interval = paymentFreq.paymentInterval?.rawValue ?? ""
        return true
    }
    
    var hasEditChanged: Bool {
        return (originalModel.name != model.name) || (originalModel.description != model.description) || (originalModel.price != model.price) || (originalModel.currency != model.currency) || (originalModel.benefit != model.benefit) || (originalModel.type != model.type) || (originalModel.interval != model.interval)
    }
    
    var currentPaymentFrequency: GroupSubscriptionPaymentFrequency? {
        guard let type = model.type else { return nil }
        guard let subscriptionType = GroupSubscriptionType(rawValue: type) else { return nil }
        
        switch subscriptionType {
        case .unlimited:
            guard let interval = model.interval, let subsInterval = GroupSubscriptionPaymentInterval(rawValue: interval) else { return nil }
            switch subsInterval {
            case .monthly:
                return .monthly
            case .yearly:
                return .yearly
            }
        case .interval:
            return .installment
        case .oneTime:
            return .single
        }
    }
    
    var selectedPaymentFrequencyText: String {
        if let currentPaymentFrequency = self.currentPaymentFrequency {
            return currentPaymentFrequency.displayText
        }
        return AppStrings.Subscription.CreateEditText.paymentFrequencyPlaceholder
    }
    
    var selectedPaymentFrequencyTextColor: UIColor {
        if let _ = self.currentPaymentFrequency {
            return UIColor(named: AppColors.appBlack.rawValue) ?? .black
        }
        return UIColor(named: AppColors.appWarmGray2.rawValue) ?? .placeholderText
    }
    
    var viewTitle: String {
        if isEditMode {
            return AppStrings.Subscription.CreateEditText.editTitle
        }
        return AppStrings.Subscription.CreateEditText.createTitle
    }
    
    var name: String {
        get {
            return model.name ?? ""
        }
        set {
            model.name = newValue
        }
    }
    
    var description: String {
        get {
            return model.description ?? ""
        }
        set {
            model.description = newValue
        }
    }
    
    var originalPrice: Double {
        get {
            return model.originalPrice ?? 0.0
        }
        set {
            model.originalPrice = newValue
        }
    }
    
    var commisionFee: Double {
        get {
            let userPrice = originalPrice
            let stripeAdditionalFee = feeCommission.stripeAdditionFee ?? 0.0
            let stripeCommission = feeCommission.stripeCommission ?? 0.0
            let orbisCommission = feeCommission.orbisCommission ?? 0.0
            let priceWithOrbisCommission = (userPrice + orbisCommission * userPrice)
            let total = priceWithOrbisCommission + (priceWithOrbisCommission * stripeCommission) + stripeAdditionalFee
            return (total - originalPrice).rounded(toPlaces: 2)
        }
    }
    
    var totalPrice: Double {
        get {
            return (originalPrice + commisionFee).rounded(toPlaces: 2)
        }
    }
    
    var currencyIdentifier: String {
        return self.currency.toCurrencySymbol
    }
    
    var priceWithTaxString: String {
        return String(format: AppStrings.Subscription.CreateEditText.priceWithTaxString, "\(currencyIdentifier) \(commisionFee)", "\(currencyIdentifier) \(totalPrice)")
    }
    
    var currency: String {
        get {
            return model.currency ?? AppValues.StripeAccountCreationDefaults.defaultCurrency.uppercased()
        }
        set {
            model.currency = newValue.uppercased()
        }
    }
    
    var attachmentImagesCount: Int {
        return subscriptionImages.count
    }
    private var toRemoveAttachmentKeys: [String] = []
    var attachmentLocalImages: [UIImage] = []
    var ypMediaItems: [YPMediaItem] = []
    
    private var subscriptionImages: [SubscriptionImage] {
        var images = [SubscriptionImage]()
        attachmentLocalImages.forEach { img in
            images.append(SubscriptionImage(image: img))
        }
        let savedImageKeys = model.imagesName ?? []
        savedImageKeys.forEach { imgKey in
            images.append(SubscriptionImage(imageKey: imgKey))
        }
        return images
    }
    
    func getSubscriptionImage(at index: Int) -> SubscriptionImage {
        return subscriptionImages[index]
    }
    
    func removeSubscriptionImage(at index: Int) -> Bool {
        let img = subscriptionImages[index]
        if let image = img.image {
            attachmentLocalImages.removeAll(where: { image == $0 })
            ypMediaItems.remove(at: index)
            return true
        } else if let imgKey = img.imageKey {
            toRemoveAttachmentKeys.append(imgKey)
            model.imagesName?.removeAll(where: { $0 == imgKey })
            return true
        }
        return false
    }
    
    var benefit: [String] {
        return model.benefit ?? []
    }
    
    func removeBenefit(at index: Int) {
        model.benefit?.remove(at: index)
    }
    
    func updateBenefit(at index: Int, with text: String) {
        model.benefit?[index] = text
    }
    
    func addBenefit() {
        if model.benefit == nil {
            model.benefit = []
        }
        model.benefit?.append("")
    }
    
    var toCreateParams: [String: Any] {
        var params = [String: Any]()
        params[GroupSubscriptionApiParamKeys.Create.name] = self.name
        params[GroupSubscriptionApiParamKeys.Create.description] = self.description
        params[GroupSubscriptionApiParamKeys.Create.price] = self.totalPrice
        params[GroupSubscriptionApiParamKeys.Create.originalPrice] = self.originalPrice
        params[GroupSubscriptionApiParamKeys.Create.currency] = self.currency
        params[GroupSubscriptionApiParamKeys.Create.benefit] = self.benefit.filter({!$0.isEmpty})
        params[GroupSubscriptionApiParamKeys.Create.type] = self.currentPaymentFrequency?.subscriptionType.rawValue ?? ""
        if let interval = self.currentPaymentFrequency?.paymentInterval {
            params[GroupSubscriptionApiParamKeys.Create.interval] = interval.rawValue
        }
        
        params[GroupSubscriptionApiParamKeys.Create.period] = self.installmentPeriod
        params[GroupSubscriptionApiParamKeys.Create.photos] = self.model.imagesName ?? []
        
        return params
    }
    
    var toEditParams: [String: Any] {
        var params = [String: Any]()
        params[GroupSubscriptionApiParamKeys.Create.subscriptionKey] = self.model.subscriptionKey ?? ""
        params[GroupSubscriptionApiParamKeys.Create.name] = self.name
        params[GroupSubscriptionApiParamKeys.Create.description] = self.description
        params[GroupSubscriptionApiParamKeys.Create.price] = self.totalPrice
        params[GroupSubscriptionApiParamKeys.Create.originalPrice] = self.originalPrice
        params[GroupSubscriptionApiParamKeys.Create.currency] = self.currency
        params[GroupSubscriptionApiParamKeys.Create.benefit] = self.benefit.filter({!$0.isEmpty})
        params[GroupSubscriptionApiParamKeys.Create.type] = self.currentPaymentFrequency?.subscriptionType.rawValue ?? ""
        if let interval = self.currentPaymentFrequency?.paymentInterval {
            params[GroupSubscriptionApiParamKeys.Create.interval] = interval.rawValue
        }
        params[GroupSubscriptionApiParamKeys.Create.period] = self.installmentPeriod
        params[GroupSubscriptionApiParamKeys.Create.photos] = self.model.imagesName ?? []
        return params
    }
    
    func validateFields(completion: @escaping responseBlock) {
        if !name.isValidField {
            completion(nil, ValidationErrors.emptySubscriptionName)
            return
        }
        if !description.isValidField {
            completion(nil, ValidationErrors.emptySubscriptionDescription)
            return
        }
        if originalPrice <= 0 {
            completion(nil, ValidationErrors.invalidSubscriptionPrice)
            return
        }
        if currentPaymentFrequency == nil {
            completion(nil, ValidationErrors.emptyPaymentFrequency)
            return
        } else if currentPaymentFrequency == .installment  {
            if (installmentPeriod ?? 0) < AppValues.Subscription.installmentMinPeriod {
                completion(nil, ValidationErrors.invalidInstallmentPeriod)
                return
            } else if (installmentPeriod ?? 0) > AppValues.Subscription.installmentMaxPeriod {
                completion(nil, ValidationErrors.invalidInstallmentPeriod)
                return
            }
        }
        completion(true, nil)
    }
    
    func fetchCommissionInfo(completion: @escaping responseBlock) {
        self.subscriptionManager.getSubscriptionCommissionInfo { [weak self] result, error in
            if let info = result as? SubscriptionCommisionInfo {
                self?.feeCommission = info
            }
            completion(result, error)
        }
    }
    
    func getStripeAccountStatus(completion: @escaping responseBlock) {
        self.stripeManager.getStripeAccountStatus { result, error in
            if let error = error {
                debugPrint("Error in stripe status: \(error.asAFError?.responseCode ?? -112) \(error)")
            }
            completion(result, error)
        }
    }
    
    func createStripeAccount(completion: @escaping responseBlock) {
        self.stripeManager.createStripeAccount(completion: completion)
    }
    
    func updateStripeAccount(completion: @escaping responseBlock) {
        self.stripeManager.updateStripeAccount(completion: completion)
    }
    
    func deleteStripeAccount(completion: @escaping responseBlock) {
        self.stripeManager.deleteStripeAccount(completion: { [weak self] result, error in
            self?.createStripeAccount(completion: completion)
        })
    }
    
    func checkValidationAndProceedStripe(completion: @escaping responseBlock) {
        validateFields { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                completion(nil, error)
            } else {
                self.getStripeAccountStatus(completion: completion)
            }
        }
    }
    
    private func handleAttachmentUpdates(completion: @escaping responseBlock) {
        var uploadedImageNames: [String] = []
        let group = DispatchGroup()
        let imageUploadTaskLabel = "SubscriptionImageUploadTask"
        var hasErrorOccured = false
        if attachmentLocalImages.count > 0 {
            var uploadTasks = [StorageUploadTask]()
            var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
            backgroundTaskId = UIApplication.shared.beginBackgroundTask {
                [weak self ] in
                self?.endBackgroundTask(withId: backgroundTaskId)
            }
            for img in attachmentLocalImages {
                group.enter()
                let task = uploadImage(imageData: img.UIImageToDataJPEG2(compressionRatio: 1)!) { [weak self] data, err in
                    if let _ = err {
                        self?.cancelAllUploadTasks(in: uploadTasks)
                        self?.deleteAllUploadedImages(inList: uploadedImageNames)
                        uploadedImageNames = []
                        hasErrorOccured = true
                    }
                    else {
                        uploadedImageNames.append(data as! String)
                    }
                    group.leave()
                }
                uploadTasks.append(task)
            }
        }
        group.notify(queue: DispatchQueue(label: imageUploadTaskLabel, qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .inherit)) { [weak self] in
            guard let self = self else { return }
            if hasErrorOccured {
                completion(nil, CommonError.uploadFailed)
                return
            }
            if (self.toRemoveAttachmentKeys.count > 0) && !hasErrorOccured {
                self.toRemoveAttachmentKeys.forEach { imageKey in
                    self.deleteImage(key: imageKey, directory: .subscriptionImages)
                }
            }
            var updatedImagesKeys = self.model.imagesName ?? []
            let toRemoveKeys = self.toRemoveAttachmentKeys
            toRemoveKeys.forEach { key in
                updatedImagesKeys.removeAll(where: { $0 == key })
            }
            uploadedImageNames.forEach { imgKey in
                if !updatedImagesKeys.contains(imgKey) {
                    updatedImagesKeys.append(imgKey)
                }
            }
            self.model.imagesName = updatedImagesKeys
            completion(true, nil)
        }
    }
    
    func proceedSubscriptionCreation(completion: @escaping responseBlock) {
        handleAttachmentUpdates { [weak self] _, err in
            guard let self = self else { return }
            if let error = err {
                completion(nil, error)
                return
            }
            if self.isEditMode {
                self.subscriptionManager.editGroupSubscription(groupKey: groupKey, param: toEditParams, completion: completion)
            } else {
                self.subscriptionManager.createGroupSubscription(groupKey: groupKey, param: toCreateParams, completion: completion)
            }
        }
        
    }
}

extension SubscriptionCreateEditViewModel {
    
    private func endBackgroundTask(withId id: UIBackgroundTaskIdentifier) {
        if id == .invalid { return }
        UIApplication.shared.endBackgroundTask(id)
    }
    
    private func cancelAllUploadTasks(in list: [StorageUploadTask]) {
        for task in list {
            task.cancel()
        }
    }
    
    private func deleteAllUploadedImages(inList list: [String]) {
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.subscriptionImages.rawValue)
        for imageName in list {
            let fileRef = storageRef.child(imageName)
            fileRef.delete { err in
                debugPrint("Error in deleting subscription image \(err?.localizedDescription ?? "")")
            }
        }
    }
    
    private func deleteImage(key: String, directory: ProjectStorageDirectories, completion: responseBlock? = nil) {
        let storageRef = Storage.storage().reference().child(directory.rawValue)
        storageRef.child(key).delete { _ in
            key.getFirebaseReference(storage: directory, imageSizeResolution: .twoHundred).delete { _ in
                key.getFirebaseReference(storage: directory, imageSizeResolution: .fourHundred).delete { _ in
                    key.getFirebaseReference(storage: directory, imageSizeResolution: .sixEighty).delete { _ in
                        completion?(true, nil)
                    }
                }
            }
        }
    }
    
    private func uploadImage(imageData: Data, completion: @escaping responseBlock) -> StorageUploadTask {
        let storageRef = Storage.storage().reference().child(ProjectStorageDirectories.subscriptionImages.rawValue)
        var imageName = UUID().uuidString
        imageName = imageName + imageData.fileExtension
        let fileRef = storageRef.child(imageName)
        // Create file metadata including the content type
        let metadata = StorageMetadata()
        metadata.contentType = imageData.mimeType
        let uploadTask = fileRef.putData(imageData, metadata: metadata) { metadata, err in
            if let error = err {
                completion(nil, error)
                return
            }
            guard let _ = metadata else {
                completion(nil, ResponseError.invalidData)
                return
            }
            let imageThumbRef = Database.database().reference().child(FirebaseRTDBNode.subscriptionImages.rawValue).child(String(imageName.split(separator: ".").first!))
            self.observeThumbnailGeneration(forRef: imageThumbRef, imageName: imageName, completion: completion)
        }
        return uploadTask
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
}
