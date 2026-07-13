//
//  CustomSearchBar.swift
//  Orbis-iOS
//
//  Created by Umair Khan on 18/05/2024.
//

import Foundation
import UIKit

class CustomSearchBar: UISearchBar {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCustomAppearance()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCustomAppearance()
    }
    
    private func setupCustomAppearance() {
        // Remove background
        self.backgroundImage = UIImage()
        self.backgroundColor = .clear
        self.barTintColor = .clear
        self.isTranslucent = true
        self.searchTextField.clearButtonMode = .never
        // Customize text field
        if let textField = self.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = .clear
            textField.borderStyle = .none
            textField.rightView = nil
        }
        
        // Remove icons
        setImage(UIImage(), for: .search, state: .normal)
        setImage(UIImage(), for: .clear, state: .normal)
        
        // Remove borders
        for subview in self.subviews {
            for innerSubview in subview.subviews {
                if innerSubview.isKind(of: NSClassFromString("UISearchBarBackground")!) {
                    innerSubview.alpha = 0
                }
                if let containerViewClass = NSClassFromString("UISearchBarTextFieldBackgroundView") {
                                   if innerSubview.isKind(of: containerViewClass) {
                                       innerSubview.alpha = 0
                                   }
                               }
                if let textField = innerSubview as? UITextField {
                                     var bounds: CGRect
                                bounds = textField.frame
                                bounds.size.height = 35 //(set height whatever you want)
                                    textField.bounds = bounds
                    textField.borderStyle = UITextField.BorderStyle.roundedRect
                //                    textField.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
                    textField.backgroundColor = UIColor.red
                //                    textField.font = UIFont.systemFontOfSize(20)
                                }
            }
        }
    }
}
