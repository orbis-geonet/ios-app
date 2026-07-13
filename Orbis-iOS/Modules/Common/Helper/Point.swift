//
//  Point.swift
//  Orbis-iOS
//
//  Created by Kamran on 29/10/2024.
//


import Foundation

class Point: CustomStringConvertible {
    var x: Double
    var y: Double
    var polarAngle: Double = 0.0
    var anchorDistance: Double = 0.0

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    // Conform to CustomStringConvertible to customize description output
    var description: String {
        return "\(x) \(y)"
    }
}
