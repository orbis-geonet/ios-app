//
//  CoordinatesUtil.swift
//  Orbis-iOS
//
//  Created by Kamran on 29/10/2024.
//


import Foundation
import CoreLocation
import UIKit
import GoogleMaps

class CoordinatesUtil {
    static let epsilon = 10.0
    static let earthRadius = 6378.137
    static let chaikinPartitions = 4
    static let polygonLogoPadding = 0.75

    static func bspline(poly: inout [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        if poly.first?.latitude != poly.last?.latitude || poly.first?.longitude != poly.last?.longitude {
            poly.append(poly.first!)
        } else {
            poly.removeLast()
        }
        poly.insert(poly.last!, at: 0)
        poly.append(poly[1])
        
        let lats = poly.map { $0.latitude }
        let lons = poly.map { $0.longitude }
        
        var points = [CLLocationCoordinate2D]()
        
        for i in 2..<lats.count - 2 {
            var t: Double = 0
            while t < 1 {
                let ax = (-lats[i - 2] + 3 * lats[i - 1] - 3 * lats[i] + lats[i + 1]) / 6
                let ay = (-lons[i - 2] + 3 * lons[i - 1] - 3 * lons[i] + lons[i + 1]) / 6
                let bx = (lats[i - 2] - 2 * lats[i - 1] + lats[i]) / 2
                let by = (lons[i - 2] - 2 * lons[i - 1] + lons[i]) / 2
                let cx = (-lats[i - 2] + lats[i]) / 2
                let cy = (-lons[i - 2] + lons[i]) / 2
                let dx = (lats[i - 2] + 4 * lats[i - 1] + lats[i]) / 6
                let dy = (lons[i - 2] + 4 * lons[i - 1] + lons[i]) / 6
                let lat = ax * pow(t + 0.1, 3) + bx * pow(t + 0.1, 2) + cx * (t + 0.1) + dx
                let lon = ay * pow(t + 0.1, 3) + by * pow(t + 0.1, 2) + cy * (t + 0.1) + dy
                points.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
                t += 0.2
            }
        }
        return points
    }
 /*
    static func bspline(poly: inout [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        if poly.first?.latitude != poly.last?.latitude || poly.first?.longitude != poly.last?.longitude {
            poly.append(poly.first!)
        } else {
            poly.removeLast()
        }
        poly.insert(poly.last!, at: 0)
        poly.append(poly[1])
        
        let lats = poly.map { $0.latitude }
        let lons = poly.map { $0.longitude }
        var points = [CLLocationCoordinate2D]()
        
        for i in 2..<lats.count - 2 {
            var t: Double = 0
            while t < 1 {
                let ax = (-lats[i - 2] + 3 * lats[i - 1] - 3 * lats[i] + lats[i + 1]) / 6
                let ay = (-lons[i - 2] + 3 * lons[i - 1] - 3 * lons[i] + lons[i + 1]) / 6
                let bx = (lats[i - 2] - 2 * lats[i - 1] + lats[i]) / 2
                let by = (lons[i - 2] - 2 * lons[i - 1] + lons[i]) / 2
                let cx = (-lats[i - 2] + lats[i]) / 2
                let cy = (-lons[i - 2] + lons[i]) / 2
                let dx = (lats[i - 2] + 4 * lats[i - 1] + lats[i]) / 6
                let dy = (lons[i - 2] + 4 * lons[i - 1] + lons[i]) / 6
                
                let lat = ax * pow(t + 0.1, 3) + bx * pow(t + 0.1, 2) + cx * (t + 0.1) + dx
                let lon = ay * pow(t + 0.1, 3) + by * pow(t + 0.1, 2) + cy * (t + 0.1) + dy
                
                // Round coordinates for consistency
                let roundedLat = round(lat * 1_000_000) / 1_000_000
                let roundedLon = round(lon * 1_000_000) / 1_000_000
                points.append(CLLocationCoordinate2D(latitude: roundedLat, longitude: roundedLon))
                
                t += 0.2
            }
        }
        
        return points
    }
  */


    static func chaikin(arr: [CLLocationCoordinate2D], num: Int) -> [CLLocationCoordinate2D] {
        guard num > 0 else { return arr }
        
        var reduced = [CLLocationCoordinate2D]()
        for i in stride(from: 0, to: arr.count, by: chaikinPartitions) {
            reduced.append(arr[i])
        }
        
        let smooth = reduced.enumerated().flatMap { (index, coord) -> [CLLocationCoordinate2D] in
            let next = reduced[(index + 1) % reduced.count]
            return [
                CLLocationCoordinate2D(latitude: 0.75 * coord.latitude + 0.25 * next.latitude,
                                       longitude: 0.75 * coord.longitude + 0.25 * next.longitude),
                CLLocationCoordinate2D(latitude: 0.25 * coord.latitude + 0.75 * next.latitude,
                                       longitude: 0.25 * coord.longitude + 0.75 * next.longitude)
            ]
        }
        
        return num == 1 ? smooth : chaikin(arr: smooth, num: num - 1)
    }

    static func minimumEnclosingCircle(polygonPoints: [CLLocationCoordinate2D]) -> (center: CLLocationCoordinate2D, radius: Double) {
        let centroid = calculateCentroid(points: polygonPoints)
        let maxDistance = polygonPoints.map { GMSGeometryDistance(centroid, $0) }.max() ?? 0.0
        return (centroid, maxDistance)
    }
    
    static func calculateCentroid(points: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        guard !points.isEmpty else {
            return CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0) // Return default if no points
        }

        // Initialize GMSCoordinateBounds with the first coordinate
        var bounds = GMSCoordinateBounds(coordinate: points[0], coordinate: points[0])
        
        // Expand bounds to include each point
        for point in points {
            bounds = bounds.includingCoordinate(point)
        }
        
        // Calculate the center by averaging the northeast and southwest corners of the bounds
        let northeast = bounds.northEast
        let southwest = bounds.southWest
        let centerLat = (northeast.latitude + southwest.latitude) / 2
        let centerLng = (northeast.longitude + southwest.longitude) / 2
        
        return CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)
    }

    static func calculateDistanceToFarthestPoint(centroid: CLLocationCoordinate2D, points: [CLLocationCoordinate2D]) -> Double {
            var maxDistance = 0.0
            
            for point in points {
                let distance = GMSGeometryDistance(centroid, point)
                maxDistance = max(maxDistance, distance)
            }
            
            return maxDistance
        }



    static func calculateShortestDistance(polygonPoints: [CLLocationCoordinate2D], center: CLLocationCoordinate2D) -> Double {
        var minDistance = Double.greatestFiniteMagnitude
        
        for i in stride(from: 0, to: polygonPoints.count, by: 10) {
            let start = polygonPoints[i]
            let end = polygonPoints[(i + 1) % polygonPoints.count]
            let distance = GMSGeometryDistance(center, getClosestPointOnSegment(start: start, end: end, point: center))
            minDistance = min(minDistance, distance)
        }
        
        return minDistance * polygonLogoPadding
    }

    static func getClosestPointOnSegment(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, point: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let latDiff = end.latitude - start.latitude
        let lonDiff = end.longitude - start.longitude
        
        if latDiff == 0.0 && lonDiff == 0.0 {
            return start
        }
        
        let t = ((point.latitude - start.latitude) * latDiff + (point.longitude - start.longitude) * lonDiff) / (latDiff * latDiff + lonDiff * lonDiff)
        
        if t < 0 { return start }
        if t > 1 { return end }
        
        return CLLocationCoordinate2D(latitude: start.latitude + t * latDiff, longitude: start.longitude + t * lonDiff)
    }
    
    static func isCircle(points: [CLLocationCoordinate2D], center: CLLocationCoordinate2D) -> Bool {
            guard !points.isEmpty else { return false }

            let radius = GMSGeometryDistance(center, points[0])
            
            for point in points {
                let distance = GMSGeometryDistance(center, point)
                if abs(distance - radius) > epsilon {
                    return false
                }
            }

            return true
        }

    
    /**
     * Calculates the radius of a circle using two points on opposite sides of a polygon.
     *
     * - Parameter polygonPoints: Array of `CLLocationCoordinate2D` representing the polygon points.
     * - Returns: The radius of the circle in kilometers.
     */
    static func calculateCircleRadius(polygonPoints: [CLLocationCoordinate2D]) -> Double {
        guard polygonPoints.count > 1 else { return 0.0 }
        
        let start = polygonPoints[0]
        let halfIndex = polygonPoints.count / 2
        let end = polygonPoints[halfIndex]
        
        // Use Google Maps Utility to compute the spherical distance
        return GMSGeometryDistance(start, end) / 2.0 // Result is in meters, divide by 2 for radius
    }
    
    /**
     * Helper function to compute the distance between two `CLLocationCoordinate2D` points.
     */
    
    static func getCircleOuterPoints(center: Coordinates, radius: Double, numPoints: Int = 100) -> [Coordinates] {
        var points = [Coordinates]()
        let angleStep = 360.0 / Double(numPoints)
        let centerLocation = CLLocationCoordinate2D(latitude: center.latitude!, longitude: center.longitude!)
        
        for i in 0..<numPoints {
            let angle = angleStep * Double(i)
            if let point = computeOffset(from: centerLocation, distance: radius, angle: angle) {
                points.append(Coordinates(latitude: point.latitude, longitude: point.longitude))
            }
        }
        
        return points
    }
    
    static func computeOffset(from: CLLocationCoordinate2D, distance: Double, angle: Double) -> CLLocationCoordinate2D? {
            let earthRadius = 6371.0 // Earth radius in kilometers
            let distanceRatio = distance / earthRadius
            let bearing = angle * .pi / 180

            let lat1 = from.latitude * .pi / 180
            let lon1 = from.longitude * .pi / 180

            let lat2 = asin(sin(lat1) * cos(distanceRatio) + cos(lat1) * sin(distanceRatio) * cos(bearing))
            let lon2 = lon1 + atan2(sin(bearing) * sin(distanceRatio) * cos(lat1), cos(distanceRatio) - sin(lat1) * sin(lat2))

            return CLLocationCoordinate2D(latitude: lat2 * 180 / .pi, longitude: lon2 * 180 / .pi)
        }
    
    static func calculatePolygonRadius(coord: [Coordinates]) -> Double {
        let points = coordinatesToLatLng(coord)
        var maxDistance = 0.0
        
        var i = 0
        while i < points.count {
            for j in (i + 1)..<points.count {
                let distance = GMSGeometryDistance(points[i], points[j])
                if distance > maxDistance {
                    maxDistance = distance
                }
            }
            i += 20
        }
        
        return maxDistance / 2
    }
    
    static func coordinatesToLatLng(_ coordinates: [Coordinates]) -> [CLLocationCoordinate2D] {
        return coordinates.map { CLLocationCoordinate2D(latitude: $0.latitude!, longitude: $0.longitude!) }
    }
    
    static func normalizePoints(points: [CLLocationCoordinate2D], targetSize: Int) -> [CLLocationCoordinate2D] {
        guard points.count != targetSize else { return points }
        
        var result = [CLLocationCoordinate2D]()
        let scaleFactor = Double(targetSize) / Double(points.count)
        
        for i in 0..<targetSize {
            let index = Double(i) / scaleFactor
            let lowerIndex = Int(index)
            let upperIndex = (lowerIndex + 1) % points.count
            let fraction = index - Double(lowerIndex)
            
            let lowerPoint = points[lowerIndex]
            let upperPoint = points[upperIndex]
            
            let interpolatedPoint = CLLocationCoordinate2D(
                latitude: lowerPoint.latitude + fraction * (upperPoint.latitude - lowerPoint.latitude),
                longitude: lowerPoint.longitude + fraction * (upperPoint.longitude - lowerPoint.longitude)
            )
            result.append(interpolatedPoint)
        }
        
        return result
    }
    
    static func rotatePoints(fromPoints: [CLLocationCoordinate2D], toPoints: [CLLocationCoordinate2D]) -> ([CLLocationCoordinate2D], [CLLocationCoordinate2D]) {
            var startingPointIndex = 0
            var startingPointFromIndex = 0
            var minDistance = Double.greatestFiniteMagnitude
            
            for (j, from) in fromPoints.enumerated() {
                for (i, to) in toPoints.enumerated() {
                    let dist = GMSGeometryDistance(from, to)
                    if dist < minDistance {
                        minDistance = dist
                        startingPointIndex = i
                        startingPointFromIndex = j
                    }
                }
            }

            let rotatedFromPoints = rotateList(fromPoints, startIndex: startingPointFromIndex)
            let rotatedToPoints = rotateList(toPoints, startIndex: startingPointIndex)
            
            return (rotatedFromPoints, rotatedToPoints)
        }
    
    static func rotateList(_ points: [CLLocationCoordinate2D], startIndex: Int) -> [CLLocationCoordinate2D] {
            return Array(points[startIndex...] + points[..<startIndex])
        }

    static func interpolatePoints(fromPoints: [CLLocationCoordinate2D], toPoints: [CLLocationCoordinate2D], t: Float) -> [CLLocationCoordinate2D] {
            return zip(fromPoints, toPoints).map { (from, to) in
                CLLocationCoordinate2D(
                    latitude: from.latitude + Double(t) * (to.latitude - from.latitude),
                    longitude: from.longitude + Double(t) * (to.longitude - from.longitude)
                )
            }
        }
    
    static func normalizeOrientation(polygon: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
            return isClockwise(polygon: polygon) ? polygon : polygon.reversed()
        }
    
    private static func isClockwise(polygon: [CLLocationCoordinate2D]) -> Bool {
            var sum = 0.0
            for i in 0..<polygon.count {
                let p1 = polygon[i]
                let p2 = polygon[(i + 1) % polygon.count]
                sum += (p2.longitude - p1.longitude) * (p2.latitude + p1.latitude)
            }
            return sum > 0
        }
    
    static func computeAngles(polygon: [CLLocationCoordinate2D], centroid: CLLocationCoordinate2D) -> [(CLLocationCoordinate2D, Double)] {
            return polygon.map { vertex in
                let angle = atan2(vertex.latitude - centroid.latitude, vertex.longitude - centroid.longitude)
                return (vertex, angle)
            }.sorted { $0.1 < $1.1 }
        }
    
    static func matchVertices(polygon1: [CLLocationCoordinate2D], polygon2: [CLLocationCoordinate2D]) -> ([CLLocationCoordinate2D], [CLLocationCoordinate2D]) {
        let centroid1 = calculateCentroid(points: polygon1)
        let centroid2 = calculateCentroid(points: polygon2)
        
        let sorted1 = computeAngles(polygon: polygon1, centroid: centroid1).map { $0.0 }
        let sorted2 = computeAngles(polygon: polygon2, centroid: centroid2).map { $0.0 }
        
        return (sorted1, sorted2)
    }

    static func vertexCorrespondence(fromPoints: [CLLocationCoordinate2D], toPoints: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
            var reorderedToPoints = [CLLocationCoordinate2D]()
            var usedIndices = Set<Int>()

            fromPoints.forEach { from in
                let nearestIndex = toPoints.enumerated()
                    .filter { !usedIndices.contains($0.offset) }
                    .min { GMSGeometryDistance(from, $0.element) < GMSGeometryDistance(from, $1.element) }?
                    .offset ?? 0

                reorderedToPoints.append(toPoints[nearestIndex])
                usedIndices.insert(nearestIndex)
            }

            return reorderedToPoints
        }
    
    static func addVerticesToMatch(poly1: [CLLocationCoordinate2D], poly2: [CLLocationCoordinate2D]) -> ([CLLocationCoordinate2D], [CLLocationCoordinate2D]) {
            var polygon1 = poly1
            var polygon2 = poly2

            while polygon1.count < polygon2.count {
                polygon1 = addVertex(polygon: polygon1)
            }
            while polygon2.count < polygon1.count {
                polygon2 = addVertex(polygon: polygon2)
            }
            
            return (polygon1, polygon2)
        }
    
    static func addVertex(polygon: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
            var newPolygon = [CLLocationCoordinate2D]()

            for i in 0..<polygon.count {
                newPolygon.append(polygon[i])
                if i < polygon.count - 1 {
                    // Add interpolated point between current and next point
                    let interpolatedPoint = interpolate(start: polygon[i], end: polygon[i + 1], t: 0.5)
                    newPolygon.append(interpolatedPoint)
                }
            }
            
            return newPolygon
        }
    
    static func interpolate(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, t: Double) -> CLLocationCoordinate2D {
            let latitude = (1 - t) * start.latitude + t * end.latitude
            let longitude = (1 - t) * start.longitude + t * end.longitude
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    
    static func orderVertices(polygon: [CLLocationCoordinate2D], centroid: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
            return polygon.sorted { point1, point2 in
                let angle1 = atan2(point1.latitude - centroid.latitude, point1.longitude - centroid.longitude)
                let angle2 = atan2(point2.latitude - centroid.latitude, point2.longitude - centroid.longitude)
                return angle1 < angle2
            }
        }

    static func distance(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Double {
            let latDiff = a.latitude - b.latitude
            let lonDiff = a.longitude - b.longitude
            return sqrt(latDiff * latDiff + lonDiff * lonDiff)
        }
    
    static func rotateList(points: [CLLocationCoordinate2D], startIndex: Int) -> [CLLocationCoordinate2D] {
            let rotatedPoints = Array(points[startIndex...]) + Array(points[..<startIndex])
            return rotatedPoints
        }
    
    static func doLinesIntersect(p1: Coordinates, p2: Coordinates, q1: Coordinates, q2: Coordinates) -> Bool {

            func orientation(p: Coordinates, q: Coordinates, r: Coordinates) -> Int {
                let firstValue = (q.latitude! - p.latitude!) * (r.longitude! - q.longitude!)
                let secondValue = (q.longitude! - p.longitude!) * (r.latitude! - q.latitude!)
                let value = firstValue - secondValue
                if value == 0 { return 0 } // collinear
                return value > 0 ? 1 : 2 // clockwise or counterclockwise
            }

            func onSegment(p: Coordinates, q: Coordinates, r: Coordinates) -> Bool {
                return min(p.latitude!, r.latitude!) <= q.latitude! && q.latitude! <= max(p.latitude!, r.latitude!) &&
                       min(p.longitude!, r.longitude!) <= q.longitude! && q.longitude! <= max(p.longitude!, r.longitude!)
            }

            let o1 = orientation(p: p1, q: p2, r: q1)
            let o2 = orientation(p: p1, q: p2, r: q2)
            let o3 = orientation(p: q1, q: q2, r: p1)
            let o4 = orientation(p: q1, q: q2, r: p2)

            // General case
            if o1 != o2 && o3 != o4 { return true }

            // Special cases
            if o1 == 0 && onSegment(p: p1, q: q1, r: p2) { return true }
            if o2 == 0 && onSegment(p: p1, q: q2, r: p2) { return true }
            if o3 == 0 && onSegment(p: q1, q: p1, r: q2) { return true }
            if o4 == 0 && onSegment(p: q1, q: p2, r: q2) { return true }

            return false
        }
    
    static func doPolygonsOverlap(polygon1: [Coordinates], polygon2: [Coordinates]) -> Bool {
            for i in 0..<polygon1.count {
                let p1 = polygon1[i]
                let p2 = polygon1[(i + 1) % polygon1.count]

                for j in 0..<polygon2.count {
                    let q1 = polygon2[j]
                    let q2 = polygon2[(j + 1) % polygon2.count]

                    if doLinesIntersect(p1: p1, p2: p2, q1: q1, q2: q2) {
                        return true
                    }
                }
            }
            return false
        }
    
    static func coordinatesToLatLng(line: [Coordinates]) -> [CLLocationCoordinate2D] {
            return line.map { CLLocationCoordinate2D(latitude: $0.latitude!, longitude: $0.longitude!) }
        }
    
    func coordinatesToPoint(line: [Coordinates?]) -> [Point] {
        var pointsList = [Point]()
        for coord in line {
            if let coord = coord {
                let point = Point(x: coord.latitude!, y: coord.longitude!)
                pointsList.append(point)
            }
        }
        return pointsList
    }

    
    static func pointsToLatLng(points: [Point]) -> [CLLocationCoordinate2D] {
            return points.map { CLLocationCoordinate2D(latitude: $0.x, longitude: $0.y) }
        }
    
    static func latLngToPoints(lats: [CLLocationCoordinate2D]) -> [Point] {
            return lats.map { Point(x: $0.latitude, y: $0.longitude) }
        }
    
   static func getTransparencyForDistanceAbove500(size: Double) -> Float {
        switch size {
        case 500.0...:
            return 0.0
        case 250.0..<500.0:
            return 0.2
        case 150.0..<250.0:
            return 0.4
        case 100.0..<150.0:
            return 0.6
        case 50.0..<100.0:
            return 0.8
        default:
            return 0.9
        }
    }

   static func getTransparencyForDistanceBetween200And500(size: Double) -> Float {
        switch size {
        case 500.0...:
            return 0.2
        case 250.0..<500.0:
            return 0.0
        case 150.0..<250.0:
            return 0.2
        case 100.0..<150.0:
            return 0.4
        case 50.0..<100.0:
            return 0.6
        default:
            return 0.8
        }
    }

   static func getTransparencyForDistanceBetween100And200(size: Double) -> Float {
        switch size {
        case 500.0...:
            return 0.4
        case 250.0..<500.0:
            return 0.2
        case 150.0..<250.0:
            return 0.0
        case 100.0..<150.0:
            return 0.2
        case 50.0..<100.0:
            return 0.4
        default:
            return 0.6
        }
    }

   static func getTransparencyForDistanceBetween50And100(size: Double) -> Float {
        switch size {
        case 500.0...:
            return 0.6
        case 250.0..<500.0:
            return 0.4
        case 150.0..<250.0:
            return 0.2
        case 100.0..<150.0:
            return 0.0
        case 50.0..<100.0:
            return 0.2
        default:
            return 0.4
        }
    }

   static func getTransparencyForDistanceBelow50(size: Double) -> Float {
        switch size {
        case 500.0...:
            return 0.8
        case 250.0..<500.0:
            return 0.6
        case 150.0..<250.0:
            return 0.4
        case 100.0..<150.0:
            return 0.2
        case 50.0..<100.0:
            return 0.0
        default:
            return 0.2
        }
    }

    func getNewLatitude(latitude: Double, distance: Double) -> Double {
        let earthRadius = 6378.137 // Earth radius in kilometers
        return latitude + (distance / earthRadius) * (180 / .pi)
    }

    func getNewLongitude(longitude: Double, latitude: Double, distance: Double) -> Double {
        let earthRadius = 6378.137 // Earth radius in kilometers
        return longitude + (distance / earthRadius) * (180 / .pi) / cos(latitude * .pi / 180)
    }

    func getNewLocation(coordinates: Coordinates, positionType: PositionType, distance: Double) -> Coordinates {
        switch positionType {
        case .topCenter:
            return Coordinates(
                latitude: getNewLatitude(latitude: coordinates.latitude!, distance: distance), longitude: coordinates.longitude
            )
            
        case .bottomCenter:
            return Coordinates(
                latitude: getNewLatitude(latitude: coordinates.latitude!, distance: -distance), longitude: coordinates.longitude
            )
            
        case .leftCenter:
            return Coordinates(
                latitude: coordinates.latitude, longitude: getNewLongitude(longitude: coordinates.longitude!, latitude: coordinates.latitude!, distance: -distance)
            )
            
        case .rightCenter:
            return Coordinates(
                latitude: coordinates.latitude, longitude: getNewLongitude(longitude: coordinates.longitude!, latitude: coordinates.latitude!, distance: distance)
            )
            
        case .topLeft:
            let topCenter = Coordinates(
                latitude: getNewLatitude(latitude: coordinates.latitude!, distance: distance), longitude: coordinates.longitude
            )
            return Coordinates(
                latitude: topCenter.latitude, longitude: getNewLongitude(longitude: topCenter.longitude!, latitude: topCenter.latitude!, distance: -distance)
            )
            
        case .bottomRight:
            let bottomCenter = Coordinates(
                latitude: getNewLatitude(latitude: coordinates.latitude!, distance: -distance), longitude: coordinates.longitude
            )
            return Coordinates(
                latitude: bottomCenter.latitude, longitude: getNewLongitude(longitude: bottomCenter.longitude!, latitude: bottomCenter.latitude!, distance: distance)
            )
        }
    }
    
   static func overlaysDistance(lat1: Double, lat2: Double, lon1: Double, lon2: Double, el1: Double, el2: Double) -> Double {
        let latDistance = (lat2 - lat1).toRadians()
        let lonDistance = (lon2 - lon1).toRadians()
        
        let a = sin(latDistance / 2) * sin(latDistance / 2) +
                cos(lat1.toRadians()) * cos(lat2.toRadians()) *
                sin(lonDistance / 2) * sin(lonDistance / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        var distance = CoordinatesUtil.earthRadius * c // convert to km
        
        let height = el1 - el2
        distance = pow(distance, 2.0) + pow(height, 2.0)
        
        return sqrt(distance)
    }

    
    func haversineDistance(latLng1: Coordinates, latLng2: Coordinates) -> Double {
        let R = 6371.0 // Earth radius in kilometers
        let lat1 = latLng1.latitude!
        let lon1 = latLng1.longitude!
        let lat2 = latLng2.latitude!
        let lon2 = latLng2.longitude!

        let dLat = (lat2 - lat1).toRadians()
        let dLon = (lon2 - lon1).toRadians()

        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1.toRadians()) * cos(lat2.toRadians()) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return R * c
    }
    
    func isNearby(polygon1: [Coordinates], polygon2: [Coordinates], radiusKm: Double = 1.0) -> Bool {
        let fromPolygon = reducePolygonSize(polygon: polygon1, percentage: 0.3)
        let toPolygon = reducePolygonSize(polygon: polygon2, percentage: 0.3)
        
        for point1 in fromPolygon {
            for point2 in toPolygon {
                if haversineDistance(latLng1: point1, latLng2: point2) <= radiusKm {
                    return true
                }
            }
        }
        return false
    }
    
    func reducePolygonSize(polygon: [Coordinates], percentage: Double) -> [Coordinates] {
        // Calculate the number of elements to remove
        let totalElements = polygon.count
        let elementsToRemove = Int(Double(totalElements) * percentage)
        
        // Determine the step size for linear removal
        let stepSize = totalElements / elementsToRemove
        
        // Create a new list that skips elements at the calculated step size
        return polygon.enumerated().compactMap { index, element in
            return (index % stepSize != 0) ? element : nil
        }
    }

   static func scaleCoordinate(from center: CLLocationCoordinate2D, to target: CLLocationCoordinate2D, scale: Double) -> CLLocationCoordinate2D {
        let latitudeDiff = target.latitude - center.latitude
        let longitudeDiff = target.longitude - center.longitude
        
        let scaledLatitude = center.latitude + latitudeDiff * scale
        let scaledLongitude = center.longitude + longitudeDiff * scale
        
        return CLLocationCoordinate2D(latitude: scaledLatitude, longitude: scaledLongitude)
    }


    static func getTransparencyForDistanceAbove500(size: Double) -> CGFloat {
        switch size {
        case _ where size >= 500.0: return 0.0
        case _ where size >= 250.0: return 0.2
        case _ where size >= 150.0: return 0.4
        case _ where size >= 100.0: return 0.6
        case _ where size >= 50.0: return 0.8
        default: return 0.9
        }
    }
}

// Extensions for angle and distance calculations
extension Double {
    var degreesToRadians: Double { return self * .pi / 180 }
    var radiansToDegrees: Double { return self * 180 / .pi }
}
