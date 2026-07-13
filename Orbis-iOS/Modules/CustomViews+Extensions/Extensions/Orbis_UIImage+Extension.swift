//
//  UIImage+Extension.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/03/2021.
//

import UIKit
import ImageIO

extension UIImage {
    func makeRoundImg() -> UIImage {
        let img = UIImageView(image: self)
        img.contentMode = .scaleAspectFill
        img.frame.size = CGSize(width: self.size.width, height: self.size.width)
        let imgLayer = CALayer()
        imgLayer.frame = img.bounds
        imgLayer.contents = img.image?.cgImage
        imgLayer.masksToBounds = true
        imgLayer.cornerRadius = self.size.width / 2
        
        UIGraphicsBeginImageContext(img.bounds.size)
        imgLayer.render(in: UIGraphicsGetCurrentContext()!)
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return roundedImage!
    }
    
    var isPortrait:  Bool    { size.height > size.width }
    var isLandscape: Bool    { size.width > size.height }
    var breadth:     CGFloat { min(size.width, size.height) }
    var breadthSize: CGSize  { .init(width: breadth, height: breadth) }
    var breadthRect: CGRect  { .init(origin: .zero, size: breadthSize) }
    
    func makeRoundImg(with color: UIColor, borderWidth borderSize: CGFloat) -> UIImage? {
        guard let cgImage = cgImage?.cropping(to: .init(origin: .init(x: isLandscape ? ((size.width-size.height)/2).rounded(.down) : .zero, y: isPortrait ? ((size.height-size.width)/2).rounded(.down) : .zero), size: breadthSize)) else { return nil }
//        var width = floor((borderSize / 180.toCGFloat) * breadth)
        let width = borderSize
        
        let bleed = breadthRect.insetBy(dx: -width, dy: -width)
        let format = imageRendererFormat
        format.opaque = false
        
        return UIGraphicsImageRenderer(size: bleed.size, format: format).image { context in
            UIBezierPath(ovalIn: .init(origin: .zero, size: bleed.size)).addClip()
            var strokeRect =  breadthRect.insetBy(dx: -width/2, dy: -width/2)
            strokeRect.origin = .init(x: width/2, y: width/2)
            UIImage(cgImage: cgImage, scale: 1, orientation: imageOrientation)
            .draw(in: strokeRect.insetBy(dx: width/2, dy: width/2))
            context.cgContext.setStrokeColor(color.cgColor)
            let line: UIBezierPath = .init(ovalIn: strokeRect)
            line.lineWidth = width
            line.stroke()
        }
    }
    
    convenience init(view: UIView) {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in:UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: image!.cgImage!)
    }
    
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
    func resizeImage(targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = widthRatio > heightRatio ?  CGSize(width: size.width * heightRatio, height: size.height * heightRatio) : CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func compressedJPEGImage(quality: CGFloat) -> UIImage? {
        return autoreleasepool {
            () -> UIImage? in
            if let imgData = self.UIImageToDataJPEG2(compressionRatio: 1) {
                return UIImage(data: imgData)
            }
            return nil
        }
    }
    
    func UIImageToDataJPEG2(compressionRatio: CGFloat) -> Data? {
        return autoreleasepool(invoking: { () -> Data? in
            return self.jpegData(compressionQuality: compressionRatio)
        })
    }
}

extension Data {
    
    var mimeType: String {
        return Swime.mimeType(data: self)?.mime ?? "application/octet-stream"
    }
    
    var fileExtension: String {
        let mimeType = self.mimeType
        return ".\(mimeType.split(separator: "/").last!)"
    }
}

extension UIImageView {
    
    func setSDWebImage(urlString: String, placeholderImage: UIImage?, storageDirectory: ProjectStorageDirectories, sizeModifier: OrbisImageSizeResolution, completion: (() -> Void)? = nil) {
        // `completion` fires (on main, as SDWebImage delivers) once the load settles — success OR
        // failure, including the size-modifier fallback retry. Default nil keeps existing callers unchanged.
        if urlString.isNotUrlLink {
            let ref = urlString.getFirebaseReference(storage: storageDirectory, imageSizeResolution: sizeModifier)
            self.sd_setImage(with: ref, placeholderImage: placeholderImage) {
                [weak self] image, err, _, _ in
                if let _ = err, ref.name.contains(sizeModifier.rawValue) {
                    let newRef = urlString.getFirebaseReference(removingSizeModifier: sizeModifier, from: ref)
                    self?.sd_setImage(with: newRef, placeholderImage: placeholderImage) { _, _, _, _ in completion?() }
                } else {
                    completion?()
                }
            }
        }
        else {
            self.sd_setImage(with: URL(string: urlString)!, placeholderImage: placeholderImage) { _, _, _, _ in completion?() }
        }
    }
}
