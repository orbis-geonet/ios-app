//
//  SubscriptionListItemCollectionViewCell.swift
//  Orbis-iOS
//
//  Created by Vikas Sharma on 01/11/22.
//

import UIKit
import SDWebImage

protocol SubscriptionListItemCollectionViewCellDelegate: AnyObject {
    func didTapSignSubscriptionButton(_ cell: SubscriptionListItemCollectionViewCell, quantity: Int)
    func didTapSignUnSubscribeButton(_ cell: SubscriptionListItemCollectionViewCell)
    func didTapEditSubscriptionButton(_ cell: SubscriptionListItemCollectionViewCell)
    func didTapDeleteSubscriptionButton(_ cell: SubscriptionListItemCollectionViewCell)
    func didTapAttachmentButton(_ cell: SubscriptionListItemCollectionViewCell)
}

class SubscriptionListItemCollectionViewCell: UICollectionViewCell {

    // MARK: - Outlets
    @IBOutlet weak var lblSubscriptionName: UILabel?
    @IBOutlet weak var lblSubscriptionDescription: UILabel?
    @IBOutlet weak var lblSubscriptionCurrency: UILabel?
    @IBOutlet weak var lblSubscriptionAmount: UILabel?
    @IBOutlet weak var lblSubscriptionDuration: UILabel?
    @IBOutlet weak var lblSubscriptionAmountSeparator: UILabel?
    @IBOutlet weak var lblSubscriptionAmountExtra: UILabel?
    @IBOutlet weak var tblFeatures: UITableView?
    @IBOutlet weak var btnSign: UIButton?
    @IBOutlet weak var btnEdit: UIButton?
    @IBOutlet weak var btnDelete: UIButton?
    @IBOutlet weak var quantityTitleLabel: UILabel!
    @IBOutlet weak var itemQuantitySv: UIStackView!
    @IBOutlet weak var itemQuantityTf: UITextField!
    @IBOutlet weak var attachmentsSv: UIStackView!
    @IBOutlet weak var attachmentsTitleLabel: UILabel!
    
    //MARK: - Properties
    static let identifier = "subscriptionItemCell"
    static let nibName = "SubscriptionListItemCollectionViewCell"
    
    var viewModel: SubscriptionListItemViewModel! {
        didSet {
            configureCell()
        }
    }

    weak var delegate: SubscriptionListItemCollectionViewCellDelegate?

    //MARK: - Init Methods
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTableView()
        addAttachmentTapAction()
    }
    
    private func setupTableView() {
        tblFeatures?.register(UINib(nibName: SubscriptionDescriptionTextTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: SubscriptionDescriptionTextTableViewCell.identifier)
        tblFeatures?.delegate = self
        tblFeatures?.dataSource = self
        
        itemQuantityTf.delegate = self
        itemQuantityTf.addTarget(self, action: #selector(textFieldDidChangeEditing(_:)), for: .editingChanged)
        
        itemQuantityTf.text = "1"
    }

    //MARK: - Configuration Methods
    private func configureCell() {
        attachmentsTitleLabel.text = AppStrings.Subscription.ListActionText.checkAttachmentText
        quantityTitleLabel.text = AppStrings.Subscription.quantityText
        lblSubscriptionName?.text = viewModel.name
        lblSubscriptionDescription?.text = viewModel.description
        lblSubscriptionAmount?.text = viewModel.price
        lblSubscriptionCurrency?.text = viewModel.currency
        
        attachmentsSv.isHidden = !viewModel.hasAttachments
        
        lblSubscriptionDuration?.text = viewModel.paymentDurationString
        lblSubscriptionDuration?.isHidden = viewModel.paymentDurationString.isEmpty
        lblSubscriptionAmountSeparator?.isHidden = viewModel.paymentDurationString.isEmpty
        
        lblSubscriptionAmountExtra?.text = viewModel.paymentInfoExtra
        lblSubscriptionAmountExtra?.isHidden = viewModel.paymentInfoExtra.isEmpty
        
        btnEdit?.setTitle(AppStrings.Subscription.ListActionText.edit, for: .normal)
        btnDelete?.setTitle(AppStrings.Group.MoreActionTexts.delete, for: .normal)
        
        if viewModel.isMainAdmin == true {
            btnEdit?.superview?.isHidden = false
            btnDelete?.isHidden = false
            btnSign?.superview?.isHidden = true
            itemQuantitySv.isHidden = true
        } else {
            btnSign?.setTitle(AppStrings.Subscription.ListActionText.subscribeText, for: .normal)
            if(viewModel.isSubscriber) {
                btnSign?.setTitle(AppStrings.cancel.capitalized, for: .normal)
            }
            btnEdit?.superview?.isHidden = true
            btnDelete?.isHidden = true
            btnSign?.superview?.isHidden = false
            itemQuantitySv.isHidden = !viewModel.isSubscriptionSinglePurchase
        }
        tblFeatures?.reloadData()
    }
    
    private func addAttachmentTapAction() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapAttachmentRow(_:)))
        attachmentsSv.isUserInteractionEnabled = true
        attachmentsSv.addGestureRecognizer(tapGesture)
    }

    // MARK: - Action Methods
    @IBAction func actionButtonSign(_ sender: UIButton) {
        guard let delegate = delegate else { return }
        self.itemQuantityTf.resignFirstResponder()
        if viewModel.isSubscriber {
            delegate.didTapSignUnSubscribeButton(self)
        } else {
            delegate.didTapSignSubscriptionButton(self, quantity: Int(self.itemQuantityTf.text ?? "") ?? 1)
        }
    }

    @IBAction func actionButtonEdit(_ sender: UIButton) {
        guard let delegate = delegate else { return }
        delegate.didTapEditSubscriptionButton(self)
    }

    @IBAction func actionButtonDelete(_ sender: UIButton) {
        guard let delegate = delegate else { return }
        delegate.didTapDeleteSubscriptionButton(self)
    }
    @IBAction func quantityTfTapped(_ sender: Any) {
        itemQuantityTf.becomeFirstResponder()
    }
    
    @objc private func didTapAttachmentRow(_ gesture: UITapGestureRecognizer) {
        guard let delegate = delegate else { return }
        delegate.didTapAttachmentButton(self)
    }
}

extension SubscriptionListItemCollectionViewCell: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0 }
        return viewModel.benefitsCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SubscriptionDescriptionTextTableViewCell.identifier) as! SubscriptionDescriptionTextTableViewCell
        cell.benefitText = viewModel.benefits[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension SubscriptionListItemCollectionViewCell: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == itemQuantityTf {
            let newString = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
            if(newString.isEmpty) { return true }
            if let numVal = Int(newString) {
                return numVal >= AppValues.Subscription.minQuantity && numVal <= AppValues.Subscription.maxQuantity
            }
            return false
        }
        return true
        
    }
    
    @objc private func textFieldDidChangeEditing(_ textField: UITextField) {
    }
}
