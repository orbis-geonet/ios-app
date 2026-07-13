//
//  FeedEntity.swift
//  Orbis-iOS
//
//  Created by Kamran on 02/12/2024.
//

/*
import Foundation
import CoreData

@objc(FeedEntity)
public class FeedEntity: NSManagedObject {
    @NSManaged public var nextPage: String
    @NSManaged public var fromNearby: Bool
    @NSManaged public var city: String
    @NSManaged public var content: String
    // Uncomment and define the additional attributes as needed
    // @NSManaged public var dateAdded: Date
    // @NSManaged public var id: Int64
    // @NSManaged public var type: String?
    // @NSManaged public var post: FeedPost?
    // @NSManaged public var slider: [FeedPost]?
    // @NSManaged public var group: GroupDetails?
    // @NSManaged public var place: PlaceDetails?
    // @NSManaged public var placeUploadPhoto: URL?
    // @NSManaged public var showNoItem: Bool?
    // @NSManaged public var loaded: Bool?
    // @NSManaged public var stories: [StoryModel]?
    // @NSManaged public var comments: [CommentModel]?
    // @NSManaged public var noItemTitle: String?
}
 */

import RealmSwift

class FeedEntity: Object {
    @objc dynamic var nextPage: String = "" // Primary key
    @objc dynamic var fromNearby: Bool = true
    @objc dynamic var city: String = ""
    @objc dynamic var content: String = ""

    override static func primaryKey() -> String? {
        return "nextPage" // Define the primary key
    }
}

