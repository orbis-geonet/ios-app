//
//  OrbisVoiceModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/05/2021.
//

import Foundation

typealias OrbisVoice = (duration: TimeInterval?, data: Data, title: String)

enum OrbisVoiceRecorderState {
    case normal
    case recording
}

class OrbisVoiceManager {
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        return dateFormatter
    }()
}
