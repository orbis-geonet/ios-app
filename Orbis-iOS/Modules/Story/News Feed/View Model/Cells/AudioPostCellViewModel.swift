//
//  AudioPostCellViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 29/03/2021.
//

import Foundation
import UIKit

class AudioPostCellViewModel: PostCellViewModel {
    var audioDuration: Double = 0
    var currentTime: Double = 0
    
    var isPlaying: Bool = false
    var isPlayerReady: Bool = false
    
    
    var description: String {
        return model.details ?? ""
    }
    
    var audioLength: String {
        return (audioDuration - currentTime).toDurationString()
    }
    
    var playPauseIcon: UIImage? {
        return (isPlaying == true) ? UIImage(named: "voice-pause-btn") : UIImage(named: "voice-play-btn")
    }
    
    var mediaUrl: String {
        return model.mediaUrls?.first ?? ""
    }
    
    func fetchMediaUrl(forName name: String, completion: @escaping responseBlock) {
        guard let postKey = self.model.postKey else {
            completion(nil, nil)
            return
        }
        if let url = OrbisAudioPlayerManager.shared.getUrl(forPost: postKey) {
            completion(url, nil)
            return
        }
        else {
            let ref = name.getFirebaseFileStorageReference(storage: .postAudio)
            ref.downloadURL {  url, err in
                if let audioUrl = url {
                    OrbisAudioPlayerManager.shared.addUrl(forPost: postKey, url: audioUrl.absoluteString)
                    completion(audioUrl.absoluteString, nil)
                    return
                }
                else {
                    completion(nil, err ?? ResponseError.invalidData)
                    return
                }
            }
        }
    }
}
