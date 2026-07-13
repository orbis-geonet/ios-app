
import UIKit

import FirebaseStorage
import SDWebImage

class CardCell: UICollectionViewCell {
    
    // UI elements
    private var imageViewConstraints: [NSLayoutConstraint] = []
    private var noImageViewLeadingConstraint: NSLayoutConstraint!
    private var imageViewLeadingConstraint: NSLayoutConstraint!
    private var descriptionBottomConstraint: NSLayoutConstraint!


    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 8
        iv.layer.backgroundColor = UIColor.gray.withAlphaComponent(0.3).cgColor
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: PaddedLabel = {
        let label = PaddedLabel()
        label.numberOfLines = 0 // Allow for dynamic height based on text
        label.insetsLayoutMarginsFromSafeArea = false
        let fontSize = 16 * (UIScreen.main.bounds.width/414)
        label.font = UIFont.boldSystemFont(ofSize: fontSize)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.backgroundColor = .red
        label.setContentHuggingPriority(.defaultHigh, for: .vertical) // Prevent extra space
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        label.textInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) // Adjust padding as needed

        return label
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        //label.backgroundColor = .purple
        label.font = UIFont.systemFont(ofSize: 12)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let ratingImageView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = .systemYellow
        iv.layer.cornerRadius = 8
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return label
    }()
    
    private let descriptionLabel: TopAlignedLabel = {
        let label = TopAlignedLabel()
        label.numberOfLines = 4
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .darkGray
        label.baselineAdjustment = .alignBaselines // Align text to the top
        //label.lineBreakMode = .byWordWrapping // Ensure proper wrapping for multi-line text
        //label.backgroundColor = .red
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update shadow path dynamically based on contentView's current bounds
        contentView.layer.shadowPath = UIBezierPath(
            roundedRect: contentView.bounds,
            cornerRadius: contentView.layer.cornerRadius
        ).cgPath
    }

    private func setupView() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(ratingLabel)
        contentView.addSubview(ratingImageView)
        contentView.addSubview(distanceLabel)
        contentView.addSubview(descriptionLabel)
        
//        titleLabel.backgroundColor = .red
//        ratingLabel.backgroundColor = .orange
//        distanceLabel.backgroundColor = .yellow
//        descriptionLabel.backgroundColor = .yellow

        // Set corner radius for smooth rounded edges
        contentView.layer.cornerRadius = 15
        contentView.layer.masksToBounds = false
        
        // Improved shadow properties for a more subtle and elegant effect
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.4
        contentView.layer.shadowOffset = CGSize(width: 0, height: 7)
        contentView.layer.shadowRadius = 4
        
        // Dynamically update shadow path for better performance
        contentView.layer.shadowPath = UIBezierPath(
            roundedRect: contentView.bounds,
            cornerRadius: contentView.layer.cornerRadius
        ).cgPath
        
        // Set a light background color to contrast with the shadow
        contentView.backgroundColor = .white
    }
    
  
    private func setupConstraints() {
        
        // Constraint for when there's no image
        noImageViewLeadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        
        // Constraint for when there's no image
        imageViewLeadingConstraint = contentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8)
        
        
        NSLayoutConstraint.activate([
            // ImageView constraints
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor), // Square shape
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Title Label constraints
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            // Rating Label constraints
            ratingLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            ratingLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            ratingLabel.heightAnchor.constraint(equalToConstant: UIFont.systemFont(ofSize: 12).lineHeight), // Fixed height for one line


            ratingImageView.leadingAnchor.constraint(equalTo: ratingLabel.trailingAnchor, constant: 4),
            ratingImageView.centerYAnchor.constraint(equalTo: ratingLabel.centerYAnchor),
            ratingImageView.widthAnchor.constraint(equalToConstant: 15),
            ratingImageView.heightAnchor.constraint(equalToConstant: 15),
            
            distanceLabel.leadingAnchor.constraint(equalTo: ratingImageView.trailingAnchor, constant: 4),
            distanceLabel.centerYAnchor.constraint(equalTo: ratingLabel.centerYAnchor),
            
            // Description Label constraints (fixed height for one line)
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            descriptionLabel.topAnchor.constraint(equalTo: ratingLabel.bottomAnchor, constant: 4),
            //descriptionLabel.heightAnchor.constraint(equalToConstant: UIFont.systemFont(ofSize: 12).lineHeight), // Fixed height for one line
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
        ])
    }


    func configure(with data: PolygonPlaceDetails, Index: Int) {
        
        titleLabel.text = data.name
        
        if let averageRate = data.averageRate {
            ratingLabel.text = "\(averageRate)"
        }else {
            ratingLabel.text = "0.0"
        }
        
        ratingImageView.image = UIImage(systemName: "star.fill")
        
        if let countRates = data.countRates {
            if data.countRates ?? 0 > 1000 {
                distanceLabel.text = "(\(Double(countRates) / 1000.0) mil)"
            } else {
                distanceLabel.text = "(\(Double(countRates)))"
            }
        }else {
            distanceLabel.text = "(0)"
        }
        
        if let vDescription = data.description, !vDescription.isEmpty {
            descriptionLabel.text = "\(data.description!)"
            // HELLO HOW ARE YOU! I am good and fine. How have you been HELLO HOW ARE YOU! I am good and fine. How have you been
        }else {
            descriptionLabel.text = ""
        }
                
        NSLayoutConstraint.deactivate([imageViewLeadingConstraint] + [noImageViewLeadingConstraint])
        
        self.hideOrbisLoader(from: imageView, remove: false)

        //print("carousel cell data.imageName === \(data.imageName)")
        
        if let imageName = data.imageName {
            imageView.isHidden = false
            //imageView.image = UIImage(named: imageName)
            
            // Activate the constraints for the image view
            NSLayoutConstraint.activate([imageViewLeadingConstraint])
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8).isActive = true
            getImage(imageName: imageName, imageView: imageView)
        } else {
            imageView.isHidden = true
            imageView.image = nil
            // Activate the leading constraint for the title label to take up the full width
            NSLayoutConstraint.activate([noImageViewLeadingConstraint])
        }
    }
    
    
    func getImage(imageName : String, imageView : UIImageView)   {
        
        let storageReference = Storage.storage().reference(withPath: Constants.PLACE_PICTURES + Utils.getImageUrl200(imageName: imageName))

        // Download image using SDWebImage
        storageReference.downloadURL { [weak self] url, error in
            if let error = error {
                print("Error fetching image URL: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    imageView.isHidden = true
                    self?.hideOrbisLoader(from: imageView, remove: true)

                }
                return
            }
            
            guard let imageUrl = url else {
                DispatchQueue.main.async {
                    imageView.isHidden = true
                    self?.hideOrbisLoader(from: imageView, remove: true)
                }
                return
            }
            
            imageView.sd_setImage(with: imageUrl, placeholderImage: nil, options: [.highPriority]) { [weak self] image, error, _, _ in
                self?.hideOrbisLoader(from: imageView, remove: true)

                if let error = error {
                    print("Error loading image: \(error.localizedDescription)")
                    imageView.isHidden = true
                } else {
                    imageView.isHidden = false
                }
            }
            
        }
    }

}

class CarouselFlowLayout: UICollectionViewFlowLayout {
    
    private let itemScale: CGFloat = 0.8 // Scale for items that are not centered
    private let itemSpacing: CGFloat = 0 // Spacing between items
    
    override init() {
        super.init()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }
    
    private func setupLayout() {
        scrollDirection = .horizontal
        minimumLineSpacing = itemSpacing

    }
    
    // Set item size to be a fraction of the collection view's size, handled dynamically in `CarouselViewController`
    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }
  
        let itemWidth = collectionView.bounds.width //* 0.85
        let itemHeight = collectionView.bounds.height //* 0.95 // Reduce slightly to prevent cropping
        
        itemSize = CGSize(width: itemWidth, height: itemHeight)
    }
    
    // Center the nearest item when scrolling stops
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return proposedContentOffset }
        
        let targetRect = CGRect(x: proposedContentOffset.x, y: 0, width: collectionView.bounds.width, height: collectionView.bounds.height)
        
        guard let layoutAttributes = super.layoutAttributesForElements(in: targetRect) else { return proposedContentOffset }
        
        let centerX = proposedContentOffset.x + collectionView.bounds.width / 2
        var closestAttribute: UICollectionViewLayoutAttributes?
        
        for attributes in layoutAttributes {
            if closestAttribute == nil || abs(attributes.center.x - centerX) < abs(closestAttribute!.center.x - centerX) {
                closestAttribute = attributes
            }
        }
        
        guard let closest = closestAttribute else { return proposedContentOffset }
        
        // Return new content offset that aligns the closest item to the center
        return CGPoint(x: closest.center.x - collectionView.bounds.width / 2, y: proposedContentOffset.y)
    }
    
    // Apply scaling for the carousel effect
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView = collectionView else { return super.layoutAttributesForElements(in: rect) }
        
        let centerX = collectionView.contentOffset.x + collectionView.bounds.width / 2
        let visibleAttributes = super.layoutAttributesForElements(in: rect)
        
        visibleAttributes?.forEach { attributes in
            let distance = abs(attributes.center.x - centerX)
            let normalizedDistance = distance / collectionView.bounds.width
            let scale = max(itemScale, 1 - normalizedDistance * 0.15) // Adjust scale factor as needed
            attributes.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
        
        return visibleAttributes
    }
}



class PaddedLabel: UILabel {
    var textInsets = UIEdgeInsets.zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + textInsets.left + textInsets.right,
                      height: size.height + textInsets.top + textInsets.bottom)
    }
}


class TopAlignedLabel: UILabel {
    
    // Override the drawText function to align text to the top
    override func drawText(in rect: CGRect) {
        guard let text = self.text else {
            super.drawText(in: rect)
            return
        }
        
        // Calculate the size of the text
        let textSize = text.boundingRect(
            with: CGSize(width: rect.width, height: CGFloat.greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: self.font ?? UIFont.systemFont(ofSize: 12)],
            context: nil
        ).size
        
        // Adjust the text rect to align to the top
        let adjustedRect = CGRect(
            origin: CGPoint(x: rect.origin.x, y: rect.origin.y),
            size: CGSize(width: rect.width, height: min(rect.height, ceil(textSize.height)))
        )
        super.drawText(in: adjustedRect)
    }
    
    // Ensure intrinsic content size respects the top alignment
    override var intrinsicContentSize: CGSize {
        guard let text = self.text else {
            return super.intrinsicContentSize
        }
        
        let textSize = text.boundingRect(
            with: CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: self.font ?? UIFont.systemFont(ofSize: 12)],
            context: nil
        ).size
        
        return CGSize(width: ceil(textSize.width), height: ceil(textSize.height))
    }
    
    // Default configuration
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        self.numberOfLines = 4 // Max number of lines
        self.font = UIFont.systemFont(ofSize: 12)
        self.textColor = .darkGray
        self.textAlignment = .left
        self.translatesAutoresizingMaskIntoConstraints = false
    }
}

