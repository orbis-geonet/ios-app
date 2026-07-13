//
//  GenericError.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 23/04/2021.
//

import Foundation

protocol GenericErrorProtocol: Error {
    
    var title: String? { get }
    var code: Int { get }
}

struct GenericError: GenericErrorProtocol {
    
    var title: String?
    var code: Int
    var errorDescription: String? { return _description }
    var failureReason: String? { return _description }
    
    private var _description: String
    
    init(title: String?, description: String, code: Int) {
        self.title = title ?? AppStrings.error
        self._description = description
        self.code = code
    }
}
