//
//  Firestore_Extension.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/07/2021.
//

import Foundation
import FirebaseFirestore

extension QueryDocumentSnapshot {
    func prepareForDecoding() -> [String: Any] {
        var data = self.data()
        data["id"] = self.documentID
        
        return data
    }
}
