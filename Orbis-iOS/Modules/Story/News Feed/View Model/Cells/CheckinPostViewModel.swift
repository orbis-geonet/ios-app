//
//  CheckinPostViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 29/03/2021.
//

import Foundation

class CheckingPostViewModel: PostCellViewModel {
    var posts: OrbisFeedPosts = []
    var currentPageIndex: Int = 0 {
        didSet {
            onPageIndexChanged?(currentPageIndex)
        }
    }
    
    init(checkinPosts: OrbisFeedPosts, pageIndex: Int) {
        super.init(data: checkinPosts.first!)
        self.posts = checkinPosts
        self.currentPageIndex = pageIndex
    }
    
    var onPageIndexChanged: ((Int) -> Void)?
    
    var count: Int {
        return posts.count
    }
    
    func getCheckinPost(at index: Int) -> OrbisFeedPost {
        return posts[index]
    }
}
