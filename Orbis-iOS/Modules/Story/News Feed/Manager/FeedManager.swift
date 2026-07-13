//
//  FeedManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/03/2021.
//

import Foundation
import UIKit

class FeedManager {
    static let shared = FeedManager()
    let names = ["John Lenon", "Maria Gomez", "Leonardo Di'Carpio", "Ronaldo Messi", "Stephenie McMan", "The Hulk", "Mr Ironman"]
    private let colors = [
        UIColor(named: AppColors.appBlue.rawValue)!,
        UIColor(named: AppColors.appPink.rawValue)!,
        UIColor(named: AppColors.appPurple.rawValue)!,
        UIColor(named: AppColors.appOrange.rawValue)!,
        UIColor(named: AppColors.appLightGreen.rawValue)!
    ]
    let imageLinks = [
        "https://images.unsplash.com/photo-1616994581908-d4f366e91dc9?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1616908841648-a4bc4322d64e?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1616198866341-8747984a0bc6?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1615478212173-0d77cfbb5dfe?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1616262938958-d449b0fe5966?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1616818400884-1c4f3d4d003c?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1616429437080-69822da5753a?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1617056462660-16df64bcb3e1?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1616963895284-e313c65f4a56?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1614871659452-ff6ec8041862?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1616894215885-829edc6d2b5b?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1617035037158-e28efd5ef473?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1615120017834-ed1e6e440661?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1615648260252-bd758220c0ce?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1615261754836-9472b23bdda4?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1615454789716-709410fe9877?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1615186004402-8a804fbc128b?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1614871395350-354bb11d90c8?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1616952391192-d8bc85de60d9?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1617171500714-19538f38dd5d?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1616258303979-fc3f038dd126?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1616740793793-c1e5958ba817?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1616273554445-00fda600feba?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1615814955367-95e34592750a?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1616249899793-4b6a9532aa9c?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1615972237926-656e3254f23c?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1616664515959-fe37461a3616?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1615085339695-d5aaf7941e50?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1617105160943-c35ab435c454?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max",
        "https://images.unsplash.com/photo-1615538363919-8e5724f16d20?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max"
    ]
    
    func getDummyFeedPost(excludeEvent: Bool = false) -> OrbisFeedPosts {
        let boolList = [true, false, false, true, false, true, true, true, false, false, false]
        let descriptionList = [
            "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor",
            "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolorLorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor",
            "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.",
            "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod.",
            ""
        ]
        let locations = ["Pedra da Praia", "Niagara Falls", "Rio De Janerio"]
        let images = imageLinks
        var postType = [OrbisPostType.audioPost, OrbisPostType.eventPost, OrbisPostType.imagePost, OrbisPostType.textPost]
        if excludeEvent {
            postType = [OrbisPostType.audioPost, OrbisPostType.imagePost, OrbisPostType.textPost]
        }
        let count = Int.random(in: 5...20)
        var i = 0
        var posts = OrbisFeedPosts()
        while i < count {
            let post = OrbisFeedPost(user: getRandomUser(), datePosted: "25/04/20 as 12:12", feedDescription: descriptionList.randomElement()!, imageLinks: images[randomPick: Int.random(in: 0...10)], likeCount: Int.random(in: 20...400), commentCount: Int.random(in: 20...400), hasLiked: boolList.randomElement()!, showOtherUsers: boolList.randomElement()!, type: postType.randomElement()!, location: locations.randomElement()!)
            posts.append(post)
            i += 1
        }
        return posts
    }
    
    func getRandomUser() -> OrbisUser {
        let userBaseColor: UIColor = colors.randomElement()!
        return OrbisUser(name: names.randomElement()!, proPicLink: "https://i.pravatar.cc/300", hasStory: Bool.random(), color: userBaseColor)
    }
    
    func getStoryUsers() -> [OrbisUser] {
        let count = Int.random(in: 5...20)
        var i = 0
        var users = [OrbisUser]()
        while i < count {
            let userBaseColor: UIColor = colors.randomElement()!
            var name = names.randomElement()!
            while users.contains(where: {$0.name == name}) {
                name += "1"
            }
            let user = OrbisUser(name: name, proPicLink: "https://i.pravatar.cc/300", hasStory: Bool.random(), color: userBaseColor)
            users.append(user)
            i += 1
        }
        return users
    }
    
//    func getRandomCheckinPost() -> OrbisFeedPost {
//        let postGroup = GroupManager.shared.getRandomGroupList().first!
//        let checkinUser = getRandomUser()
//        let place = OrbisPlace(coordinates: nil, name: "asd", placeKey: "dasd", type: "PARK", userCreatedKey: checkinUser.userKey, source: "Asd", address: "asd", description: "asd", categoryKey: "asd", cityKey: "asd", countryKey: "asd", phone: "asd", lastCheckInTimestamp: "ssdsd", lastSizeChangeTimestamp: "asdsd", dominantGroupKey: postGroup.groupKey, creationServerTimestamp: "asd", timestamp: "asdas", groupCreatedKey: postGroup.groupKey, dominantGroup: postGroup, competingGroups: [postGroup], googlePlaceId: "asd", size: 0, lastSize: 0)
//        var post = OrbisFeedPost(user: checkinUser, datePosted: "25/04/20 as 12:12", feedDescription: "", imageLinks: [], likeCount: Int.random(in: 20...400), commentCount: Int.random(in: 20...400), hasLiked: false, showOtherUsers: false, type: .checkinPost, location: "asd")
//        post.group = postGroup
//        post.user = checkinUser
//        post.place = place
//        return post
//    }
    
//    func getRandomCheckinPosts() -> OrbisFeedPosts {
////        let count = Int.random(in: 5...10)
//        let count = 10
//        var i = 0
//        var posts = OrbisFeedPosts()
//        while i < count {
//            posts.append(getRandomCheckinPost())
//            i += 1
//        }
//        return posts
//    }
    
    func getRandomUserPostPhoto(forUser userId: String) -> UserPostPhotos {
        let count = Int.random(in: 0...35)
        var i = 0
        var photos = UserPostPhotos()
        while i < count {
            let imagelink = imageLinks.randomElement()!
            photos.append(UserPostPhoto(userId: userId, photoUrl: imagelink))
            i += 1
        }
        return photos
    }
    
    func getDummyFeedEventPosts() -> OrbisFeedPosts {
        let boolList = [true, false, false, true, false, true, true, true, false, false, false]
        let descriptionList = [
            "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor",
            "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolorLorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor",
            "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.",
            "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod.",
            ""
        ]
        let locations = ["Pedra da Praia", "Niagara Falls", "Rio De Janerio"]
        let images = imageLinks
        let postType = OrbisPostType.eventPost
        let count = Int.random(in: 5...20)
        var i = 0
        var posts = OrbisFeedPosts()
        while i < count {
            let post = OrbisFeedPost(user: getRandomUser(), datePosted: "25/04/20 as 12:12", feedDescription: descriptionList.randomElement()!, imageLinks: images[randomPick: Int.random(in: 0...10)], likeCount: Int.random(in: 20...400), commentCount: Int.random(in: 20...400), hasLiked: boolList.randomElement()!, showOtherUsers: boolList.randomElement()!, type: postType, location: locations.randomElement()!)
            posts.append(post)
            i += 1
        }
        return posts
    }
}
