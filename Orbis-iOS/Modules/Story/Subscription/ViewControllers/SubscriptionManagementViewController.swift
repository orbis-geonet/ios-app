//
//  SubscriptionManagementViewController.swift
//  Orbis-iOS
//
//  Created by Vikas Sharma on 05/11/22.
//

import UIKit

enum SubscriptionGraphFilterValue: String, CaseIterable {
    case month
    case trimester
    case semester
    case year
}

class SubscriptionManagementViewController: OrbisLocalizableViewController {
    
    @IBOutlet weak var previousBtnImageView: UIImageView!
    @IBOutlet weak var subscriptionTitleLabel: UILabel!
    @IBOutlet weak var nextBtnImageView: UIImageView!
    @IBOutlet weak var totalSubscriptionTitleLabel: UILabel!
    @IBOutlet weak var totalSubscriptionsValueLabel: UILabel!
    @IBOutlet weak var totalRevenueTitleLabel: UILabel!
    @IBOutlet weak var totalRevenueValueLabel: UILabel!
    @IBOutlet weak var graphSubscriptionValueLabel: UILabel!
    @IBOutlet weak var graphSubscriptionTitleLabel: UILabel!
    @IBOutlet weak var graphRevenueTitleLabel: UILabel!
    @IBOutlet weak var graphRevenueValueLabel: UILabel!
    
    
    @IBOutlet weak var subscriptionGraphCV: UICollectionView!
    @IBOutlet weak var subscriptionGraphFilterCV: UICollectionView!
    @IBOutlet weak var subscriptionAmountGraphCV: UICollectionView!
    @IBOutlet weak var subscriptionAmountGraphFilterCV: UICollectionView!
    
    var previousTappedSubscriberDataIndex: Int?
    var previousTappedAmountDataIndex: Int?
    weak var navDelegate: SubscriptionActivityPageNavigationDelegate?
    
    var viewModel: SubscriptionManagementViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewComponents()
        updateStaticTexts()
        setupSubscriptionGraphCV()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
        fetchStatData()
    }
    
    override func updateStaticTexts() {
        super.updateStaticTexts()
        totalSubscriptionTitleLabel.text = AppStrings.Subscription.Activity.totalSubscriptionTitle
        totalRevenueTitleLabel.text = AppStrings.Subscription.Activity.totalRevenueTitle
        graphSubscriptionTitleLabel.text = AppStrings.Subscription.Activity.subscriptionsTitle
        graphRevenueTitleLabel.text = AppStrings.Subscription.Activity.revenueTitle
    }
    
    private func configureViewComponents() {
        if let tabManVC = self.tabmanParent as? SubscriptionActivityTabViewController {
            tabManVC.onFirstFetchComplete = {
                [weak self] in
                if tabManVC.currentIndex == 0 {
                    self?.refreshData()
                    self?.fetchStatData()
                }
            }
        }
        previousBtnImageView.isUserInteractionEnabled = true
        nextBtnImageView.isUserInteractionEnabled = true
        
        let previousTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPreviousSubscriptionBtn(_:)))
        let nextTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapNextSubscriptionBtn(_:)))
        
        previousBtnImageView.addGestureRecognizer(previousTapGesture)
        nextBtnImageView.addGestureRecognizer(nextTapGesture)
    }
    
    @objc private func didTapPreviousSubscriptionBtn(_ sender: Any) {
        guard let currentIndex = navDelegate?.getCurrentIndex(), currentIndex > 0 else { return }
        guard navDelegate?.gotoPage(at: currentIndex - 1) == true else { return }
        refreshData()
        self.fetchStatData()
    }
    
    @objc private func didTapNextSubscriptionBtn(_ sender: Any) {
        guard let currentIndex = navDelegate?.getCurrentIndex(), let maxIndex = navDelegate?.getMaxIndex(), currentIndex < maxIndex else { return }
        guard navDelegate?.gotoPage(at: currentIndex + 1) == true else { return }
        refreshData()
        self.fetchStatData()
    }
    
    private func setupSubscriptionGraphCV() {
        subscriptionGraphCV.register(UINib(nibName: SubscriptionStatGraphItemCVC.nibName, bundle: nil), forCellWithReuseIdentifier: SubscriptionStatGraphItemCVC.identifier)
        subscriptionGraphCV.delegate = self
        subscriptionGraphCV.dataSource = self
        
        subscriptionGraphFilterCV.register(UINib(nibName: SubscriptionStatFilterItemCVC.nibName, bundle: nil), forCellWithReuseIdentifier: SubscriptionStatFilterItemCVC.identifier)
        subscriptionGraphFilterCV.delegate = self
        subscriptionGraphFilterCV.dataSource = self
        
        subscriptionAmountGraphCV.register(UINib(nibName: SubscriptionStatGraphItemCVC.nibName, bundle: nil), forCellWithReuseIdentifier: SubscriptionStatGraphItemCVC.identifier)
        subscriptionAmountGraphCV.delegate = self
        subscriptionAmountGraphCV.dataSource = self
        
        subscriptionAmountGraphFilterCV.register(UINib(nibName: SubscriptionStatFilterItemCVC.nibName, bundle: nil), forCellWithReuseIdentifier: SubscriptionStatFilterItemCVC.identifier)
        subscriptionAmountGraphFilterCV.delegate = self
        subscriptionAmountGraphFilterCV.dataSource = self
    }
    
    private func fetchStatData() {
        self.previousTappedAmountDataIndex = nil
        self.previousTappedSubscriberDataIndex = nil
        self.showOrbisLoader(disableUserInteraction: true)
        viewModel.fetchStatData { [weak self] result, error in
            if let error = error {
                self?.handleError(error: error)
            } else {
                self?.updateSubscriptionGraphData()
            }
            self?.hideOrbisLoader()
        }
    }

    private func refreshData() {
        viewModel.subscription = navDelegate?.getCurrentSelectedSubscriptionModel()
        updateSubscriptionData()
    }
    
    private func updateSubscriptionData() {
        subscriptionTitleLabel.text = viewModel.subscriptionName
        updateSubscriptionGraphData()
    }
    
    private func updateSubscriptionGraphData() {
        totalSubscriptionsValueLabel.text = viewModel.totalSubscribers
        graphSubscriptionValueLabel.text = viewModel.totalSubscribers
        totalRevenueValueLabel.text = viewModel.totalRevenue
        graphRevenueValueLabel.text = viewModel.totalRevenue
        subscriptionGraphCV.reloadData()
        subscriptionAmountGraphCV.reloadData()
        subscriptionGraphFilterCV.reloadData()
        subscriptionAmountGraphFilterCV.reloadData()
    }
}

extension SubscriptionManagementViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(collectionView == subscriptionGraphCV) {
            return viewModel.graphSubscribersStatData.count
        } else if (collectionView == subscriptionAmountGraphCV) {
            return viewModel.graphRevenueStatData.count
        } else if (collectionView == subscriptionGraphFilterCV || collectionView == subscriptionAmountGraphFilterCV) {
            return viewModel.graphFilterValuesCount
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if(collectionView == subscriptionGraphCV) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SubscriptionStatGraphItemCVC.identifier, for: indexPath) as! SubscriptionStatGraphItemCVC
            cell.minValue = viewModel.minSubscriberValue
            cell.maxValue = viewModel.maxSubscriberValue
            cell.data = viewModel.graphSubscribersStatData[indexPath.row]
            cell.isTapped = indexPath.row == previousTappedSubscriberDataIndex
            cell.layoutIfNeeded()
            return cell
        } else if (collectionView == subscriptionAmountGraphCV) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SubscriptionStatGraphItemCVC.identifier, for: indexPath) as! SubscriptionStatGraphItemCVC
            cell.minValue = viewModel.minRevenueValue
            cell.maxValue = viewModel.maxRevenueValue
            cell.data = viewModel.graphRevenueStatData[indexPath.row]
            cell.isTapped = indexPath.row == previousTappedAmountDataIndex
            cell.layoutIfNeeded()
            return cell
        } else if (collectionView == subscriptionGraphFilterCV || collectionView == subscriptionAmountGraphFilterCV) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SubscriptionStatFilterItemCVC.identifier, for: indexPath) as! SubscriptionStatFilterItemCVC
            cell.name = viewModel.graphFilterValues[indexPath.row].rawValue.capitalized.localized
            cell.isActive = indexPath.row == viewModel.selectedFilterIndex
            cell.layoutIfNeeded()
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(collectionView == subscriptionGraphCV) {
            if (previousTappedSubscriberDataIndex == indexPath.row) {
                previousTappedSubscriberDataIndex = nil
                collectionView.reloadItems(at: [indexPath])
                return
            }
            var indexPathsToReload = [IndexPath]()
            if let prevIndex = self.previousTappedSubscriberDataIndex {
                indexPathsToReload.append(IndexPath(row: prevIndex, section: indexPath.section))
            }
            previousTappedSubscriberDataIndex = indexPath.row
            indexPathsToReload.append(indexPath)
            collectionView.performBatchUpdates {
                collectionView.reloadItems(at: indexPathsToReload)
            }
        } else if (collectionView == subscriptionAmountGraphCV) {
            if (previousTappedAmountDataIndex == indexPath.row) {
                previousTappedAmountDataIndex = nil
                collectionView.reloadItems(at: [indexPath])
                return
            }
            var indexPathsToReload = [IndexPath]()
            if let prevIndex = self.previousTappedAmountDataIndex {
                indexPathsToReload.append(IndexPath(row: prevIndex, section: indexPath.section))
            }
            previousTappedAmountDataIndex = indexPath.row
            indexPathsToReload.append(indexPath)
            collectionView.performBatchUpdates {
                collectionView.reloadItems(at: indexPathsToReload)
            }
        } else if (collectionView == subscriptionGraphFilterCV || collectionView == subscriptionAmountGraphFilterCV) {
            if(viewModel.selectedFilterIndex == indexPath.row) { return }
            var indexPathsToReload = [IndexPath]()
            indexPathsToReload.append(IndexPath(row: viewModel.selectedFilterIndex, section: indexPath.section))
            viewModel.selectedFilterIndex = indexPath.row
            indexPathsToReload.append(indexPath)
            subscriptionGraphFilterCV.performBatchUpdates { [weak self] in
                self?.subscriptionGraphFilterCV.reloadItems(at: indexPathsToReload)
            }
            subscriptionAmountGraphFilterCV.performBatchUpdates { [weak self] in
                self?.subscriptionAmountGraphFilterCV.reloadItems(at: indexPathsToReload)
            }
            fetchStatData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if(collectionView == subscriptionGraphCV) {
            var sizeWidth = 25.toCGFloat.relativeToIphone8Width()
            if(indexPath.row == previousTappedSubscriberDataIndex) {
                let itemVal = viewModel.graphSubscribersStatData[indexPath.row].keys.first ?? ""
                let text = "\(itemVal)"
                let textWidth = text.findTextWidth(font: UIFont(name: "Roboto-Black", size: CGFloat(14).relativeToIphone8Width())!)
                if(textWidth > sizeWidth) {
                    sizeWidth = textWidth
                }
            }
            return CGSize(width: sizeWidth, height: collectionView.frame.size.height)
        } else if(collectionView == subscriptionAmountGraphCV) {
            var sizeWidth = 25.toCGFloat.relativeToIphone8Width()
            if(indexPath.row == previousTappedAmountDataIndex) {
                let itemVal = viewModel.graphRevenueStatData[indexPath.row].keys.first ?? ""
                let text = "\(itemVal)"
                let textWidth = text.findTextWidth(font: UIFont(name: "Roboto-Black", size: CGFloat(14).relativeToIphone8Width())!)
                if(textWidth > sizeWidth) {
                    sizeWidth = textWidth
                }
            }
            return CGSize(width: sizeWidth, height: collectionView.frame.size.height)
        } else if (collectionView == subscriptionGraphFilterCV || collectionView == subscriptionAmountGraphFilterCV) {
            var sizeWidth = 50.toCGFloat.relativeToIphone8Width()
            let itemName = viewModel.graphFilterValues[indexPath.row].rawValue.capitalized.localized
            let itemNameHorizontalPadding = 30.toCGFloat.relativeToIphone8Width()
            let textWidth = itemName.findTextWidth(font: UIFont(name: "Roboto-Regular", size: CGFloat(12).relativeToIphone8Width())!) + itemNameHorizontalPadding
            if(textWidth > sizeWidth) {
                sizeWidth = textWidth
            }
            return CGSize(width: sizeWidth, height: collectionView.frame.size.height)
        }
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10.toCGFloat.relativeToIphone8Width()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10.toCGFloat.relativeToIphone8Width()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
}
