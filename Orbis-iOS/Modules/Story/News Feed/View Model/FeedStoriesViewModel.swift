//
//  FeedStoriesViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 28/03/2021.
//

import Foundation

class FeedStoriesViewModel {
    var storyModel: [OrbisStory] = []
    
    init(model: [OrbisStory]) {
        storyModel = model
    }
    
    var storyCount: Int {
        return storyModel.count
    }
    
    func getModel(at index: Int) -> OrbisStory {
        return storyModel[index]
    }
}
