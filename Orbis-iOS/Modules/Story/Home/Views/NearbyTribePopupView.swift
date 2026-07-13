//
//  NearbyTribePopupView.swift
//  Orbis-iOS
//
//  Created by Zohaib Ahmad on 03/06/2026.
//

import UIKit

final class NearbyTribePopupView: UIView {
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var totalMembersCount: UILabel!
    
    @IBOutlet weak var firstMemberAvatar: UIImageView!
    
    @IBOutlet weak var secondMemberAvatar: UIImageView!
    @IBOutlet weak var thirdMemberAvatar: UIImageView!
    
    @IBOutlet weak var firstMemberView: RoundedView!
    
    @IBOutlet weak var secondMemberView: RoundedView!
    
    @IBOutlet weak var thirdMemberView: RoundedView!
    
    private var currentBorderColor: UIColor?
    
    
    var onTap: (() -> Void)?

    static func loadFromNib() -> NearbyTribePopupView {
        let nib = UINib(nibName: "NearbyTribePopupView", bundle: nil)
        return nib.instantiate(withOwner: nil, options: nil).first as! NearbyTribePopupView
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()

        containerView.layer.cornerRadius = 18
        containerView.layer.borderWidth = 2
        containerView.clipsToBounds = true

        [firstMemberView, secondMemberView, thirdMemberView].forEach {
            $0?.clipsToBounds = true
            $0?.layer.masksToBounds = true
        }

        [firstMemberAvatar, secondMemberAvatar, thirdMemberAvatar].forEach {
            $0?.clipsToBounds = true
            $0?.layer.masksToBounds = true
            $0?.contentMode = .scaleAspectFill
        }

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 6)

        let tap = UITapGestureRecognizer(target: self, action: #selector(popupTapped))
        addGestureRecognizer(tap)
    }

    
    // Full render from the already-loaded place — name, description, count and border need no
    // network. The fetch that follows only refreshes these and fills the member avatars in.
    func configure(place: PolygonPlaceDetails) {
        let tribeName = place.dominantGroup?.name ?? "Unknown Tribe"
        let description = place.dominantGroup?.description ?? place.name ?? ""

        titleLabel.text = tribeName
        descriptionLabel.text = description
        totalMembersCount.text = "\(place.dominantGroup?.membersCount ?? 0) Members"

        // strokeColorHex first — Android getPlaceColor parity (same choice showLoading made).
        applyBorderColor(place.dominantGroup?.strokeColorHex ?? place.dominantGroup?.solidColorHex)

        // Placeholder avatars while the member fetch is in flight — hidden avatars read as
        // "members never loaded" whenever the fetch is slow or fails mid-pan. configure(data:)
        // replaces these with real images and hides any the tribe doesn't fill.
        [firstMemberAvatar, secondMemberAvatar, thirdMemberAvatar].forEach {
            $0?.isHidden = false
            $0?.image = UIImage(systemName: "person.crop.circle.fill")
            $0?.tintColor = .systemGray3
        }
    }

    func configure(data: NearbyTribePopupData, onAvatarsLoaded: (() -> Void)? = nil) {
        titleLabel.text = data.group.name
        descriptionLabel.text = data.group.description
        totalMembersCount.text = "\(data.group.membersCount ?? 0) Members"

        applyBorderColor(data.group.strokeColorHex)

        let avatarViews = [
            firstMemberAvatar,
            secondMemberAvatar,
            thirdMemberAvatar
        ]

        // Report when ALL visible avatars have settled, so the marker's tracksViewChanges freeze can
        // wait for the real decode instead of a fixed timer (Android onAvatarProcessed parity).
        let expected = min(avatarViews.count, data.memberImageUrls.count)
        guard expected > 0 else {
            for imageView in avatarViews { imageView?.isHidden = true }
            onAvatarsLoaded?()
            return
        }
        var done = 0
        let onOne = {
            done += 1
            if done == expected { onAvatarsLoaded?() }
        }

        for (index, imageView) in avatarViews.enumerated() {
            guard index < data.memberImageUrls.count else {
                imageView?.isHidden = true
                continue
            }

            imageView?.isHidden = false
            imageView?.setSDWebImage(
                urlString: data.memberImageUrls[index],
                placeholderImage: UIImage(systemName: "person.crop.circle.fill"),
                storageDirectory: .profilePictures,
                sizeModifier: .fourHundred,
                completion: { onOne() }
            )
        }
    }
    
    private func applyBorderColor(_ hex: String?) {
        // CYAN fallback (matches Android getPlaceColor's `?: Color.CYAN`) so the border is never
        // an invisible/wrong black when a tribe lacks a color hex.
        let color = UIColor(hexString: hex ?? "#00FFFF")
        currentBorderColor = color
        containerView.layer.borderColor = color.cgColor
    }

    

    @objc private func popupTapped() {
        onTap?()
    }
}
