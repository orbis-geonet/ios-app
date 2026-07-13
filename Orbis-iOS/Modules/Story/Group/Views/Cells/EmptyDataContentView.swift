//
//  EmptyDataContentView.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 04/05/2021.
//

import UIKit

class HorizontalStackView: UIStackView {
    init(arrangedElements subViews: [UIView], alignment: UIStackView.Alignment, distribution: UIStackView.Distribution, spacing: CGFloat) {
        super.init(frame: .zero)
        self.axis = .horizontal
        self.alignment = alignment
        self.distribution = distribution
        self.spacing = spacing
        subViews.forEach { view in
            self.addArrangedSubview(view)
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class VerticalStackView: UIStackView {
    init(arrangedElements subViews: [UIView], alignment: UIStackView.Alignment, distribution: UIStackView.Distribution, spacing: CGFloat) {
        super.init(frame: .zero)
        self.axis = .vertical
        self.alignment = alignment
        self.distribution = distribution
        self.spacing = spacing
        subViews.forEach { view in
            self.addArrangedSubview(view)
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class HorizontalSpacerView: UIView {
    init(length: CGFloat) {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        NSLayoutConstraint.activate([
            self.widthAnchor.constraint(equalToConstant: length.relativeToIphone8Width()),
            self.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class VerticalSpacerView: UIView {
    init(height: CGFloat) {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        NSLayoutConstraint.activate([
            self.widthAnchor.constraint(equalToConstant: 1),
            self.heightAnchor.constraint(equalToConstant: height.relativeToIphone8Width())
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class EmptyDataContentView: UIView {
    var imageView: UIImageView!
    var descriptionLabel: UILabel!
    var contentPadding: UIEdgeInsets!
    
    lazy var contentStackView = VerticalStackView(arrangedElements: [VerticalSpacerView(height: 25), imageView, descriptionLabel], alignment: .center, distribution: .fill, spacing: 30)
    
    init(description: String, image: UIImage, imageSize: CGSize, contentPadding: UIEdgeInsets, backgroundColor: UIColor = .clear) {
        super.init(frame: .zero)
        descriptionLabel = getLabel(withText: description)
        imageView = getImageView(withImage: image, imageSize: imageSize)
        self.contentPadding = contentPadding
        self.backgroundColor = backgroundColor
        addContentToView()
    }
    
    private func addContentToView() {
        self.addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: contentPadding.top.relativeToIphone8Width()),
            contentStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -contentPadding.bottom.relativeToIphone8Width()),
            contentStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: contentPadding.left.relativeToIphone8Width()),
            contentStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -contentPadding.right.relativeToIphone8Width())
        ])
    }
    
    private func getImageView(withImage image: UIImage, imageSize: CGSize) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: imageSize.width.relativeToIphone8Width()),
            imageView.heightAnchor.constraint(equalToConstant: imageSize.height.relativeToIphone8Width())
        ])
        return imageView
    }
    
    private func getLabel(withText text: String) -> UILabel {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = text
        label.font = UIFont(name: "Roboto-Regular", size: CGFloat(16).relativeToIphone8Width())!
        label.textColor = UIColor(named: AppColors.appPinkishGray.rawValue)
        return label
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class OrbisViewAttachedTableViewCell: UITableViewCell {
    var attachedView: UIView = UIView()
    private let emptyViewTag = 9281993
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addAttachedView()
    }
    
    private func addAttachedView() {
        self.contentView.subviews.forEach { view in
            view.removeFromSuperview()
        }
        attachedView = UIView(frame: self.bounds)
        self.contentView.addSubview(attachedView)
        attachedView.translatesAutoresizingMaskIntoConstraints = false
        let bottomConstraint = attachedView.bottomAnchor.constraint(greaterThanOrEqualTo: self.contentView.bottomAnchor)
        bottomConstraint.priority = UILayoutPriority.init(rawValue: 750)
        NSLayoutConstraint.activate([
            attachedView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            attachedView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            attachedView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            bottomConstraint
        ])
    }
    
    func addContent(view: UIView) {
        guard !self.attachedView.subviews.contains(where: {$0.tag == emptyViewTag }) else { return }
        view.tag = emptyViewTag
        self.attachedView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: self.attachedView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: self.attachedView.trailingAnchor),
            view.topAnchor.constraint(equalTo: self.attachedView.topAnchor),
            view.bottomAnchor.constraint(equalTo: self.attachedView.bottomAnchor)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addAttachedView()
    }
}
