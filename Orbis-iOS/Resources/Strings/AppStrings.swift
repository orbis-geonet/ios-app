//
//  AppStrings.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 23/04/2021.
//

import Foundation

struct AppStrings {
    static var appName: String {
        return "Orbis"
    }
    static var error: String {
        return "Error".localized
    }
    struct AppPermission {
        struct Location {
            static var title: String {
                return "Enable Location Service".localized
            }
            static var message: String {
                return "Please turn on location service from device settings.".localized
            }
        }
    }
    
   
    struct Authentication {
        static var email: String {
            return "E-mail".localized
        }
        static var password: String {
            return "Password".localized
        }
        static var forgotPassword: String {
            return "Forgot Password?".localized
        }
        static var login: String {
            return "Login".localized
        }
        static var fullName: String {
            return "Full Name".localized
        }
        static var name: String {
            return "Name".localized
        }
        static var dobPlaceholder: String {
            return "Date of Birth".localized
        }
        static var gender: String {
            return "Gender".localized
        }
        static var register: String {
            return "Register".localized
        }
        static var accountCreatedSuccessful: String {
            return "Your account has been created successfully".localized
        }
        static var selectGender: String {
            return "Select Gender".localized
        }
        static var authOptionPickerHeading: String {
            return "Just taking a peek ?".localized
        }
        static var authOptionPickerMessage: String {
            return "To get the most out of ORBIS, sign up and take part ... it's fast and free".localized
        }
        static var registerLowerCase: String {
            return "register".localized
        }
        static var fastAndFree: String {
            return "fast and free".localized
        }
        static var authOptionPickerSignup: String {
            return "I want to sign up".localized
        }
        static var authOptionPickerLogin: String {
            return "I already have an account".localized
        }
        static var authMainLoginWith: String {
            return "Login with".localized
        }
        static var forgotPasswordTitle: String {
            return "Forgot your password ?".localized
        }
        static var forgotPasswordMessage: String {
            return "Don't worry, we sent an e-mail to your registered email address so you can reset your password".localized
        }
        static var send: String {
            return "Send".localized
        }
        static var forgotPasswordSuccessTitle: String {
            return "Your reset password link was successfully sent !".localized
        }
        static var forgotPasswordSuccessMessage: String {
            return "You will receive an email to reset your password. Just click on the link and follow the steps !".localized
        }
        static var registrationTOSMessagePretext: String {
            return "by clicking register you accept ".localized
        }
    }
    
    struct Onboarding {
        static var onboardingTitle: String {
            return "Welcome to Orbis!".localized
        }
        static var onboardingMessage: String {
            return "A geolocation social network created to map the social groups in your region. With Orbis, you can check where those groups are in real time and get to know them.".localized
        }
        static var start: String {
            return "Start".localized
        }
    }
    struct Feed {
        struct Tabs {
            static var myFeed: String {
                return "My Feed".localized
            }
            static var nearby: String {
                return "Nearby".localized
            }
        }
        static var unfollowGroupStories: String {
            return "Unfollow group stories".localized
        }
    }
    struct Group {
        struct MoreActionTexts {
            static var leave: String {
                return "Leave".localized
            }
            static var follow: String {
                return "Follow".localized
            }
            static var unfollow: String {
                return "Unfollow".localized
            }
            static var report: String {
                return "Report".localized
            }
            static var delete: String {
                return "Delete".localized
            }
            static var activateSubscription: String {
                return "Activate Offer".localized
            }
            static var deactivateSubscription: String {
                return "Deactivate Offer".localized
            }
            static var share: String {
                return "Share".localized
            }
            static var unhideStories: String {
                return "Unhide stories".localized
            }
        }
        struct Create {
            static var chooseColor: String {
                return "Choose a group color".localized
            }
            static var groupNamePlaceholder: String {
                return "Type your group name".localized
            }
            static var groupDescriptionPlaceholder: String {
                return "Tell us more about your group..".localized
            }
            static var createGroup: String {
                return "Create Group".localized
            }
            static var createGroupAlertMessage: String {
                return "It's prohibited to create groups of commercial establishments".localized
            }
        }
        struct GroupMemberAction {
            static var make: String {
                return "Make".localized
            }
            static var admin: String {
                return "admin".localized
            }
            static var remove: String {
                return "Remove".localized
            }
            static var fromAdmin: String {
                return "from admin".localized
            }
            static var ban: String {
                return "Ban".localized
            }
            static var unban: String {
                return "Unban".localized
            }
        }
        static var places: String {
            return "Places".localized
        }
        static var members: String {
            return "Members".localized
        }
        static var status: String {
            return "Status".localized
        }
        static var groups: String {
            return "Groups".localized
        }
        static var searchGroupPlaceholder: String {
            return "Type here to search groups".localized
        }
        static var groupNameSearchPlaceholder: String {
            return "Search the name of the group here".localized
        }
        static var ownedPlaces: String {
            return "Owned Places".localized
        }
        static var group: String {
            return "Group".localized
        }
        static var removePlaceFromGroup: String {
            return "Remove from group".localized
        }
    }
    struct Profile {
        struct Tabs {
            static var photos: String {
                return "Photos".localized
            }
            static var posts: String {
                return "Posts".localized
            }
        }
        static var blockConfirmationTitle: String {
            return "Block".localized
        }
        static var blockConfirmationMessage: String {
            return "Are you sure you want to block this user?".localized
        }
        static var blockedUserTitle: String {
            return "Blocked User".localized
        }
        static var blockedUserMessage: String {
            return "Something went wrong trying to fetch user information.".localized
        }
        static var usersTitle: String {
            return "Users".localized
        }
        static var searchUsersPlaceholder: String {
            return "Search users".localized
        }
        static var followers: String {
            return "Followers".localized
        }
        static var following: String {
            return "Following".localized
        }
        static var follow: String {
            return "Follow".localized
        }
        static var unfollow: String {
            return "Unfollow".localized
        }
        static var requested: String {
            return "Requested".localized
        }
        static var connectInstagram: String {
            return "Connect with Instagram".localized
        }
        static var instagramConnected: String {
            return "Connected with instagram".localized
        }
        static var emptyPhotosMessage: String {
            return "Connect with Instagram or add photos straight to Orbis".localized
        }
        static var otherProfileEmptyPhotoMessage: String {
            return "There are no publications".localized
        }
        static var privateAccountTitle: String {
            return "This Account is Private".localized
        }
        static var privateAccountMessage: String {
            return "Follow this account to see their photos and posts".localized
        }
        static var removeUploadedPhotoTitle: String {
            return "Remove Photo".localized
        }
    }
    struct Places {
        static var getDirection: String {
            return "Get Direction".localized
        }
        static var placeSearchPlaceholder: String {
            return "Enter the name of the place here...".localized
        }
        static var placeNamePlaceholder: String {
            return "Type here the name of the place..".localized
        }
        static var exactAddressPlaceholder: String {
            return "Type the exact address (Optional)".localized
        }
        static var groupsInPlace: String {
            return "Groups in this place".localized
        }
        static var placeAddressLabel: String {
            return "Address".localized
        }
        static var placeTelephoneLabel: String {
            return "Telephone".localized
        }
        static var placeScheduleLabel: String {
            return "Schedule".localized
        }
        static var placeWebsiteLabel: String {
            return "Website".localized
        }
        static var openInGoogleMaps: String {
            return "Open in Maps".localized
        }
        static var callTitle: String {
            return "Call".localized
        }
        static var gotoWebsite: String {
            return "Go to website".localized
        }
        static var updateScheduleTitle: String {
            return "Update Opening Hours".localized
        }
        
        static var placeAddressPlaceholder: String {
            return "Type here the address of the place.."
        }
        static var placeTelephonePlaceholder: String {
            return "Enter contact detail for the place.."
        }
        static var placeWebsitePlaceholder: String {
            return "Type here the website link of the place.."
        }
        static var selectOpenTimeTitle: String {
            return "Select Open Time"
        }
        static var selectCloseTimeTitle: String {
            return "Select Close Time"
        }
        static var createPlaceTitle: String {
            return "Create Place".localized
        }
        static var createPlaceBtnText: String {
            return "Create place".localized
        }
        static var emptyPlaceDescription: String {
            return "This place does not have a description. To include one please press and hold here.".localized
        }
        static var chooseGroup: String {
            return "Choose a group".localized
        }
        static var editPlaceDescription: String {
            return "Edit Place Description".localized
        }
        static var reviewTitle: String {
            return "Review".localized
        }
        static var ratingMessage: String {
            return "How many stars would you like to give this place?".localized
        }
    }
    struct Events {
        static var events: String {
            return "Events".localized
        }
        struct Create {
            static var title: String {
                return "Event".localized
            }
            static var yourEvent: String {
                return "Your Event".localized
            }
            static var eventTitlePlaceholder: String {
                return "Event title".localized
            }
            static var eventAddressPlaceholder: String {
                return "Address, street, number, neighborhood, city".localized
            }
            static var eventDatePlaceholder: String {
                return "Date".localized
            }
            static var eventTimeStartPlaceholder: String {
                return "Start".localized
            }
            static var eventTimeEndPlaceholder: String {
                return "End".localized
            }
            static var eventDescriptionPlaceholder: String {
                return "Event description".localized
            }
            static
            var publishBtnText: String {
                return "Publish event".localized
            }
            static var selectStartTime: String {
                return "Select Start Time".localized
            }
            static var selectEndTime: String {
                return "Select End Time".localized
            }
            
        }
        static var going: String {
            return "I'm going!".localized
        }
        static var willGo: String {
            return "I'll go".localized
        }
        static var attend: String {
            return "Attend".localized
        }
        static var confirmed: String {
            return "Confirmed".localized
        }
        static var from: String {
            return "From".localized
        }
        static var to: String {
            return "to".localized
        }
    }
    struct Checkin {
        static var checkin: String {
            return "Check-in".localized
        }
        static var checkinTitle: String {
            return "Check-in".localized
        }
        static var checkinSearchPlaceholder: String {
            return "Search places nearby".localized
        }
    }
    struct Post {
        static var publishAsIndicator: String {
            return "Would like to publish as:".localized
        }
        static var postDescriptionPlaceholder: String {
            return "Type here about the place, group or whatever you want...".localized
        }
        static var photoType: String {
            return "Photo".localized
        }
        static var checkinType: String {
            return "Check-in".localized
        }
        static var videoType: String {
            return "Video".localized
        }
        static var post: String {
            return "Post".localized
        }
        static var yourPost: String {
            return "Your Post".localized
        }
        static var chooseGroupOrUser: String {
            return "Choose a group or user".localized
        }
        static var chooseGroup: String {
            return "Choose a group".localized
        }
        static var recording: String {
            return "Recording...".localized
        }
        static var recordingStopped: String {
            return "Recording stopped.".localized
        }
        struct Actions {
            static var reportPost: String {
                return "Report post".localized
            }
            static var report: String {
                return "Report".localized
            }
            static var reportPostPlaceholder: String {
                return "Help us understand what's happening with this post. How would you describe it?".localized
            }
            
            static var reportGroup: String {
                return "Report group".localized
            }
            static var reportGroupPlaceholder: String {
                return "Help us understand what's wrong with this group. How would you describe it?".localized
            }
            
            static var reportProfile: String {
                return "Report profile".localized
            }
            static var reportProfilePlaceholder: String {
                return "Help us understand what's wrong with this profile. How would you describe it?".localized
            }
            
            static var reportPlace: String {
                return "Report place".localized
            }
            static var reportPlacePlaceholder: String {
                return "Help us understand what's wrong with this place. How would you describe it?".localized
            }
        }
        struct Comments {
            static var commentTitle: String {
                return "Comments".localized
            }
            static var commentPlaceholder: String {
                return "Write your comment.".localized
            }
        }
    }
    struct Messaging {
        static var messagesTitle: String {
            return "Messages".localized
        }
        static var you: String {
            return "You".localized
        }
        static var sentImage: String {
            return "sent an image".localized
        }
        static var sendVideo: String {
            return "sent a video".localized
        }
        static var activeNow: String {
            return "Active now".localized
        }
        static var online: String {
            return "Online".localized
        }
        static var justNow: String {
            return "Just now".localized
        }
        static var messagePlaceholder: String {
            return "Type here.".localized
        }
        struct TimeFormat {
            static var yearsAgo: String {
                return "years ago".localized
            }
            static var yearAgo: String {
                return "year ago".localized
            }
            static var monthsAgo: String {
                return "months ago".localized
            }
            static var monthAgo: String {
                return "month ago".localized
            }
            static var weeksAgo: String {
                return "weeks ago".localized
            }
            static var weekAgo: String {
                return "week ago".localized
            }
            static var daysAgo: String {
                return "days ago".localized
            }
            static var dayAgo: String {
                return "day ago".localized
            }
            static var hoursAgo: String {
                return "hours ago".localized
            }
            static var hourAgo: String {
                return "hour ago".localized
            }
            static var minutesAgo: String {
                return "minutes ago".localized
            }
            static var minuteAgo: String {
                return "minute ago".localized
            }
            static var secondsAgo: String {
                return "seconds ago".localized
            }
        }
    }
    struct Notification {
        struct Tabs {
            static var news: String {
                return "News".localized
            }
            static var pending: String {
                return "Pending".localized
            }
        }
        static var title: String {
            return "Notification".localized
        }
        static var acceptAction: String {
            return "Accept".localized
        }
        static var hasRequestedToFollow: String {
            return "has requested to follow".localized
        }
    }
    struct Settings {
        struct Tabs {
            static var profile: String {
                return "Profile".localized
            }
            static var social: String {
                return "Social".localized
            }
            static var preferences: String {
                return "Preferences".localized
            }
        }
        
        static var title: String {
            return "Settings".localized
        }
        static var comment: String {
            return "Comment".localized
        }
        static var rateApp: String {
            return "Rate app".localized
        }
        static var inviteFriends: String {
            return "Invite friends".localized
        }
        static var tos: String {
            return "Terms of service".localized
        }
        static var privacyPolicy: String {
            return "Privacy policy".localized
        }
        static var deleteAccount: String {
            return "Delete my Account".localized
        }
        static var logout: String {
            return "Logout".localized
        }
        
        static var manageMyGroup: String {
            return "Manage my groups (admin)".localized
        }
        static var placesYouFollow: String {
            return "Places you follow".localized
        }
        static var mySubscriptions: String {
            return "My purchases".localized
        }
        static var accountPrivacy: String {
            return "Your account privacy".localized
        }
        static var makeAccountPrivate: String {
            return "Make my account private".localized
        }
        static var blockedList: String {
            return "Blocked list".localized
        }
        static var language: String {
            return "Language".localized
        }
        static var pushNotification: String {
            return "Push notification".localized
        }
        static var on: String {
            return "ON".localized
        }
        static var off: String {
            return "OFF".localized
        }
        static var languageSearchPlaceholder: String {
            return "Enter the language name".localized
        }
    }
    struct Language {
        static var deviceLanguage: String {
            return "Device language".localized
        }
        static var english: String {
            return "English".localized
        }
        static var chinese: String {
            return "Chinese".localized
        }
        static var ukranian: String {
            return "Ukranian".localized
        }
        static var nepali: String {
            return "Nepali".localized
        }
        static var hindi: String {
            return "Hindi".localized
        }
        static var indonesian: String {
            return "Indonesian".localized
        }
        static var japanese: String {
            return "Japanese".localized
        }
        static var korean: String {
            return "Korean".localized
        }
        static var malay: String {
            return "Malay".localized
        }
        static var russian: String {
            return "Russian".localized
        }
        static var thai: String {
            return "Thai".localized
        }
        static var urdu: String {
            return "Urdu".localized
        }
        static var vietnamise: String {
            return "Vietnamise".localized
        }
        static var arabic: String {
            return "Arabic".localized
        }
        static var swahili: String {
            return "Swahili".localized
        }
        static var italian: String {
            return "Italian".localized
        }
        static var turkish: String {
            return "Turkish".localized
        }
        static var spanish: String {
            return "Spanish".localized
        }
        static var french: String {
            return "French".localized
        }
        static var german: String {
            return "German".localized
        }
        static var portugues: String {
            return "Portuguese".localized
        }
        static var polish: String {
            return "Polish".localized
        }
    }
    struct ConfirmationPopup {
        static var confirmDelete: String {
            return "Confirm delete?".localized
        }
        static var deletePostConfirmationMessage: String {
            return "Are you sure you want to delete this post? Once deleted, it cannot be undone.".localized
        }
        
        static var confirmDeleteGroup: String {
            return "Confirm delete group?".localized
        }
        static var deleteGroupConfirmationMessage: String {
            return "Are you sure you want to delete this group? Once deleted, it cannot be undone.".localized
        }
        
        static var newAdminRequired: String {
            return "New Admin Required".localized
        }
        static var newAdminConfirmationMessage: String {
            return "Do you want to assign a new admin from members list before leaving this group?".localized
        }
        
        static var confirmLeaveGroup: String {
            return "Confirm leave group?".localized
        }
        static var leaveGroupConfirmationMessage: String {
            return "Are you sure, you want to leave this group?".localized
        }
        
        static var confirmAssign: String {
            return "Confirm assign".localized
        }
        static var assignMemberAdminPrefix: String {
            return "Are you sure you want to assign".localized
        }
        static var assignMemberAdminPostfix: String {
            return "as new admin of the group?".localized
        }
        
        static var accountDeletion: String {
            return "Account deletion".localized
        }
        static var deleteAccountConfirmMessage: String {
            return "Are you sure you want to delete your account? Once deleted, it cannot be recovered.".localized
        }
    }
    struct SuccessMessages {
        static var postReported: String {
            return "Post has been reported successfully".localized
        }
        static var groupReported: String {
            return "Group has been reported successfully".localized
        }
        static var profileReported: String {
            return "Profile has been reported successfully".localized
        }
        static var placeReported: String {
            return "Place has been reported successfully".localized
        }
        static var hasBeenDeleted: String {
            return "has been deleted.".localized
        }
        static var passwordChanged: String {
            return "Password has been changed.".localized
        }
    }
    static var thisUser: String {
        return "this user".localized
    }
    static var feed: String {
        return "Feed".localized
    }
    static var cancel: String {
        return "Cancel".localized
    }
    static var ok: String {
        return "Ok".localized
    }
    static var uploadPhoto: String {
        return "Upload photo".localized
    }
    static var changePhoto: String {
        return "Change Photo".localized
    }
    static var saveChanges: String {
        return "Save changes".localized
    }
    static var changePassword: String {
        return "Change Password".localized
    }
    static var user: String {
        return "user".localized
    }
    static var selectOption: String {
        return "Select option".localized
    }
    static var selectDOB: String {
        return "Select Date of Birth".localized
    }
    static var selectDate: String {
        return "Select Date".localized
    }
    static var search: String {
        return "Search".localized
    }
    static var results: String {
        return "Results".localized
    }
    static var understood: String {
        return "Understood".localized
    }
    static var viewMore: String {
        return "View more".localized
    }
    static var viewLess: String {
        return "View less".localized
    }
    static var save: String {
        return "Save".localized
    }
    static var update: String {
        return "Update".localized
    }
    static var textCopied: String {
        return "Text Copied!".localized
    }
    static var close: String {
        return "Close".localized
    }
    static var enterYourText: String {
        return "Enter your text".localized
    }
    static var yes: String {
        return "Yes".localized
    }
    static var no: String {
        return "No".localized
    }
    static var warning: String {
        return "Warning".localized
    }
    static var orbisUser: String {
        return "Orbis User"
    }
    static var orbisDeletedUser: String {
        return "Orbis User"
    }
    static var userHasBeenDeleted: String {
        return "User deleted".localized
    }

    struct Subscription {
        
        struct ListActionText {
            static var subscribeText: String {
                return "Purchase".localized
            }
            static var edit: String {
                return "Edit".localized
            }
            static var subscriptionsTitle: String {
                return "Offers".localized
            }
            static var checkAttachmentText: String {
                return "Check photos".localized
            }
        }
        
        struct CreateEditText {
            struct PlaceholderTexts {
                static var subscriptionNamePlaceholder: String {
                    return "Type the name of your offer".localized
                }
                static var subscriptionDescriptionPlaceholder: String {
                    return "Tell us more about your offer".localized
                }
                static var subscriptionBenefitPlaceholder: String {
                    return "Type benefit here".localized
                }
                static var subscriptionPricePlaceholder: String {
                    return "Price".localized
                }
            }
            static var createTitle: String {
                return "Create Offer".localized
            }
            static var editTitle: String {
                return "Edit Offer".localized
            }
            static var benefitsTitle: String {
                return "Benefits of the offer".localized
            }
            static var addMoreBenefit: String {
                return "More benefits".localized
            }
            static var priceWithTaxString: String {
                return "Fees: %@ | Total: %@".localized
            }
            static var paymentFrequencyPlaceholder: String {
                return "Choose the payment frequency".localized
            }
            static var photosTitle: String {
                return "Photos".localized
            }
            static var paymentFrequencyTitle: String {
                return "Payment frequency".localized
            }
        }
        
        struct GroupDetailsButtonsText {
            static var createSubscription: String {
                return "Create Offer".localized
            }
            static var editSubscription: String {
                return "Edit Offer".localized
            }
            static var subscriptionActivity: String {
                return "Activity".localized
            }
            static var subscription: String {
                return "Members Club".localized
            }
            static var updateSubscription: String {
                return "Update offer".localized
            }
        }
        
        static var purchasedCodesText: String {
            return "Purchased Codes".localized
        }
        
        static var seeCodesText: String {
            return "See codes".localized
        }
        
        static var codeText: String {
            return "Code".localized
        }
        
        static var durationMonthlyText: String {
            return "mon".localized
        }
        
        static var durationYearlyText: String {
            return "yr".localized
        }
        
        static var paymentInstallmentExtraInfo: String {
            return "in %@x, total: %@".localized
        }
        
        static var selectCurrency: String {
            return "Select Currency".localized
        }

        static var deleteBenefitConfirmationMessage: String {
            return "Are you sure you want to delete this benefit?".localized
        }

        static var deleteSubscriptionConfirmationMessage: String {
            return "Are you sure you want to delete this offer?".localized
        }
        
        static var activateSubscriptionConfirmationMessage: String {
            return "Are you sure you want to activate all offers?".localized
        }
        static var deactivateSubscriptionConfirmationMessage: String {
            return "Are you sure you want to deactivate all offers?".localized
        }
        
        static var unsubscribeConfirmationMessage: String {
            return "Are you sure you want to cancel this purchase?".localized
        }
        
        static var subscriptionSuccessMessage: String {
            return "Your purchase has been confirmed!".localized
        }
        
        static var quantityText: String {
            return "Quantity".localized
        }

        struct Activity {
            static var title: String {
                return "Activity".localized
            }

            struct Tabs {
                static var management: String {
                    return "Management".localized
                }
                static var clients: String {
                    return "Clients".localized
                }
            }
            static var totalSubscriptionTitle: String {
                return "Total Offers".localized
            }
            static var totalRevenueTitle: String {
                return "Total Revenue".localized
            }
            static var subscriptionsTitle: String {
                return "Clients".localized
            }
            static var revenueTitle: String {
                return "Revenue".localized
            }
        }
        struct IllustrativePopup {
            static var groupAdminCreateSubscriptionPopupMsg: String {
                return "Now you can create offers with social incentive for your group and monetize in the \"create offer button\".".localized
            }
            static var userSubscriptionFeaturePopupMsg: String {
                return "Now you can buy offers from the groups and receive gifts, benefits and discounts!".localized
            }
        }
    }
}

struct AppErrorStrings {
    
    static var invalidRating: String {
        return "Invalid rating!".localized
    }
    static var fixHighlightedError: String {
        return "Please fix highlighted error(s)".localized
    }
    static var couldNotCompleteReq: String {
        return "Couldn't complete your request.".localized
    }
    static var googleSigninFailed: String {
        return "Google Sign-in failed.".localized
    }
    static var cannotLoginAtMoment: String {
        return "Cannot login at the moment!".localized
    }
    static var emailPasswordInvalid: String {
        return "Email or password is invalid".localized
    }
    
    static var feedEmpty: String {
        return "Feed is empty.".localized
    }
    static var newsFeedEmpty: String {
        return "News feed is empty.".localized
    }
    static var groupFeedEmpty: String {
        return "No post has been uploaded to this group yet.".localized
    }
    static var userFeedEmpty: String {
        return "User feed is empty.".localized
    }
    static var placeFeedEmpty: String {
        return "No post has been uploaded to this place yet.".localized
    }
    
    static var couldNotLoadVideo: String {
        return "Could not load video".localized
    }
    static var cannotPlayAudio: String {
        return "Cannot play audio".localized
    }
    
    static var userBannedFromPosting: String {
        return "You have been banned from posting.".localized
    }
    
    static var invalidLinkProvided: String {
        return "Invalid link provided".localized
    }
    
    static var invalidPostType: String {
        return "Invalid post type".localized
    }
    
    static var selectDateFirst: String {
        return "Please select date of event first.".localized
    }
    static var selectStartTimeFirst: String {
        return "Please select start time of event first.".localized
    }
    
    static var emailAppNotAvailable: String {
        return "Email app not available.".localized
    }
}
