//
//  PasswordSkyFloatingLabelTextField.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 06/04/2021.
//

import Foundation
import SkyFloatingLabelTextField

@IBDesignable
class PasswordSkyFloatingTextField: SkyFloatingLabelTextField {
    
    @IBInspectable var rightPadding: CGFloat = 0 {
        didSet {
            setRightPadding(rightPadding)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setRightPadding(rightPadding)
    }
    
    func setRightPadding(_ value: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: value.relativeToIphone8Width(), height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}
