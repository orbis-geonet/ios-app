//
//  CreateEventViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 18/04/2021.
//

import Foundation
import UIKit
import CoreLocation

class CreateEventModel {
    var publisher: OrbisUser?
    var groupPublisher: Group?
    var type: OrbisPostType?
    var address: String?
    var description: String?
    var image: UIImage?
    var eventTitle: String?
    var postedDate: String?
    var postedTime: String?
}
