//
//  OrbisTrackSlider.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 28/05/2021.
//

import UIKit

@IBDesignable
class OrbisTrackSlider: UISlider {
    
    @IBInspectable var thickness: CGFloat = 10 {
        didSet {
            setup()
        }
    }
    @IBInspectable var thumbSize: CGFloat = 25 {
        didSet {
            setup()
        }
    }
    @IBInspectable var sliderThumbImage: UIImage? {
        didSet {
            setup()
        }
    }
    @IBInspectable var selectedTrackColor: UIColor? {
        didSet {
            setup()
        }
    }
    @IBInspectable var unselectedTrackColor: UIColor? {
        didSet {
            setup()
        }
    }
    // Custom thumb view which will be converted to UIImage
    // and set as thumb. You can customize it's colors, border, etc.
    private lazy var thumbView: UIView = {
        let thumb = UIView()
        thumb.backgroundColor = UIColor(named: AppColors.appBlack.rawValue)//thumbTintColor
        thumb.layer.borderWidth = 4.toCGFloat.relativeToIphone8Width()
        thumb.layer.borderColor = UIColor.white.cgColor
        return thumb
    }()
    
    private func thumbImage(radius: CGFloat) -> UIImage {
        // Set proper frame
        // y: radius / 2 will correctly offset the thumb
        
        thumbView.frame = CGRect(x: 0, y: radius / 2, width: radius, height: radius)
        thumbView.layer.cornerRadius = radius / 2
        
        // Convert thumbView to UIImage
        // See this: https://stackoverflow.com/a/41288197/7235585
        
        let renderer = UIGraphicsImageRenderer(bounds: thumbView.bounds)
        return renderer.image { rendererContext in
            thumbView.layer.render(in: rendererContext.cgContext)
        }
    }
    
    func setup() {
        guard let minTrackStartColor = selectedTrackColor else{return}
        guard let maxTrackColor = unselectedTrackColor else{return}
        do {
            self.setMinimumTrackImage(try self.gradientImage(
                                        size: self.trackRect(forBounds: self.bounds).size,
                                        colorSet: [minTrackStartColor.cgColor, minTrackStartColor.cgColor]),
                                      for: .normal)
            self.setMaximumTrackImage(try self.gradientImage(
                                        size: self.trackRect(forBounds: self.bounds).size,
                                        colorSet: [maxTrackColor.cgColor, maxTrackColor.cgColor]),
                                      for: .normal)
//            self.setThumbImage(sliderThumbImage, for: .normal)
            let thumb = thumbImage(radius: thumbSize.relativeToIphone8Width())
            setThumbImage(thumb, for: .normal)
        } catch {
            self.minimumTrackTintColor = minTrackStartColor
            self.maximumTrackTintColor = maxTrackColor
        }
    }
    func gradientImage(size: CGSize, colorSet: [CGColor]) throws -> UIImage? {
        let tgl = CAGradientLayer()
        tgl.frame = CGRect.init(x:0, y:0, width:size.width, height: size.height)
        tgl.cornerRadius = tgl.frame.height / 2
        tgl.masksToBounds = false
        tgl.colors = colorSet
        tgl.startPoint = CGPoint.init(x:0.0, y:0.5)
        tgl.endPoint = CGPoint.init(x:1.0, y:0.5)
        
        UIGraphicsBeginImageContextWithOptions(size, tgl.isOpaque, 0.0);
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        tgl.render(in: context)
        let image =
            
            UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets:
                                                                            UIEdgeInsets.init(top: 0, left: size.height, bottom: 0, right: size.height))
        UIGraphicsEndImageContext()
        return image!
    }
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let height = thickness.relativeToIphone8Width()
        let originY = (bounds.height / 2) - (thickness / 2)
        return CGRect(
            x: bounds.origin.x,
            y: originY,
            width: bounds.width,
            height: height
        )
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
}
