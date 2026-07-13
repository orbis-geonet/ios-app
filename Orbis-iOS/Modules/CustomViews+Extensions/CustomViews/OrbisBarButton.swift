//
//  OrbisBarButton.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 30/03/2021.
//

import Foundation
import Tabman

class TMFixedWidthLineBarIndicator: TMLineBarIndicator {
    private let fixedWidthLineView = UIView()
    private let widthMultiplier: CGFloat = 0.85
    
    override var tintColor: UIColor! {
        didSet {
            backgroundColor = .clear
            fixedWidthLineView.backgroundColor = tintColor
        }
    }
    
    override func layout(in view: UIView) {
        super.layout(in: view)
        
        view.addSubview(fixedWidthLineView)
        fixedWidthLineView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            fixedWidthLineView.topAnchor.constraint(equalTo: topAnchor),
            fixedWidthLineView.bottomAnchor.constraint(equalTo: bottomAnchor),
            fixedWidthLineView.centerXAnchor.constraint(equalTo: centerXAnchor),
            fixedWidthLineView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: widthMultiplier)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        fixedWidthLineView.layer.cornerRadius = layer.cornerRadius
    }
}

typealias OrbisTMBarButton = TMBarView<TMHorizontalBarLayout, TMLabelBarButton, TMFixedWidthLineBarIndicator>
