//
//  PlaceMarkerView.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 03/04/2021.
//

import Foundation
import UIKit

class PlaceMarkerView: RoundedView {
    private let image: UIImage!
    private var bgColor: UIColor = .white
    private var widthMultiplier: CGFloat = 0.5
    private let imageView: UIImageView!
    private var isWidthFixed = false
    
    init(image: UIImage, bgColor: UIColor, size: CGSize, displayShadow: Bool = false, widthMultiplier: CGFloat = 0.5, isWidthFixed: Bool = false) {
        self.image = image
        self.imageView = UIImageView(image: image)
        self.widthMultiplier = widthMultiplier
        self.isWidthFixed = isWidthFixed
        super.init(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        self.bgColor = bgColor
        self.backgroundColor = bgColor
        self.translatesAutoresizingMaskIntoConstraints = false
        self.widthAnchor.constraint(equalToConstant: size.width).isActive = true
        self.heightAnchor.constraint(equalToConstant: size.height).isActive = true
        self.isCircular = true
        if displayShadow {
            self.displayShadow = true
            self.shadowOffset = CGSize(width: 0, height: 3)
            self.shadowRadius = 6
            self.shadowColor = .black
            self.shadowOpacity = 0.16
        }
        self.setNeedsDisplay()
        addImageView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addImageView() {
        addSubview(imageView)
        imageView.tintColor = UIColor(named: AppColors.appWarmGray2.rawValue)!
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let aspectRatio = self.image.size.height / self.image.size.width
        if isWidthFixed {
            imageView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: widthMultiplier).isActive = true
        }
        else {
            imageView.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, multiplier: widthMultiplier).isActive = true
        }
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: aspectRatio).isActive = true
        imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.imageView.layoutIfNeeded()
        self.layoutIfNeeded()
    }
    
    var toImage: UIImage {
        let renderer = UIGraphicsImageRenderer(size: self.bounds.size)
        let image = renderer.image { ctx in
            self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        }
        return image
    }
}
