//
//  PlaceNearbyGroupsCellViewModel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 03/04/2021.
//

import Foundation
import UIKit

class PlaceNearbyGroupsCellViewModel {
    let groups: Groups!
    var cellWidths: [CGFloat] = []
    
    init(groups: Groups) {
        self.groups = groups.filter({$0.percentage != nil})
    }
    
    var count: Int {
        return groups.count
    }
    
    func getGroup(at index: Int) -> Group {
        return groups[index]
    }
    
    func getCellWidth(at index: Int, separation: CGFloat) -> CGFloat {
        if count <= 1 {
            return cellWidths[index]
        }
        if index == 0 {
            return cellWidths[index]
        }
        return cellWidths[index] + separation
    }
    
    func calculateAndStoreCellWidths(withFullWidth width: CGFloat) {
        cellWidths = []
        for i in 0..<count {
            let indexWidth = calculateCellWidth(forItemAt: i, fullWidth: width)
            cellWidths.append(indexWidth)
        }
    }
    
    private func calculateCellWidth(forItemAt index: Int, fullWidth: CGFloat) -> CGFloat {
        let groupPercentage = getGroup(at: index).percentage ?? 0
        return CGFloat(groupPercentage / 100.0) * fullWidth
    }
//    private func calculateCellWidth(forItemAt index: Int, fullWidth: CGFloat) -> CGFloat {
//        if count <= 1 {
//            return fullWidth
//        }
//        if count < 3 {
//            if index == 0 {
//                return 0.6 * fullWidth
//            }
//            else {
//                return 0.4 * fullWidth
//            }
//        }
//        if index == 0 {
//            return 0.51 * fullWidth
//        }
//        else {
//            let remainingWidth = 0.49 * fullWidth
//            let remainingCount = count - 1
//            let indexPosition = index - 1
//            var loopVal = remainingCount
//            var totalDivision = 0
//            while loopVal > 0 {
//                totalDivision += loopVal
//                loopVal -= 1
//            }
//            let minDivWidth = remainingWidth / totalDivision.toCGFloat
//            return minDivWidth * (remainingCount - indexPosition).toCGFloat
//        }
//    }
}
