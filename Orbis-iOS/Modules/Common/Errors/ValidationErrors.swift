//
//  ValidationErrors.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 23/04/2021.
//

import Foundation

enum ValidationErrors: Error {
    case emptyFullName
    case emptyEmail
    case emptyPassword
    case emptyNewPassword
    case passwordsDoNotMatch
    case emptyDOB
    case emptyGender
    case invalidEmail
    case invalidPassword
    case oneOrMoreRequireFieldMissing
    case notAuthorized
    case emailNotFound
    case socialMediaLoginUsed
    case emptyGroupName
    case emptyGroupDescription
    case emptyGroupImage
    case emptyGroupBaseColor
    case emptyPostDescription
    case noImageSelected
    case noPostAudio
    case noPostVideo
    case noPostCheckinPlace
    case emptyPlaceName
    case emptyPlaceGroup
    case emptyPlaceType
    case emptyPlaceLocation
    case emptyPlaceAddress
    case emptyPlaceTelephone
    case emptyPlaceWebsite
    case invalidPlaceWebsite
    case emptyPostPublisher
    case emptyEventTitle
    case invalidOrEmptyEventDate
    case emptyEventDetails
    case appleSignInEmptyEmail
    case nothingChanged
    // Group Subscription
    case emptySubscriptionName
    case emptySubscriptionDescription
    case invalidSubscriptionPrice
    case emptyPaymentFrequency
    case invalidInstallmentPeriod
}

extension ValidationErrors: CustomStringConvertible {
    var description: String{
        switch self {
        case .emptyFullName:
            return "Full name is empty".localized
        case .emptyEmail:
            return "Email is empty".localized
        case .emptyPassword:
            return "Password is empty".localized
        case .emptyNewPassword:
            return "New Password is empty".localized
        case .passwordsDoNotMatch:
            return "Passwords do no match.".localized
        case .invalidEmail:
            return "Email address is not valid".localized
        case .invalidPassword:
            return "Password length must be greater than or equal to 8".localized
        case .oneOrMoreRequireFieldMissing:
            return "One or more required field is missing".localized
        case .notAuthorized:
            return "You are not authorized to perform this operation.".localized
        case .emailNotFound:
            return "No user found for given email".localized
        case .socialMediaLoginUsed:
            return "This email-id is associated with social media login".localized
        case .emptyGroupName:
            return "Group name is empty".localized
        case .emptyGroupBaseColor:
            return "Please chose group base color from available set of colors.".localized
        case .emptyGroupDescription:
            return "Group description is empty".localized
        case .emptyGroupImage:
            return "Group image is required".localized
        case .emptyPostDescription:
            return "Post description is empty".localized
        case .noImageSelected:
            return "Please select at least 1 image".localized
        case .emptyPlaceName:
            return "Place name is empty".localized
        case .emptyPlaceGroup:
            return "Please select group before proceeding.".localized
        case .emptyPlaceType:
            return "Please identify place type first.".localized
        case .emptyPlaceLocation:
            return "Please select place location.".localized
        case .emptyPlaceAddress:
            return "Empty address.".localized
        case .emptyPlaceTelephone:
            return "Empty telephone.".localized
        case .emptyPlaceWebsite:
            return "Empty website.".localized
        case .invalidPlaceWebsite:
            return "Invalid website.".localized
        case .noPostAudio:
            return "Please record audio before proceeding.".localized
        case .noPostVideo:
            return "Please select video before proceeding.".localized
        case .noPostCheckinPlace:
            return "Please select place to checkin".localized
        case .emptyPostPublisher:
            return "Please select publisher before proceeding.".localized
        case .emptyEventTitle:
            return "Please enter event title".localized
        case .emptyEventDetails:
            return "Please enter event details".localized
        case .invalidOrEmptyEventDate:
            return "Please re-check your scheduled date and time".localized
        case .emptyDOB:
            return "Date of Birth is required".localized
        case .emptyGender:
            return "Gender is empty".localized
        case .nothingChanged:
            return "Please edit data before saving".localized
        case .appleSignInEmptyEmail:
            return "Your account might have been deleted previously. Please revoke your Apple ID access to the app and retry again. If you still face the issue, please contact administration.".localized
        case .emptySubscriptionName:
            return "Please enter subscription name.".localized
        case .emptySubscriptionDescription:
            return "Please enter subscription description.".localized
        case .invalidSubscriptionPrice:
            return "Please enter valid price amount value.".localized
        case .emptyPaymentFrequency:
            return "Please select payment frequency.".localized
        case .invalidInstallmentPeriod:
            return String(format: "Installment period should be within the range of %@ - %@".localized, "\(AppValues.Subscription.installmentMinPeriod)", "\(AppValues.Subscription.installmentMaxPeriod)")
        }
    }
}
