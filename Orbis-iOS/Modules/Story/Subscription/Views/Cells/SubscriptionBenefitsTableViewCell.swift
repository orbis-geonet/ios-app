//
//  SubscriptionBenefitsTableViewCell.swift
//  Orbis-iOS
//
//  Created by Vikas Sharma on 02/11/22.
//

import UIKit

protocol SubscriptionBenefitsTableViewCellDelegate: AnyObject {
    func didTapRemoveBenefitButton(cell: SubscriptionBenefitsTableViewCell)
    func didChangeBenefitText(cell: SubscriptionBenefitsTableViewCell, text: String)
}

class SubscriptionBenefitsTableViewCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var txtfldBenefit: UITextField?
    @IBOutlet weak var btnRemoveHeightConstraint: NSLayoutConstraint?

    //MARK: - Properties
    static let identifier = "subscriptionBenefits"
    weak var delegate: SubscriptionBenefitsTableViewCellDelegate?
    
    var benefitDefaultDescription: String = "" {
        didSet {
            txtfldBenefit?.text = benefitDefaultDescription
        }
    }

    //MARK: - Init Methods
    override func awakeFromNib() {
        super.awakeFromNib()
        configureCell()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    //MARK: - Configuration Methods
    private func configureCell() {
        updateStaticTexts()
        txtfldBenefit?.addTarget(self, action: #selector(textFieldDidChangeText(_:)), for: .editingChanged)
    }
    
    @objc private func textFieldDidChangeText(_ sender: UITextField) {
        guard let delegate = delegate else { return }
        delegate.didChangeBenefitText(cell: self, text: sender.text ?? "")
    }
    
    private func addLanguageUpdateObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateLanguage), name: NSNotification.Name(rawValue: AppNotificationKeys.userLanguageDidUpdate), object: nil)
    }
    
    @objc private func didUpdateLanguage(_ notification: NSNotification) {
        updateStaticTexts()
    }
    
    func updateStaticTexts() {
        txtfldBenefit?.placeholder = AppStrings.Subscription.CreateEditText.PlaceholderTexts.subscriptionBenefitPlaceholder
    }

    // MARK: - Action Methods
    @IBAction func actionButtonRemoveBenefit(_ sender: UIButton) {
        guard let delegate = delegate else { return }
        delegate.didTapRemoveBenefitButton(cell: self)
    }
}
