//
//  OrbisStory.swift
//
//  Created by Ranjith Kumar on 9/8/17
//  Copyright (c) DrawRect. All rights reserved.
//

import Foundation

public class OrbisStory: Codable {
    // Note: To retain lastPlayedSnapIndex value for each story making this type as class
    public var snapsCount: Int {
        return posts.count
    }
    var storyKey: String
    var group: Group
    var posts: OrbisFeedPosts
    var nextPage: String?
    
    private var storyLastPlayedSnapIndex: Int?
    
    var lastPlayedSnapIndex: Int {
        set {
            self.storyLastPlayedSnapIndex = newValue
        }
        get {
            return storyLastPlayedSnapIndex ?? posts.firstIndex(where: {$0.seen == false}) ?? 0
        }
    }
    var isCompletelyVisible = false
    var isCancelledAbruptly = false
    
    var hasSeenAll: Bool {
        let totalCount = posts.count
        let seenCount = posts.filter({$0.seen == true}).count
        return totalCount == seenCount
    }
    
    enum CodingKeys: String, CodingKey {
        case storyKey
        case group = "group"
        case posts = "posts"
        case nextPage
    }
}

extension OrbisStory: Equatable {
    public static func == (lhs: OrbisStory, rhs: OrbisStory) -> Bool {
        return lhs.group.groupKey == rhs.group.groupKey
    }
}
