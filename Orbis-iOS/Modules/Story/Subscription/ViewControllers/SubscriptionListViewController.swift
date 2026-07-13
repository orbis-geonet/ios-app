//
//  SubscriptionListViewController.swift
//  Orbis-iOS
//
//  Created by Vikas Sharma on 01/11/22.
//

import UIKit
import StripePaymentSheet

class SubscriptionListViewController: OrbisLocalizableViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var viewTitleLabel: UILabel!
    @IBOutlet weak var viewAddSubscription: UIView?
    @IBOutlet weak var collectionSubscription: UICollectionView?
    @IBOutlet weak var pageControl: UIPageControl?
    
    // MARK: - Properties
    var viewModel: SubscriptionListViewModel!
    var isLoading = false
    
    var paymentSheet: PaymentSheet?
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupCollectionView()
        handleViewModelActionHandlers()
        updateStaticTexts()
        resetData()
        loadData()
        viewAddSubscription?.isHidden = !viewModel.isMainAdmin
    }
    
    override func updateStaticTexts() {
        viewTitleLabel.text = AppStrings.Subscription.ListActionText.subscriptionsTitle
    }
    
    private func setupCollectionView() {
        collectionSubscription?.register(UINib(nibName: SubscriptionListItemCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: SubscriptionListItemCollectionViewCell.identifier)
        collectionSubscription?.delegate = self
        collectionSubscription?.dataSource = self
    }
    
    private func handleViewModelActionHandlers() {
        viewModel.onGroupSubscriptionsFetched = { [weak self] in
            self?.hideOrbisLoader()
            DispatchQueue.main.async { [weak self] in
                self?.setupPageControl()
                self?.view.layoutIfNeeded()
                self?.collectionSubscription?.reloadData()
            }
            self?.isLoading = false
        }
        viewModel.onGroupSubscriptionsFetchedCompletePagination = { [weak self] in
            self?.hideOrbisLoader()
            DispatchQueue.main.async { [weak self] in
                self?.setupPageControl()
                self?.view.layoutIfNeeded()
                self?.collectionSubscription?.reloadData()
            }
            self?.isLoading = false
        }
        viewModel.onGroupSubscriptionsFetchError = { [weak self] (error) in
            self?.hideOrbisLoader()
            self?.handleError(error: error)
            self?.isLoading = false
        }
    }
    
    // MARK: - Page Control
    private func setupPageControl() {
        pageControl?.numberOfPages = viewModel.count
        UIPageControl.appearance().backgroundColor = .clear
    }
    
    // MARK: - Action Methods
    @IBAction func actionButtonBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionButtonAddSubscription(_ sender: UIButton) {
        let createSubscriptionVC = UIStoryboard.getViewController(inStoryboard: "Subscription", identifier: "createSubscriptionVC") as! CreateSubscriptionViewController
        createSubscriptionVC.subscriptionCreated = { [weak self] success in
            if (success) {
                self?.viewModel.initializePagination(clearItems: false)
                self?.loadData()
            }
        }
        createSubscriptionVC.viewModel = SubscriptionCreateEditViewModel(groupKey: self.viewModel.groupKey)
        self.navigationController?.pushViewController(createSubscriptionVC, animated: true)
    }
    
    // MARK: - View Action Methods
    
    var shouldShowWhiteLoader: Bool {
        guard let cv = collectionSubscription else { return false }
        guard cv.numberOfSections > 0 && cv.numberOfItems(inSection: 0) > 0 else { return false }
        return true
    }
    
    func resetData() {
        viewModel.initializePagination()
        isLoading = false
        DispatchQueue.main.async { [weak self] in
            self?.setupPageControl()
            self?.view.layoutIfNeeded()
            self?.collectionSubscription?.reloadData()
        }
    }
    
    func loadData() {
        isLoading = true
        self.showOrbisLoader(isWhiteLoader: shouldShowWhiteLoader)
        viewModel.loadGroupSubscriptions()
    }
    
    func loadMore() {
        isLoading = true
        self.showOrbisLoader(isWhiteLoader: shouldShowWhiteLoader)
        viewModel.loadMoreGroupSubscriptions()
    }
    
    func tryDeleteSubscription(at index: Int) {
        self.showOrbisLoader(isWhiteLoader: shouldShowWhiteLoader)
        viewModel.tryDeleteSubscription(at: index) { [weak self] result, error in
            if let error = error {
                self?.handleError(error: error)
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.setupPageControl()
                    self?.view.layoutIfNeeded()
                    self?.collectionSubscription?.reloadData()
                }
            }
            self?.hideOrbisLoader()
        }
    }
    
    // MARK: - Consumer POV Actions
    
    private func updateSubscriptionStatus(forSubscription key: String, isSubscriber: Bool) {
        viewModel.updateSubscriptionStatus(key: key, isSubscriber: isSubscriber)
        self.collectionSubscription?.reloadData()
    }
    
    private func proceedCancelSubscription(at index: Int) {
        guard let key = viewModel.getGroupSubscriptionItem(at: index).subscriptionKey else { return }
        self.showOrbisLoader(disableUserInteraction: true, isWhiteLoader: shouldShowWhiteLoader)
        viewModel.cancelSubscription(forSubscription: key) { [weak self] result, error in
            self?.hideOrbisLoader()
            if let error = error {
                self?.handleError(error: error)
            } else {
                self?.updateSubscriptionStatus(forSubscription: key, isSubscriber: false)
            }
        }
    }
    
    private func presentPaymentSheet(forSubscription key: String, publishableKey: String, paymentIntentClientSecret: String) {
        // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
        STPAPIClient.shared.publishableKey = publishableKey
        
        // MARK: Create a PaymentSheet instance
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = AppStrings.appName
        configuration.applePay = .init(
            merchantId: APPKeys.applePayMerchantId, merchantCountryCode: "US")
        //        configuration.returnURL = "payments-example://stripe-redirect"
        self.paymentSheet = PaymentSheet(
            paymentIntentClientSecret: paymentIntentClientSecret,
            configuration: configuration)
        showPaymentSheet(forSubscription: key)
    }
    
    private func showPaymentSheet(forSubscription key: String) {
        paymentSheet?.present(from: self) { [weak self] paymentResult in
            guard let self = self else { return }
            // MARK: Handle the payment result
            switch paymentResult {
            case .completed:
                if self.viewModel.isSubscriptionSinglePurchase(key: key) {
                    UIUtil.showGlobalToast(message: AppStrings.Subscription.subscriptionSuccessMessage)
                    self.collectionSubscription?.reloadData()
                } else {
                    self.updateSubscriptionStatus(forSubscription: key, isSubscriber: true)
                    UIUtil.showGlobalToast(message: AppStrings.Subscription.subscriptionSuccessMessage)
                }
            case .canceled:
                print("Canceled!")
            case .failed(let error):
                print(error)
                self.handleError(error: error)
            }
        }
    }
    
    private func tryFetchStripeTokenAndProceed(forSubscription key: String, quantity: Int = 1) {
        self.showOrbisLoader(disableUserInteraction: true, isWhiteLoader: shouldShowWhiteLoader)
        if self.viewModel.isSubscriptionSinglePurchase(key: key) {
            viewModel.getStripeTokenFromServer(forPurchase: key, quantity: quantity) { [weak self] result, error in
                if let tokenModel = result as? OrbisStripeTokenModel {
                    self?.presentPaymentSheet(forSubscription: key, publishableKey: tokenModel.publicToken ?? "", paymentIntentClientSecret: tokenModel.clientSecret ?? "")
                } else {
                    self?.handleError(error: error ?? CommonError.invalidDataFormat)
                }
                self?.hideOrbisLoader()
            }
        } else {
            viewModel.getStripeTokenFromServer(forSubscription: key) { [weak self] result, error in
                if let tokenModel = result as? OrbisStripeTokenModel {
                    self?.presentPaymentSheet(forSubscription: key, publishableKey: tokenModel.publicToken ?? "", paymentIntentClientSecret: tokenModel.clientSecret ?? "")
                } else {
                    self?.handleError(error: error ?? CommonError.invalidDataFormat)
                }
                self?.hideOrbisLoader()
            }
        }
    }
    
    private func showAttachmentSlideShow(at index: Int) {
        let model = viewModel.getGroupSubscriptionItem(at: index)
        guard let imageNames = model.imagesName, imageNames.count > 0 else { return }
        let vc = UIStoryboard.getViewController(inStoryboard: "Subscription", identifier: "subscriptionAttachmentSlideshowVC") as! SubscriptionAttachmentSlideShowVC
        vc.modalPresentationStyle = .overFullScreen
        vc.imageNames = imageNames
        presentPanModal(vc)
    }
}

extension SubscriptionListViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0 }
        return viewModel.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SubscriptionListItemCollectionViewCell.identifier, for: indexPath) as! SubscriptionListItemCollectionViewCell
        cell.viewModel = SubscriptionListItemViewModel(model: viewModel.getGroupSubscriptionItem(at: indexPath.row), group: viewModel.groupModel)
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.frame.height
        print("Height of frame = \(height)")
        return CGSize(width: collectionView.frame.width, height: height)
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
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.row == viewModel.count - 1 else { return }
        if(isLoading && !viewModel.hasItemsLastPageReached) {
            loadMore()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offSet = scrollView.contentOffset.x
        let width = scrollView.frame.width
        let horizontalCenter = width / 2
        let newPage = Int(offSet + horizontalCenter) / Int(width)
        pageControl?.currentPage = newPage
    }
}

extension SubscriptionListViewController: SubscriptionListItemCollectionViewCellDelegate {
    func didTapSignUnSubscribeButton(_ cell: SubscriptionListItemCollectionViewCell) {
        guard let indexPath = self.collectionSubscription?.indexPath(for: cell) else { return }
        showConfirmationAlert(title: "", message: AppStrings.Subscription.unsubscribeConfirmationMessage, okBtnTitle: AppStrings.yes, cancelBtnTitle: AppStrings.no) { [weak self] success in
            if success {
                self?.proceedCancelSubscription(at: indexPath.row)
            }
        }
    }
    
    func didTapSignSubscriptionButton(_ cell: SubscriptionListItemCollectionViewCell, quantity: Int) {
        guard let indexPath = self.collectionSubscription?.indexPath(for: cell) else { return }
        let subscriptionModel = viewModel.getGroupSubscriptionItem(at: indexPath.row)
        guard let key = subscriptionModel.subscriptionKey else { return }
        tryFetchStripeTokenAndProceed(forSubscription: key, quantity: quantity)
    }
    
    func didTapEditSubscriptionButton(_ cell: SubscriptionListItemCollectionViewCell) {
        guard let indexPath = self.collectionSubscription?.indexPath(for: cell) else { return }
        let createSubscriptionVC = UIStoryboard.getViewController(inStoryboard: "Subscription", identifier: "createSubscriptionVC") as! CreateSubscriptionViewController
        createSubscriptionVC.viewModel = SubscriptionCreateEditViewModel(groupKey: viewModel.groupKey, model: viewModel.getGroupSubscriptionItem(at: indexPath.row))
        createSubscriptionVC.subscriptionCreated = { [weak self] success in
            if (success) {
                self?.viewModel.initializePagination(clearItems: false)
                self?.loadData()
            }
        }
        self.navigationController?.pushViewController(createSubscriptionVC, animated: true)
    }
    
    func didTapDeleteSubscriptionButton(_ cell: SubscriptionListItemCollectionViewCell) {
        guard let indexPath = self.collectionSubscription?.indexPath(for: cell) else { return }
        showConfirmationAlert(title: "", message: AppStrings.Subscription.deleteSubscriptionConfirmationMessage, okBtnTitle: AppStrings.yes, cancelBtnTitle: AppStrings.no) { [weak self] success in
            if success {
                self?.tryDeleteSubscription(at: indexPath.row)
            }
        }
    }
    
    func didTapAttachmentButton(_ cell: SubscriptionListItemCollectionViewCell) {
        guard let indexPath = self.collectionSubscription?.indexPath(for: cell) else { return }
        showAttachmentSlideShow(at: indexPath.row)
    }
}
