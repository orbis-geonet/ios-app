//
//  CheckInStatus.swift
//  Orbis-iOS
//
//  Created by Kamran on 02/11/2024.
//


import Foundation

struct CheckInStatus: Codable {
    let status: String
    
    init(status: String = "NEW") {
        self.status = status
    }
}
