//
//  CreateGroupBody.swift
//  Orbis-iOS
//
//  Created by Kamran on 30/10/2024.
//

import Foundation

struct CreateGroupBody: Codable {
    var name: String = ""
    var location: Coordinates?
    var description: String = ""
    var imageName: String = ""
    var colorIndex: Int = -1
    var strokeColorHex: String = ""
    var os: String = "iOS"
}
