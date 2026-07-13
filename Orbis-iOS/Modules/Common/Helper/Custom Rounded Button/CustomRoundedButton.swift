
import UIKit
import FirebaseStorage
import SDWebImage

class CustomRoundedButton: UIButton {
    
    private var place: PolygonPlaceDetails?
    private var callback: ((_ place: PolygonPlaceDetails?) -> Void)?
    
    // Add callback for button press
    func onTap(_ callback: @escaping (_ place: PolygonPlaceDetails?) -> Void) {
        self.callback = callback
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }
    
    // Method to update the button's content dynamically
    func updateContent(place: PolygonPlaceDetails?) {
        self.place = place

        // Set unconditionally so a nil-name tribe CLEARS the bar instead of keeping the seed
        // ("Clube do Picnic") or the previously-focused tribe's stale name.
        textLabel.text = place?.dominantGroup?.name ?? ""
        
        // Deactivate all constraints to avoid conflicts
        NSLayoutConstraint.deactivate([imageViewLeadingConstraint, noImageViewLeadingConstraint, noImageTextViewTrailingConstraint, imageTextViewTrailingConstraint])

        if let validIconName = place?.dominantGroup?.imageName {
            // Case: Icon is visible
            iconImageView.isHidden = false

            // Activate constraints for icon
            NSLayoutConstraint.activate([
                iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
                textLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 18),
                textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            ])

            getImage(imageName: validIconName, imageView: iconImageView)
        } else {
            // Case: No icon
            iconImageView.isHidden = true

            // Activate constraints for textLabel to take full width
            NSLayoutConstraint.activate([
                textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
                textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            ])
        }

        // Adjust text alignment
        textLabel.textAlignment = .left

        // Apply additional styles
        if let strokeColorHex = place?.dominantGroup?.strokeColorHex {
            self.iconImageView.layer.borderColor = UIColor(hexString: strokeColorHex).cgColor
            self.iconImageView.layer.borderWidth = 3.0
            self.iconImageView.layer.cornerRadius = self.iconImageView.frame.size.width / 2
            self.iconImageView.clipsToBounds = true
        }

        layer.cornerRadius = frame.height / 2
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }

    @objc private func handleTap() {
        callback?(place)
    }

    func getImage(imageName: String, imageView: UIImageView) {
        // Cancel any superseded in-flight sd load on this reused icon view before starting a new one.
        imageView.sd_cancelCurrentImageLoad()

        let storageReference = Storage.storage().reference(
            withPath: Constants.GROUP_PHOTO_STORAGE + Utils.getImageUrl200(imageName: imageName)
        )

        // Download image using SDWebImage
        storageReference.downloadURL { [weak self] url, error in
            // Drop a stale/out-of-order completion during rapid focus enter/exit: only the
            // currently-focused tribe's icon (matching self.place) is allowed to paint.
            guard self?.place?.dominantGroup?.imageName == imageName else { return }
            if let error = error {
                print("Error fetching image URL: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    imageView.isHidden = true
                }
                return
            }
            
            guard let imageUrl = url else {
                DispatchQueue.main.async {
                    imageView.isHidden = true
                }
                return
            }
            
            // Load the image using SDWebImage
            imageView.sd_setImage(with: imageUrl, placeholderImage: nil, options: .highPriority, completed: { [weak self] (image, error, _, _) in
                guard self?.place?.dominantGroup?.imageName == imageName else { return }
                if error != nil {
                    imageView.isHidden = true
                    if let placeType = self?.place?.placeType {
                        imageView.isHidden = false
                        imageView.image = OrbisMapPlaceIconManager.shared.placeIcons[placeType]
                    }
                } else {
                    imageView.isHidden = false
                }
            })
        }
    }

    init(icon: UIImage? = nil, title: String) {
        super.init(frame: .zero)
        setupButton(icon: icon, title: title)
        addTouchDownAnimation()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var noImageViewLeadingConstraint: NSLayoutConstraint!
    private var noImageTextViewTrailingConstraint: NSLayoutConstraint!
    private var imageViewLeadingConstraint: NSLayoutConstraint!
    private var imageTextViewTrailingConstraint: NSLayoutConstraint!
    private let iconImageView = UIImageView()
    private let textLabel = UILabel()

    private func setupButton(icon: UIImage?, title: String) {
        // Configure iconImageView
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        // Configure textLabel
        textLabel.text = title
        textLabel.numberOfLines = 0
        textLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        textLabel.textColor = .black
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.lineBreakMode = .byTruncatingTail

        addSubview(iconImageView)
        addSubview(textLabel)

        // Default constraints
        imageViewLeadingConstraint = iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12)
        noImageViewLeadingConstraint = textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12)
        noImageTextViewTrailingConstraint = textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24)
        imageTextViewTrailingConstraint = textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24)

        NSLayoutConstraint.activate([
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 42),
            iconImageView.heightAnchor.constraint(equalToConstant: 42),
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            iconImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            textLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 24),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
        ])
    }

    private func addTouchDownAnimation() {
        addTarget(self, action: #selector(animateButtonDown), for: .touchDown)
        addTarget(self, action: #selector(animateButtonUp), for: [.touchUpInside, .touchDragExit])
    }

    @objc private func animateButtonDown() {
        UIView.animate(withDuration: 0.15) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }

    @objc private func animateButtonUp() {
        UIView.animate(withDuration: 0.15) {
            self.transform = .identity
        }
    }
}
