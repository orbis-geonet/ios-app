//
//  PositionType.swift
//  Orbis-iOS
//
//  Created by Kamran on 29/10/2024.
//


enum PositionType: String {
    case topCenter = "TopCenter"
    case bottomCenter = "BottomCenter"
    case leftCenter = "LeftCenter"
    case rightCenter = "RightCenter"
    case topLeft = "TopLeft"
    case bottomRight = "BottomRight"
    
    func rawValue() -> String {
        return self.rawValue
    }
}
