//
//  DropDownOptionListViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 18/08/2023.
//

import Foundation

typealias DropDownOptionList = [DropDownOptionItem]

struct DropDownOptionItem {
    var id: String?
    var displayName: String?
    
}

class DropDownOptionListViewModel {
    var options = DropDownOptionList()
    
    init(options: DropDownOptionList) {
        self.options = options
    }
    
    var sectionCount: Int {
        return 1
    }
    
    func count(inSection section: Int) -> Int {
        if section == 0 {
            return options.count
        }
        return 0
    }
    
    func getOption(at index: Int) -> DropDownOptionItem {
        return options[index]
    }
}
