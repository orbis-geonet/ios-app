//
//  CGFloatExtension.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/03/2021.
//

import Foundation
import UIKit

let minScalableValue: CGFloat = 8.0 // Min value that should undergo upper scaling for bigger iphones and iPads
extension CGFloat {
    
    static func getUpperScaleLimit() -> CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return 1.8
        default:
            return 1.5
        }
    }
    
    func relativeToIphone8Width(shouldUseLimit: Bool = true, deviceWidth: CGFloat = UIScreen.main.bounds.width) -> CGFloat {
        let upperScaleLimit: CGFloat = CGFloat.getUpperScaleLimit()
        var toUpdateValue = floor(self * (deviceWidth / 375))
        guard self > minScalableValue else {return toUpdateValue}
        guard shouldUseLimit else {return toUpdateValue}
        guard upperScaleLimit > 1 else {return toUpdateValue}
        let limitedValue = self * upperScaleLimit
        if toUpdateValue > limitedValue {
            toUpdateValue = limitedValue
        }
        return toUpdateValue
    }
    
    func relativeToIphone8Height(shouldUseLimit: Bool = true) -> CGFloat {
        var extraHeight: CGFloat = 0
        if #available(iOS 11.0, *) {
            extraHeight = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
            extraHeight = extraHeight + (UIApplication.shared.windows.first?.safeAreaInsets.top ?? 20) - 20
        }
        let upperScaleLimit: CGFloat = CGFloat.getUpperScaleLimit()
        var toUpdateValue = floor(self * ((UIScreen.main.bounds.height - extraHeight) / 667))
        guard self > minScalableValue else {return toUpdateValue}
        guard shouldUseLimit else {return toUpdateValue}
        guard upperScaleLimit > 1 else {return toUpdateValue}
        let limitedValue = self * upperScaleLimit
        if toUpdateValue > limitedValue {
            toUpdateValue = limitedValue
        }
        return toUpdateValue
    }
    
    var deg2rad: CGFloat {
        return self * .pi / 180
    }
}

extension Int {
    var toCGFloat: CGFloat {
        return CGFloat(self)
    }
}
