//
//  OrbisVideoCacheManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 31/05/2021.
//

import Foundation

class OrbisVideoCacheManager {
    static let shared = OrbisVideoCacheManager()
    
    private let maxURLCacheSize = 100
    private var urlCache: [String: String] = [:]
    
    func heapSize() -> Int {
        return malloc_size(Unmanaged.passRetained(OrbisAudioPlayerManager.shared).toOpaque())
    }
    
    func addUrl(forUrl path: String, url: String) {
        if urlCache.count > maxURLCacheSize - 1 {
            urlCache.removeValue(forKey: urlCache.first!.key)
        }
        urlCache[path] = url
    }
    
    func getUrl(forUrl url: String) -> String? {
        return urlCache[url]
    }
}
