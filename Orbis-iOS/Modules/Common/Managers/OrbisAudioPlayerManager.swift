//
//  OrbisAudioPlayerManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/05/2021.
//

import Foundation

class OrbisAudioPlayerManager {
    static let shared = OrbisAudioPlayerManager()
    
    private let maxURLCacheSize = 100
    private var urlCache: [String: String] = [:]
    
    func heapSize() -> Int {
        return malloc_size(Unmanaged.passRetained(OrbisAudioPlayerManager.shared).toOpaque())
    }
    
    func addUrl(forPost key: String, url: String) {
        if urlCache.count > maxURLCacheSize - 1 {
            urlCache.removeValue(forKey: urlCache.first!.key)
        }
        urlCache[key] = url
    }
    
    func getUrl(forPost key: String) -> String? {
        return urlCache[key]
    }
}
