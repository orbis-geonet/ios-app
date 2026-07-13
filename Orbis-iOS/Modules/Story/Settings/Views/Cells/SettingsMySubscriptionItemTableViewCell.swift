//
//  SettingsMySubscriptionItemTableViewCell.swift
//  Orbis-iOS
//
//  Created by Vikas Sharma on 05/11/22.
//

import UIKit

class SettingsMySubscriptionItemTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var codesLabel: UILabel!
    
    @IBAction func cancelTapped(_ sender: Any) {
        onCancelTapped?(self)
    }
    
    var subscriptionModel: GroupConsumedSubscription! {
        didSet {
            updateCellComponents()
        }
    }
    
    private var paymentDurationString: String {
        guard let type = subscriptionModel.type else { return AppStrings.Subscription.durationMonthlyText }
        guard let subscriptionType = GroupSubscriptionType(rawValue: type) else { return AppStrings.Subscription.durationMonthlyText }
        switch subscriptionType {
        case .unlimited:
            guard let interval = subscriptionModel.interval, let subsInterval = GroupSubscriptionPaymentInterval(rawValue: interval) else { return AppStrings.Subscription.durationMonthlyText }
            switch subsInterval {
            case .monthly:
                return AppStrings.Subscription.durationMonthlyText
            case .yearly:
                return AppStrings.Subscription.durationYearlyText
            }
        case .interval:
            return AppStrings.Subscription.durationMonthlyText
        case .oneTime:
            return ""
        }
    }
    
    var subscriptionDescription: String {
        let name = subscriptionModel.name ?? ""
        return "\(name) - \(subscriptionModel.currency?.toCurrencySymbol ?? "")\(subscriptionModel.price?.rounded(toPlaces: 2).formattedWithSeparator(decimalSeparator: ",", groupingSeparator: ".") ?? "")/\(paymentDurationString)"
    }
    
    var onCancelTapped: ((SettingsMySubscriptionItemTableViewCell) -> Void)?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    private func updateCellComponents() {
        nameLabel.text = subscriptionModel.groupName ?? ""
        codesLabel.text = "\(AppStrings.Subscription.codeText): \(subscriptionModel.codes?.first ?? "")" 
        codesLabel.isHidden = (subscriptionModel.codes?.count ?? 0) <= 0
        descriptionLabel.text = subscriptionDescription
        cancelBtn.setTitle(AppStrings.cancel, for: .normal)
    }
}
