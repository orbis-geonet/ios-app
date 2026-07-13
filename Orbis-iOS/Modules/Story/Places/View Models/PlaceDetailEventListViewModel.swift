//
//  PlaceDetailEventListViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 05/04/2021.
//

import Foundation

class PlaceDetailEventListViewModel {
    let model: OrbisPlace!
    let manager = FeedManager()
    var posts = OrbisFeedPosts()
    
    init(place: OrbisPlace) {
        self.model = place
        posts = manager.getDummyFeedEventPosts()
    }
    
    var count: Int {
        return posts.count + 1 // +1 for header cell
    }
    
    func getPostModel(at index: Int) -> OrbisFeedPost {
        return posts[index]
    }
    
}
