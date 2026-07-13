//
//  AddSubscriptionBenefitsTableViewCell.swift
//  Orbis-iOS
//
//  Created by Vikas Sharma on 02/11/22.
//

import UIKit

protocol AddSubscriptionBenefitsTableViewCellDelegate: AnyObject {
    func didTapAddMoreBenefitButton(cell: AddSubscriptionBenefitsTableViewCell)
}

class AddSubscriptionBenefitsTableViewCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var addMoreBtn: UIButton!
    
    //MARK: - Properties
    static let identifier = "addSubscriptionBenefits"
    weak var delegate: AddSubscriptionBenefitsTableViewCellDelegate?

    //MARK: - Init Methods
    override func awakeFromNib() {
        super.awakeFromNib()
        updateStaticTexts()
        addLanguageUpdateObserver()
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

    }
    
    private func addLanguageUpdateObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateLanguage), name: NSNotification.Name(rawValue: AppNotificationKeys.userLanguageDidUpdate), object: nil)
    }
    
    @objc private func didUpdateLanguage(_ notification: NSNotification) {
        updateStaticTexts()
    }
    
    func updateStaticTexts() {
        addMoreBtn.setTitle(AppStrings.Subscription.CreateEditText.addMoreBenefit, for: .normal)
    }

    // MARK: - Action Methods
    @IBAction func actionButtonAddMoreBenefit(_ sender: UIButton) {
        guard let delegate = delegate else { return }
        delegate.didTapAddMoreBenefitButton(cell: self)
    }
}
