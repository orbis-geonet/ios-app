//
//  StoryItemViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 28/03/2021.
//

import Foundation
import UIKit

class StoryItemViewModel {
    var model: OrbisStory!
    
    init(user: OrbisStory) {
        model = user
    }
    
    var name: String {
        return model.group.name ?? ""
    }
    
    var propicLink: String {
        return model.group.imageName ?? ""
    }
    
    var borderDashWidth: CGFloat {
        return ceil((60.toCGFloat * 3) / unseenStoryCount.toCGFloat)
    }

    var borderDashGap: CGFloat {
        if unseenStoryCount > 1 {
            return 3
        }
        return 0.01
    }
    
    var groupBaseColor: UIColor {
        return model.group.groupBorderColor
    }
    
    var hasStory: Bool {
        return true
    }
    
    var unseenStoryCount: Int {
        let count = model.posts.filter({$0.seen == false}).count
        return count < 1 ? 1 : count
    }
}
