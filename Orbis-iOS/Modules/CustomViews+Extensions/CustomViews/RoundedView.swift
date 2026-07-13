//
//  RoundedView.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/03/2021.
//

import Foundation
import UIKit

@IBDesignable
class RoundedView: UIView {
    private var dashedBorderLayer: CAShapeLayer?
    
    @IBInspectable var shouldConverBorderToDashed: Bool = false {
        didSet {
            updateBorders()
        }
    }
    
    @IBInspectable var borderDashWidth: CGFloat = 0 {
        didSet {
            updateBorders()
        }
    }
    @IBInspectable var borderDashGap: CGFloat = 0 {
        didSet {
            updateBorders()
        }
    }
    @IBInspectable var borderWidth: CGFloat = 0.0 {
        didSet {
            updateBorders()
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }
    
    @IBInspectable var isCircular: Bool = false {
        didSet {
            if isCircular {
                cornerRadius = self.frame.width / 2
            }
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            self.layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var displayShadow: Bool = false {
        didSet {
            if displayShadow == true {
                addShadow()
            }
        }
    }
    
    @IBInspectable var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }
    
    @IBInspectable var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }
    
    @IBInspectable var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable var shadowColor: UIColor? {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.shadowColor = color.cgColor
                layer.shadowPath = UIBezierPath(roundedRect: layer.bounds, cornerRadius: layer.cornerRadius).cgPath
            } else {
                layer.shadowColor = nil
            }
        }
    }
    
    private func addShadow() {
        let layer = self.layer
        layer.masksToBounds = true
        layer.shadowOffset = shadowOffset
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius = shadowRadius
        if let shadowClr = shadowColor {
            layer.masksToBounds = false
            layer.shadowColor = shadowClr.cgColor
        }
        layer.shadowPath = UIBezierPath(roundedRect: layer.bounds, cornerRadius: layer.cornerRadius).cgPath
        
        let bColor = self.backgroundColor?.cgColor
        self.backgroundColor = nil
        layer.backgroundColor =  bColor
        if isCircular {
            self.cornerRadius = self.frame.width / 2
        }
        else {
            self.layer.cornerRadius = cornerRadius.relativeToIphone8Width()
        }
    }
    
    override func awakeFromNib() {
        if isCircular {
            self.cornerRadius = self.frame.width / 2
        }
        else {
            self.layer.cornerRadius = cornerRadius.relativeToIphone8Width()
        }
        if displayShadow {
            addShadow()
        }
        updateBorders()
    }
    
    override func layoutSubviews() {
        if isCircular {
            self.cornerRadius = self.frame.width / 2
        }
        if displayShadow {
            addShadow()
        }
        updateBorders()
    }
    
    private func updateBorders() {
        if shouldConverBorderToDashed {
            layer.borderWidth = 0
            addLineDashedStroke()
        }
        else {
            dashedBorderLayer?.removeFromSuperlayer()
            layer.borderWidth = borderWidth
            if borderWidth > 2 {
                self.layer.borderWidth = borderWidth.relativeToIphone8Width()
            }
        }
    }
    
    func addLineDashedStroke() {
        guard borderDashGap > 0 else {
            dashedBorderLayer?.removeFromSuperlayer()
            return
        }
        dashedBorderLayer?.removeFromSuperlayer()
        dashedBorderLayer = CAShapeLayer()
        dashedBorderLayer?.strokeColor = self.borderColor?.cgColor ?? UIColor.clear.cgColor
        let pattern: [NSNumber] = [NSNumber(value: Float(borderDashWidth)), NSNumber(value: Float(borderDashGap))]
        dashedBorderLayer?.lineDashPattern = pattern
        dashedBorderLayer?.lineWidth = borderWidth.relativeToIphone8Width()
        dashedBorderLayer?.frame = bounds
        dashedBorderLayer?.fillColor = nil
        dashedBorderLayer?.path = UIBezierPath(roundedRect: bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).cgPath
        let position = layer.sublayers?.count ?? 0
        layer.insertSublayer(dashedBorderLayer!, at: UInt32(position))
    }
}
