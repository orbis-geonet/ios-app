//
//  OrbisStories.swift
//  InstagramStories
//
//  Created by Ranjith Kumar on 9/8/17.
//  Copyright © 2017 DrawRect. All rights reserved.
//

import Foundation

typealias OrbisStories = [OrbisStory]

extension OrbisStories {
    func removeCachedFile(for urlString: String) {
        IGVideoCacheManager.shared.getFile(for: urlString) { (result) in
            switch result {
            case .success(let url):
                IGVideoCacheManager.shared.clearCache(for: url.absoluteString)
            case .failure(let error):
                debugPrint("File read error: \(error)")
            }
        }
    }
    static func removeAllVideoFilesFromCache() {
        IGVideoCacheManager.shared.clearCache()
    }
}
