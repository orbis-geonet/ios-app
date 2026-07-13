//
//  OrbisStoryPreviewModel.swift
//  InstagramStories
//
//  Created by Boominadha Prakash on 18/03/18.
//  Copyright © 2018 DrawRect. All rights reserved.
//

import Foundation

class OrbisStoryPreviewModel: NSObject {
    
    //MARK:- iVars
    let stories: [OrbisStory]
    let handPickedStoryIndex: Int //starts with(i)
    
    //MARK:- Init method
    init(_ stories: [OrbisStory], _ handPickedStoryIndex: Int) {
        self.stories = stories
        self.handPickedStoryIndex = handPickedStoryIndex
    }
    
    //MARK:- Functions
    func numberOfItemsInSection(_ section: Int) -> Int {
            return stories.count
    }
    func cellForItemAtIndexPath(_ indexPath: IndexPath) -> OrbisStory? {
        if indexPath.item < stories.count {
            return stories[indexPath.item]
        }else {
            fatalError("Stories Index mis-matched :(")
        }
    }
}
