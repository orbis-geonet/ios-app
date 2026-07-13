//
//  OrbisStoryStaticSnapView.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 15/04/2021.
//

import Foundation
import UIKit

class OrbisStoryStaticSnapView: UIView {
    
    var imageView: UIImageView!
    var postDescriptionLabel: UILabel!
    
    let mimeType: OrbisPostType!
    
    //MARK: - Overriden functions
    init(mimeType: OrbisPostType) {
        self.mimeType = mimeType
        super.init(frame: .zero)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        loadUIElements()
        installLayoutConstraints()
    }
    
    //MARK: - Private functions
    private func loadUIElements(){
        backgroundColor = .black
        initializeImageView()
        initializeDescriptionLabel()
        addSubview(imageView)
        addSubview(postDescriptionLabel)
        self.bringSubviewToFront(postDescriptionLabel)
    }
    
    private func initializeImageView() {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        self.imageView = imageView
    }
    
    private func initializeDescriptionLabel() {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.numberOfLines = 0
        lbl.textColor = .white
        lbl.font = UIFont(name: "Roboto-Regular", size: CGFloat(16).relativeToIphone8Width())!
        lbl.textAlignment = .center
        self.postDescriptionLabel = lbl
    }
    
    private func installLayoutConstraints(){
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.igTopAnchor.constraint(equalTo: self.igTopAnchor),
            self.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            self.bottomAnchor.constraint(equalTo: imageView.igBottomAnchor)
            ])
        NSLayoutConstraint.activate([
            postDescriptionLabel.igLeftAnchor.constraint(equalTo: self.igLeftAnchor, constant: 15.toCGFloat.relativeToIphone8Width()),
            self.igRightAnchor.constraint(equalTo: postDescriptionLabel.igRightAnchor, constant: 15.toCGFloat.relativeToIphone8Width()),
            postDescriptionLabel.heightAnchor.constraint(lessThanOrEqualTo: self.heightAnchor, multiplier: 0.7),
            postDescriptionLabel.igCenterYAnchor.constraint(equalTo: self.igCenterYAnchor)
            ])
    }
}
