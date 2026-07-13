//
//  NearbyCommunityCell.swift
//  Orbis-iOS
//
//  Created by Zohaib Ahmad on 03/06/2026.
//

import UIKit
import FirebaseStorage
import SDWebImage



final class NearbyCommunityCell: UITableViewCell {

    static let identifier = "NearbyCommunityCell"

    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let activityIcon = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        
        selectionStyle = .none
        avatarImageView.layer.cornerRadius = 24
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.backgroundColor = .systemGray5
        avatarImageView.layer.borderWidth = 3
        avatarImageView.layer.borderColor = UIColor.systemGray4.cgColor

        nameLabel.font = UIFont(name: "Roboto-Medium", size: 14)
        nameLabel.textColor = .black
        
        descriptionLabel.font = UIFont(name: "Roboto-Regular", size: 12)
        descriptionLabel.textColor = .gray
        descriptionLabel.numberOfLines = 2
        [avatarImageView, nameLabel, descriptionLabel, activityIcon].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            avatarImageView.widthAnchor.constraint(equalToConstant: 48),
            avatarImageView.heightAnchor.constraint(equalToConstant: 48),

            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),

            descriptionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: activityIcon.leadingAnchor, constant: -12),
            descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

            activityIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            activityIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            activityIcon.widthAnchor.constraint(equalToConstant: 20),
            activityIcon.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    func configure(place: PolygonPlaceDetails) {
        applyContent(
            name: place.dominantGroup?.name ?? place.name ?? "Community",
            description: place.dominantGroup?.description ?? "",
            strokeColorHex: place.dominantGroup?.strokeColorHex,
            imageName: place.dominantGroup?.imageName ?? ""
        )
    }

    // Server tribe-search result rows (no polygon place wrapper).
    func configure(group: Group) {
        applyContent(
            name: group.name ?? "Community",
            description: group.description ?? "",
            strokeColorHex: group.strokeColorHexString,
            imageName: group.imageName ?? ""
        )
    }

    private func applyContent(name: String, description: String, strokeColorHex: String?, imageName: String) {

        nameLabel.text = name
        descriptionLabel.text = description
        activityIcon.isHidden = true

        if let hexColor = strokeColorHex, !hexColor.isEmpty {
            avatarImageView.layer.borderColor = UIColor(hexString: hexColor).cgColor
        } else {
            avatarImageView.layer.borderColor = UIColor.systemGray4.cgColor
        }

        avatarImageView.image = UIImage(named: "placeholder")
        guard !imageName.isEmpty else { return }

        let storageRef = Storage.storage().reference(
            withPath: Constants.GROUP_PHOTO_STORAGE + Utils.getImageUrl200(imageName: imageName)
        )

        // Guard against reuse races: only apply the resolved URL if this cell still shows the same tribe.
        let expectedName = name
        storageRef.downloadURL { [weak self] url, error in
            guard let self, self.nameLabel.text == expectedName else { return }

            guard let url = url, error == nil else {
                self.avatarImageView.image = UIImage(named: "placeholder")
                return
            }

            self.avatarImageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "placeholder")
            )
        }
    }
    
//    func configure(place: PolygonPlaceDetails) {
//        let group = place.dominantGroup
//
//        nameLabel.text = group?.name ?? place.name ?? "Community"
//        descriptionLabel.text = group?.description ?? ""
//
//        if let hexColor = group?.strokeColorHex, !hexColor.isEmpty {
//            avatarImageView.layer.borderColor = UIColor(hexString: hexColor).cgColor
//        } else {
//            avatarImageView.layer.borderColor = UIColor.systemGray4.cgColor
//        }
//
//
//        let imageName = group?.imageName ?? ""
//
//        guard !imageName.isEmpty else {
//            avatarImageView.image = UIImage(named: "placeholder")
//            return
//        }
//
//        let storageRef = Storage.storage().reference(
//            withPath: Constants.GROUP_PHOTO_STORAGE + Utils.getImageUrl200(imageName: imageName)
//        )
//
//        storageRef.downloadURL { [weak self] url, error in
//            guard let self else { return }
//
//            guard let url = url, error == nil else {
//                self.avatarImageView.image = UIImage(named: "placeholder")
//                return
//            }
//
//            self.avatarImageView.sd_setImage(
//                with: url,
//                placeholderImage: UIImage(named: "placeholder")
//            )
//        }
//    }
}
