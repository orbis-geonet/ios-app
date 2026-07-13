//
//  LiquidGlassView.swift
//  Orbis-iOS
//
//  Created by Zohaib Ahmad on 02/06/2026.
//


import UIKit

class CustomIntensityVisualEffectView: UIVisualEffectView {

    private let customIntensity: CGFloat
    private var animator: UIViewPropertyAnimator?
    

    init(effect: UIVisualEffect, intensity: CGFloat) {
        self.customIntensity = intensity
        super.init(effect: nil)

        animator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
            self.effect = effect
        }

        animator?.fractionComplete = customIntensity
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}



@IBDesignable
class LiquidGlassView: UIView {

    private let blurView = CustomIntensityVisualEffectView(
        effect: UIBlurEffect(style: .systemUltraThinMaterialLight),
        intensity: 0.06
    )
    @IBInspectable var isCircle: Bool = false {
        didSet { setNeedsLayout() }
    }

    private let glassLayer = UIView()
    private let borderLayer = CAShapeLayer()

    @IBInspectable var cornerRadius: CGFloat = 24 {
        didSet { updateStyle() }
    }

    @IBInspectable var blurIntensity: CGFloat = 0.12 {
        didSet {
            rebuildBlur()
        }
    }

    private func rebuildBlur() {
        blurView.removeFromSuperview()
        setupView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear
        clipsToBounds = false

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 16
        layer.shadowOffset = CGSize(width: 0, height: 8)

        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.clipsToBounds = true
        blurView.isUserInteractionEnabled = false
        insertSubview(blurView, at: 0)

        glassLayer.backgroundColor = UIColor(
            red: 217 / 255,
            green: 217 / 255,
            blue: 217 / 255,
            alpha: 0.2
        )

        glassLayer.translatesAutoresizingMaskIntoConstraints = false
        glassLayer.isUserInteractionEnabled = false
        insertSubview(glassLayer, aboveSubview: blurView)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            glassLayer.topAnchor.constraint(equalTo: topAnchor),
            glassLayer.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassLayer.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassLayer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.white.withAlphaComponent(0.18).cgColor
        borderLayer.lineWidth = 1
        layer.addSublayer(borderLayer)

        updateStyle()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateStyle()
    }
    
    private func updateStyle() {
        let radius = isCircle ? min(bounds.width, bounds.height) / 2 : cornerRadius

        layer.cornerRadius = radius

        blurView.layer.cornerRadius = radius
        blurView.clipsToBounds = true

        glassLayer.layer.cornerRadius = radius
        glassLayer.clipsToBounds = true

        let path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            cornerRadius: radius
        )

        borderLayer.frame = bounds
        borderLayer.path = path.cgPath
    }
}
