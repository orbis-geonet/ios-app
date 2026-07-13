//
//  TextPostCellViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 29/03/2021.
//

import Foundation

class TextPostCellViewModel: PostCellViewModel {
    
    var description: String {
        return model.details ?? ""
    }
    
}
