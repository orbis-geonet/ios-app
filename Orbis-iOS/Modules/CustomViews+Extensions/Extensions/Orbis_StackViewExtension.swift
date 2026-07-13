//
//  StackViewExtension.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/03/2021.
//

import Foundation
import UIKit

extension UIStackView {
    
    open override func awakeFromNib() {
        if self.axis == .horizontal {
            self.spacing = self.spacing.relativeToIphone8Width()
        } else {
            self.spacing = self.spacing.relativeToIphone8Height()
        }
        self.layoutIfNeeded()
    }
    
}
