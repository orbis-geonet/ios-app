//
//  SettingsLanguageListViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 12/04/2021.
//

import Foundation

class SettingsLanguageListViewModel {
    let supportedLanguages: [AppLanguage] = [.deviceLanguage,
                                             .english,
//                                             .chinese,
//                                             .ukranian,
//                                             .nepali,
//                                             .hindi,
//                                             .indonesian,
//                                             .japanese,
//                                             .korean,
//                                             .malay,
//                                             .russian,
//                                             .thai,
//                                             .urdu,
//                                             .vietnamise,
//                                             .arabic,
//                                             .swahili,
//                                             .italian,
//                                             .turkish,
//                                             .spanish,
//                                             .french,
//                                             .german,
                                             .portugues]
//                                             .polish]
    let selectedLanguage: String!
    
    init(selectedLanguage: String) {
        self.selectedLanguage = selectedLanguage
    }
    
    var count: Int {
        return supportedLanguages.count
    }
    
    func getLanguage(at index: Int) -> String {
        return supportedLanguages[index].languageText
    }
    
    func getLanguageCode(at index: Int) -> String {
        return supportedLanguages[index].rawValue
    }
}
