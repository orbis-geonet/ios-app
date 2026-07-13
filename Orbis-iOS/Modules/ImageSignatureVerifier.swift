
import UIKit

struct ImageSignatureVerifier {
    static func getSignature(of image: UIImage) -> String {
        guard let cgImage = image.cgImage else { print("+++ failed to get cgImage"); return "-1" }
        let height = Double(cgImage.height)
        let width = Double(cgImage.width)
        
//        let tenTopLeft = CGPoint(x: width * 0.1, y: height * 0.1)
//        let tenTopRight = CGPoint(x: width * 0.9, y: height * 0.1)
//        let tenBottomLeft = CGPoint(x: width * 0.1, y: height * 0.9)
//        let tenBottomRight = CGPoint(x: width * 0.9, y: height * 0.9)
//        let fortyTopLeft = CGPoint(x: width * 0.4, y: height * 0.4)
//        let fortyTopRight = CGPoint(x: width * 0.6, y: height * 0.4)
//        let fortyBottomLeft = CGPoint(x: width * 0.4, y: height * 0.6)
//        let fortyBottomRight = CGPoint(x: width * 0.6, y: height * 0.6)
//        let center = CGPoint(x: width * 0.5, y: height * 0.5)
        
        let tenTopLeft = CGPoint(x: width * 0.2, y: height * 0.1)
        let tenTopRight = CGPoint(x: width * 0.5, y: height * 0.1)
        let tenBottomLeft = CGPoint(x: width * 0.7, y: height * 0.7)
        let tenBottomRight = CGPoint(x: width * 0.8, y: height * 0.9)
        let fortyTopLeft = CGPoint(x: width * 0.3, y: height * 0.4)
        let fortyTopRight = CGPoint(x: width * 0.4, y: height * 0.4)
        let fortyBottomLeft = CGPoint(x: width * 0.5, y: height * 0.6)
        let fortyBottomRight = CGPoint(x: width * 0.7, y: height * 0.8)
        let center = CGPoint(x: width * 0.5, y: height * 0.5)
        
        let points = [tenTopLeft, tenTopRight, tenBottomLeft, tenBottomRight, fortyTopLeft, fortyTopRight, fortyBottomLeft, fortyBottomRight, center]
        
        var subscription = ""
        
        points.forEach {
            print("+++ Point: \($0)")
            let pixelColor = cgImage.getPixelColor($0)
            subscription += pixelColor.toHexString()
            print("+++ Signature: \(subscription)")
        }
        
        print("+++ Signature successfully created - \(subscription)")
        
        return subscription
    }
}

public extension CGBitmapInfo {
    // See https://stackoverflow.com/a/60247648/1765629
    // I've extended it to include .a
    enum ComponentLayout {

        case a
        case bgra
        case abgr
        case argb
        case rgba
        case bgr
        case rgb

        var count: Int {
            switch self {
            case .a: return 1
            case .bgr, .rgb: return 3
            default: return 4
            }
        }
    }
    
    var componentLayout: ComponentLayout? {
            guard let alphaInfo = CGImageAlphaInfo(rawValue: rawValue & Self.alphaInfoMask.rawValue) else { return nil }
            let isLittleEndian = contains(.byteOrder32Little)

            if alphaInfo == .none {
                return isLittleEndian ? .bgr : .rgb
            }
        
            let alphaIsFirst = alphaInfo == .premultipliedFirst || alphaInfo == .first || alphaInfo == .noneSkipFirst

            if isLittleEndian {
                return alphaIsFirst ? .bgra : .abgr
            } else {
                return alphaIsFirst ? .argb : .rgba
            }
        }

    var isAlphaPremultiplied: Bool {
        let alphaInfo = CGImageAlphaInfo(rawValue: rawValue & Self.alphaInfoMask.rawValue)
        return alphaInfo == .premultipliedFirst || alphaInfo == .premultipliedLast
    }

    // [...] skipping the rest
}

public extension CGImage {
    func getPixelColor(_ point: CGPoint) -> UIColor {
        guard let pixelData = self.dataProvider?.data, let layout = bitmapInfo.componentLayout, let data = CFDataGetBytePtr(pixelData) else {
            return .clear
        }
        
        let x = Int(point.x)
        let y = Int(point.y)
        let w = self.width
        let h = self.height
        let index = w * y + x
        let numBytes = CFDataGetLength(pixelData)
        let numComponents = layout.count
        if numBytes != w * h * numComponents {
            NSLog("Unexpected size: \(numBytes) != \(w)x\(h)x\(numComponents)")
            return .clear
        }
        let isAlphaPremultiplied = bitmapInfo.isAlphaPremultiplied
        switch numComponents {
        case 1:
            return UIColor(red: 0, green: 0, blue: 0, alpha: CGFloat(data[index])/255.0)
        case 3:
            let c0 = CGFloat((data[3*index])) / 255
            let c1 = CGFloat((data[3*index+1])) / 255
            let c2 = CGFloat((data[3*index+2])) / 255
            if layout == .bgr {
                return UIColor(red: c2, green: c1, blue: c0, alpha: 1.0)
            }
            return UIColor(red: c0, green: c1, blue: c2, alpha: 1.0)
        case 4:
            let c0 = CGFloat((data[4*index])) / 255
            let c1 = CGFloat((data[4*index+1])) / 255
            let c2 = CGFloat((data[4*index+2])) / 255
            let c3 = CGFloat((data[4*index+3])) / 255
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            switch layout {
            case .abgr:
                a = c0; b = c1; g = c2; r = c3
            case .argb:
                a = c0; r = c1; g = c2; b = c3
            case .bgra:
                b = c0; g = c1; r = c2; a = c3
            case .rgba:
                r = c0; g = c1; b = c2; a = c3
            default:
                break
            }
            if isAlphaPremultiplied && a > 0 {
                r = r / a
                g = g / a
                b = b / a
            }
            return UIColor(red: r, green: g, blue: b, alpha: a)
        default:
            return .clear
        }
    }
}
