//
//  CreateSubscriptionViewController.swift
//  Orbis-iOS
//
//  Created by Vikas Sharma on 01/11/22.
//

import TPKeyboardAvoiding
import UIKit
import KMPlaceholderTextView

class CreateSubscriptionViewController: OrbisLocalizableViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var viewTitleLabel: UILabel!
    @IBOutlet weak var benefitsTitleLabel: UILabel!
    @IBOutlet weak var nextBtn: UIButton!
    
    @IBOutlet weak var txtfldSubscriptionName: UITextField?
    @IBOutlet weak var txtvwDescription: KMPlaceholderTextView?
    @IBOutlet weak var flagCurrency: UIImageView?
    @IBOutlet weak var txtfldPrice: UITextField?
    @IBOutlet weak var lblTaxInfo: UILabel?
    @IBOutlet weak var tblBenefits: TPKeyboardAvoidingTableView?
    @IBOutlet weak var tblBenefitHeightConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var paymentFreqTitleLabel: UILabel!
    @IBOutlet weak var paymentFreqDropDownArrow: UIImageView!
    @IBOutlet weak var paymentFreqSelectorView: RoundedView!
    
    @IBOutlet weak var freqInstallmentTimeSelectorView: RoundedView!
    @IBOutlet weak var selectedPaymentFreqLabel: UILabel!
    @IBOutlet weak var freqInstallmentTimeTf: UITextField!
    @IBOutlet weak var paymentFreqDropDownBtn: UIButton!
    @IBOutlet weak var freqInstallmentTimeTfBtn: UIButton!
    @IBOutlet weak var attachmentTitleLabel: UILabel!
    @IBOutlet weak var attachmentPlusBtn: UIButton!
    @IBOutlet weak var attachmentContentView: UIView!
    @IBOutlet weak var attachmentCollectionView: UICollectionView!
    @IBOutlet weak var attachmentPageControl: UIPageControl!
    
    // MARK: - Action Methods
    
    @IBAction func actionButtonBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func addAttachmentTapped(_ sender: Any) {
        openImagePickerView()
    }
    
    @IBAction func actionButtonCurrency(_ sender: UIButton) {
        return
        //        let actionSheetVC = UIAlertController(title: AppStrings.Subscription.selectCurrency, message: nil, preferredStyle: .actionSheet)
        //        let usdAction = UIAlertAction(title: OrbisCurrency.USD.rawValue, style: .default) { [weak self] action in
        //            self?.flagCurrency?.image = UIImage(named: "icFlagUSA")
        //        }
        //
        //        let brlAction = UIAlertAction(title: OrbisCurrency.BRL.rawValue, style: .default) { [weak self] action in
        //            self?.flagCurrency?.image = UIImage(named: "icFlagBrazil")
        //        }
        //
        //        actionSheetVC.addAction(usdAction)
        //        actionSheetVC.addAction(brlAction)
        //        self.present(actionSheetVC, animated: true, completion: nil)
    }
    
    @IBAction func actionButtonNext(_ sender: UIButton) {
        tryProceedSubscriptionCreation()
    }
    
    @IBAction func selectPaymentFrequencyTapped(_ sender: Any) {
        let location = paymentFreqSelectorView.convert(paymentFreqSelectorView.bounds.origin, to: self.view)
        showPaymentDropDownView(inLocation: location, tappedViewFrame: paymentFreqSelectorView.bounds, leftConstraintVal: 15.toCGFloat.relativeToIphone8Width(), rightConstraintValue: 15.toCGFloat.relativeToIphone8Width())
    }
    
    @IBAction func selectInstallmentTimeTapped(_ sender: Any) {
        freqInstallmentTimeTf.becomeFirstResponder()
    }
    
    @IBAction func attachmentPageControlValueChanged(_ sender: Any) {
        guard attachmentPageControl != nil else { return }
        guard isAttachmentPageControlTap else { return }
        isAttachmentPageControlTap = false
        let currentPage = attachmentPageControl.currentPage
        let pageWidth = self.attachmentCollectionView.frame.size.width
        let scrollTo = CGPoint(x: pageWidth * currentPage.toCGFloat, y: 0)
        attachmentCollectionView.setContentOffset(scrollTo, animated: true)
    }
    
    // MARK: - Properties
    var viewModel: SubscriptionCreateEditViewModel!
    
    weak var paymentFrequencySelectorView: DropDownOptionListView?
    
    var subscriptionCreated: ((_ status: Bool) -> Void)?
    
    var config: YPImagePickerConfiguration!
    var imagePickerController: YPImagePicker!
    
    var isAttachmentPageControlTap = true
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextFields()
        setupAttachmentCollectionView()
        updateStaticTexts()
        self.flagCurrency?.image = UIImage(named: "icFlagBrazil")
        tblBenefits?.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        fetchFeeCommision()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if(keyPath == "contentSize") {
            if let newvalue = change?[.newKey] {
                if let newsize = newvalue as? CGSize {
                    tblBenefitHeightConstraint?.constant = newsize.height
                }
            }
        }
    }
    
    deinit {
        tblBenefits?.removeObserver(self, forKeyPath: "contentSize")
    }
    
    private func configureTextFields() {
        txtfldSubscriptionName?.text = viewModel.name
        txtvwDescription?.text = viewModel.description
        
        txtfldPrice?.delegate = self
        txtvwDescription?.delegate = self
        
        txtfldPrice?.addTarget(self, action: #selector(textFieldDidChangeEditing(_:)), for: .editingChanged)
        txtfldSubscriptionName?.addTarget(self, action: #selector(textFieldDidChangeEditing(_:)), for: .editingChanged)
        txtfldPrice?.text = "\(viewModel.originalPrice.rounded(toPlaces: 2))"
        
        freqInstallmentTimeTf.delegate = self
        freqInstallmentTimeTf.addTarget(self, action: #selector(textFieldDidChangeEditing(_:)), for: .editingChanged)
        
        freqInstallmentTimeTf.isUserInteractionEnabled = !viewModel.isEditMode
        freqInstallmentTimeTfBtn.isUserInteractionEnabled = !viewModel.isEditMode
        paymentFreqDropDownBtn.isUserInteractionEnabled = !viewModel.isEditMode
        
        updatePaymentFrequencyUI()
        updateAttachmentUI()
        
        tblBenefits?.reloadData()
    }
    
    func setupAttachmentCollectionView() {
        attachmentCollectionView.register(UINib(nibName: SubscriptionAttachmentItemCell.nibName, bundle: nil), forCellWithReuseIdentifier: SubscriptionAttachmentItemCell.identifier)
        
        attachmentCollectionView.delegate = self
        attachmentCollectionView.dataSource = self
    }
    
    override func updateStaticTexts() {
        viewTitleLabel.text = viewModel.viewTitle
        benefitsTitleLabel.text = AppStrings.Subscription.CreateEditText.benefitsTitle
        nextBtn.setTitle(viewModel.viewTitle, for: .normal)
        txtfldSubscriptionName?.placeholder = AppStrings.Subscription.CreateEditText.PlaceholderTexts.subscriptionNamePlaceholder
        txtvwDescription?.placeholder = AppStrings.Subscription.CreateEditText.PlaceholderTexts.subscriptionDescriptionPlaceholder
        txtfldPrice?.placeholder = AppStrings.Subscription.CreateEditText.PlaceholderTexts.subscriptionPricePlaceholder
        attachmentTitleLabel.text = AppStrings.Subscription.CreateEditText.photosTitle
        paymentFreqTitleLabel.text = AppStrings.Subscription.CreateEditText.paymentFrequencyTitle
    }
    
    // MARK: - Helper Methods
    private func updateTaxLabel(withPrice price: Double?) {
        viewModel.originalPrice = price ?? 0.0
        lblTaxInfo?.text = viewModel.priceWithTaxString
    }
    
    private func updatePaymentFrequencyUI() {
        selectedPaymentFreqLabel.text = viewModel.selectedPaymentFrequencyText
        selectedPaymentFreqLabel.textColor = viewModel.selectedPaymentFrequencyTextColor
        
        freqInstallmentTimeSelectorView.isHidden = viewModel.currentPaymentFrequency != .installment
        
        freqInstallmentTimeTf.text = viewModel.installmentPeriodText
    }
    
    func openImagePickerView() {
        setupImagePickerView()
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    private func setupImagePickerView() {
        config = YPImagePicker.getAppImageViewConfig(allowMultiSelect: true, allowsCrop: false, onStartScreen: .photo)
        config.library.defaultMultipleSelection = true
        config.library.preSelectItemOnMultipleSelection = false
        config.library.preselectedItems = viewModel.ypMediaItems
        imagePickerController = YPImagePicker(configuration: config)
        imagePickerController.didFinishPicking { [weak self] (items, canceled) in
            guard let strongSelf = self else {
                self?.imagePickerController.dismiss(animated: true, completion: nil)
                return
            }
            guard !canceled else {
                self?.imagePickerController.dismiss(animated: true, completion: nil)
                return
            }
            var ypMediaItems = [YPMediaItem]()
            var images = [UIImage]()
            var imagesData = [Data]()
            for item in items {
                switch item {
                case .photo(let photo):
                    let data = photo.image.UIImageToDataJPEG2(compressionRatio: 1)!
                    guard data.count <= AppValues.Subscription.maxImageSize else {
                        self?.showToastMessage(message: "One or more image size invalid.")
                        return
                    }
                    ypMediaItems.append(item)
                    images.append(photo.image.resizeImage(targetSize: CGSize(width: 800, height: 800)))
                    imagesData.append(data)
                default:
                    break
                }
            }
            strongSelf.viewModel.ypMediaItems = ypMediaItems
            strongSelf.viewModel.attachmentLocalImages = images
            strongSelf.updateAttachmentUI()
            strongSelf.attachmentPageControl.currentPage = 0
            strongSelf.attachmentPageControlValueChanged(strongSelf.attachmentPageControl ?? UIPageControl())
            self?.imagePickerController.dismiss(animated: true, completion: nil)
        }
    }
    
    private func updateAttachmentUI() {
        self.attachmentCollectionView.reloadData()
        self.attachmentContentView.isHidden = viewModel.attachmentImagesCount <= 0
    }
    
    //MARK: - View Model Methods
    
    private func fetchFeeCommision() {
        self.showOrbisLoader()
        viewModel.fetchCommissionInfo { [weak self] result, error in
            if let error = error {
                self?.handleError(error: error)
            }
            self?.updateTaxLabel(withPrice: self?.viewModel.originalPrice ?? 0.0)
            self?.hideOrbisLoader()
        }
    }
    
    private func tryProceedSubscriptionCreation() {
        self.showOrbisLoader()
        viewModel.checkValidationAndProceedStripe { [weak self] result, error in
            guard let self = self else { return }
            if let error = error as? ValidationErrors {
                self.hideOrbisLoader()
                self.handleError(error: error)
            } else if let error = error as? GenericError, error.code == 404 {
                self.viewModel.createStripeAccount { result1, error1 in
                    if let response = result1 as? StripeAccountCreateResponse, let url = response.setupAccountUrl, !url.isEmpty {
                        self.tryOpenLink(urlString: url)
                        self.hideOrbisLoader()
                    } else {
                        self.hideOrbisLoader()
                        self.handleError(error: error1 ?? CommonError.invalidDataFormat)
                    }
                }
            } else if let status = result as? StripeAccountStatusModel {
                if((status.accountStatus == .created || status.accountStatus == .validationFailed)) {
                    self.viewModel.updateStripeAccount { result2, error2 in
                        if let response = result2 as? StripeAccountCreateResponse, let url = response.setupAccountUrl, !url.isEmpty {
                            self.tryOpenLink(urlString: url)
                            self.hideOrbisLoader()
                        } else {
                            self.hideOrbisLoader()
                            self.handleError(error: error2 ?? CommonError.invalidDataFormat)
                        }
                    }
                } else if(status.accountStatus == .readyToUse) {
                    self.proceedSubscriptionCreation()
                } else {
                    self.handleError(error: error ?? CommonError.invalidDataFormat)
                    self.hideOrbisLoader()
                }
                
            } else {
                self.handleError(error: error ?? CommonError.invalidDataFormat)
                self.hideOrbisLoader()
            }
        }
    }
    
    private func proceedSubscriptionCreation() {
        viewModel.proceedSubscriptionCreation { [weak self] result, error in
            if let error = error {
                self?.hideOrbisLoader()
                self?.handleError(error: error)
            } else {
                self?.subscriptionCreated?(true)
                self?.navigationController?.popViewController(animated: true)
            }
        }
        
    }
    
    func tryOpenLink(urlString: String) {
        let application = UIApplication.shared
        application.open(URL(string: urlString)!, options: [:]) { (success) in
            if success {
                return
            }
        }
    }
    
    private func tryRemoveSubscriptionImage(at index: Int) {
        if viewModel.removeSubscriptionImage(at: index) {
            updateAttachmentUI()
        }
    }
    
}

extension CreateSubscriptionViewController {
    
    private func removePaymentFrequencyDropDownView() {
        paymentFrequencySelectorView?.removeFromSuperview()
        paymentFrequencySelectorView = nil
        UIView.animate(withDuration: 0.15) {
            [weak self] in
            self?.paymentFreqDropDownArrow.transform = CGAffineTransform(rotationAngle: 0.toCGFloat.deg2rad)
        } completion: { (true) in
        }
    }
    
    private func showPaymentDropDownView(inLocation point: CGPoint, tappedViewFrame: CGRect, leftConstraintVal: CGFloat, rightConstraintValue: CGFloat) {
        self.view.endEditing(true)
        removePaymentFrequencyDropDownView()
        let listView = DropDownOptionListView(frame: self.view.bounds)
        listView.viewModel = DropDownOptionListViewModel(options: viewModel.availablePaymentFrequencies)
        listView.actionBtnContainer.alpha = 0
        self.view.addSubview(listView)
        listView.translatesAutoresizingMaskIntoConstraints = false
        listView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        listView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        listView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        listView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.view.bringSubviewToFront(listView)
        let originY = point.y + tappedViewFrame.height - 5.toCGFloat.relativeToIphone8Width() - (self.view.safeAreaInsets.top)
        listView.btnTopConstraint.constant = originY
        listView.btnLeadingConstraint.constant = leftConstraintVal
        listView.btnTrailingConstraint.constant = rightConstraintValue
        listView.actionBtnContainer.autoresizesSubviews = true
        listView.optionsListTableView.reloadData()
        listView.updateListSize()
        listView.layoutIfNeeded()
        listView.actionBtnContainer.isHidden = false
        self.paymentFrequencySelectorView = listView
        self.paymentFrequencySelectorView?.onOutsideViewTapped = {
            [weak self] in
            self?.removePaymentFrequencyDropDownView()
        }
        self.paymentFrequencySelectorView?.onOptionSelected = {
            [weak self] option in
            self?.removePaymentFrequencyDropDownView()
            self?.updatePaymentFrequencySelection(option: option)
        }
        UIView.animate(withDuration: 0.15) {
            [weak self] in
            self?.paymentFrequencySelectorView?.actionBtnContainer.alpha = 1
            self?.paymentFreqDropDownArrow.transform = CGAffineTransform(rotationAngle: 180.toCGFloat.deg2rad)
        } completion: { (true) in
        }
    }
    
    private func updatePaymentFrequencySelection(option: DropDownOptionItem) {
        if viewModel.updatePaymentFrequency(option: option) {
            updatePaymentFrequencyUI()
        }
    }
    
}

extension CreateSubscriptionViewController: UITextFieldDelegate, UITextViewDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == txtfldPrice {
            var replacementString = string
            if string == "," {
                replacementString = "."
                let newString = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: replacementString)
                if Double(newString) != nil {
                    textField.text = newString
                }
                return false
            }
            let newString = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: replacementString)
            if(newString.isEmpty) { return true }
            return Double(newString) != nil
        } else if textField == freqInstallmentTimeTf {
            let newString = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
            if(newString.isEmpty) { return true }
            if let numVal = Int(newString) {
                return numVal >= 0 && numVal <= AppValues.Subscription.installmentMaxPeriod
            }
            return false
        }
        return true
        
    }
    
    @objc private func textFieldDidChangeEditing(_ textField: UITextField) {
        switch textField {
        case txtfldPrice:
            self.updateTaxLabel(withPrice: Double(textField.text ?? ""))
            break
        case txtfldSubscriptionName:
            self.viewModel.name = textField.text ?? ""
            break
        case freqInstallmentTimeTf:
            self.viewModel.installmentPeriod = Int(textField.text ?? "")
            break
        default:
            break
        }
        
    }
    
    func textViewDidChange(_ textView: UITextView) {
        guard textView == self.txtvwDescription else { return }
        viewModel.description = textView.text
    }
}

extension CreateSubscriptionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0 }
        return viewModel.benefit.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == viewModel.benefit.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: AddSubscriptionBenefitsTableViewCell.identifier) as! AddSubscriptionBenefitsTableViewCell
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: SubscriptionBenefitsTableViewCell.identifier) as! SubscriptionBenefitsTableViewCell
            cell.benefitDefaultDescription = viewModel.benefit[indexPath.row]
            cell.delegate = self
            return cell
        }
    }
}

extension CreateSubscriptionViewController: SubscriptionBenefitsTableViewCellDelegate {
    func didChangeBenefitText(cell: SubscriptionBenefitsTableViewCell, text: String) {
        guard let indexPath = tblBenefits?.indexPath(for: cell) else { return }
        viewModel.updateBenefit(at: indexPath.row, with: text)
    }
    
    func didTapRemoveBenefitButton(cell: SubscriptionBenefitsTableViewCell) {
        guard let indexPath = tblBenefits?.indexPath(for: cell) else { return }
        showConfirmationAlert(title: "", message: AppStrings.Subscription.deleteBenefitConfirmationMessage, okBtnTitle: AppStrings.yes, cancelBtnTitle: AppStrings.no) { [weak self] success in
            if success {
                self?.viewModel.removeBenefit(at: indexPath.row)
                self?.tblBenefits?.reloadData()
            }
        }
    }
}

extension CreateSubscriptionViewController: AddSubscriptionBenefitsTableViewCellDelegate {
    func didTapAddMoreBenefitButton(cell: AddSubscriptionBenefitsTableViewCell) {
        guard let _ = tblBenefits?.indexPath(for: cell) else { return }
        viewModel.addBenefit()
        tblBenefits?.reloadData()
    }
}

extension CreateSubscriptionViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard viewModel != nil else {
            return 0
        }
        let count = viewModel.attachmentImagesCount
        attachmentPageControl.numberOfPages = count
        attachmentPageControl.currentPage = 0
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SubscriptionAttachmentItemCell.identifier, for: indexPath) as! SubscriptionAttachmentItemCell
        cell.model = viewModel.getSubscriptionImage(at: indexPath.row)
        cell.onRemoveTapped = {
            [weak self] cell in
            guard let indexPath = collectionView.indexPath(for: cell) else { return }
            self?.tryRemoveSubscriptionImage(at: indexPath.row)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width:collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}

extension CreateSubscriptionViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == attachmentCollectionView else { return }
        guard isAttachmentPageControlTap else { return }
        let witdh = scrollView.frame.width - (scrollView.contentInset.left*2)
        let index = scrollView.contentOffset.x / witdh
        let roundedIndex = round(index)
        self.attachmentPageControl.currentPage = Int(roundedIndex)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == attachmentCollectionView else { return }
        attachmentPageControl?.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        isAttachmentPageControlTap = true
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView == attachmentCollectionView else { return }
        attachmentPageControl?.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        isAttachmentPageControlTap = true
    }
}
