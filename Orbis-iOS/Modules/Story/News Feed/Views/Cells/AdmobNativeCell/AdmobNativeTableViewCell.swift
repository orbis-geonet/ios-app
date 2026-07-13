//
//  AdmobNativeTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 07/09/2021.
//

import UIKit
import GoogleMobileAds

class AdmobNativeTableViewCell: UITableViewCell {

    @IBOutlet weak var adView: NativeAdView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func fill(adMob: NativeAd) {
        adView.nativeAd = adMob
        
        (adView.headlineView as? UILabel)?.text = adMob.headline
        (adView.priceView as? UILabel)?.text = adMob.price
        (adView.bodyView as? UILabel)?.text = adMob.body
        (adView.advertiserView as? UILabel)?.text = adMob.advertiser
        (adView.callToActionView as? UIButton)?.isUserInteractionEnabled = false
        (adView.callToActionView as? UIButton)?.setTitle(adMob.callToAction?.uppercased(), for: .normal)
        (adView.iconView as? UIImageView)?.image = adMob.icon?.image
        (adView.priceView as? UILabel)?.text = adMob.price
        (adView.storeView as? UILabel)?.text = adMob.store
        (adView.mediaView)?.mediaContent = adMob.mediaContent
        
        if let starRating = adMob.starRating {
            (adView.starRatingView as? UILabel)?.text = starRating.description + "\u{2605}"
        } else {
            (adView.starRatingView as? UILabel)?.text = nil
        }
    }
    
}
