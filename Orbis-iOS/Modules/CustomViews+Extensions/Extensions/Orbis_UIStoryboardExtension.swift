//
//  UIStoryboardExtension.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/03/2021.
//

import UIKit

extension UIStoryboard {
    static func getViewController(inStoryboard storyboard: String, identifier: String) -> UIViewController {
        return UIStoryboard(name: storyboard, bundle: nil).instantiateViewController(withIdentifier: identifier)
    }
}
