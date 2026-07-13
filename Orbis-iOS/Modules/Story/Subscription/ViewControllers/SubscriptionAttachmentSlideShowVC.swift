//
//  SubscriptionAttachmentSlideShowVC.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 23/08/2023.
//

import UIKit
import HWPanModal

class SubscriptionAttachmentSlideShowVC: OrbisLocalizableViewController {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var viewTitleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewPageControl: UIPageControl!
    @IBOutlet weak var contentBottomConstraint: NSLayoutConstraint!
    
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    @IBAction func pageControlValueChanged(_ sender: Any) {
        guard collectionViewPageControl != nil else { return }
        guard isAttachmentPageControlTap else { return }
        isAttachmentPageControlTap = false
        let currentPage = collectionViewPageControl.currentPage
        let pageWidth = self.collectionView.frame.size.width
        let scrollTo = CGPoint(x: pageWidth * currentPage.toCGFloat, y: 0)
        collectionView.setContentOffset(scrollTo, animated: true)
    }
    
    var imageNames: [String]! = []
    
    var isAttachmentPageControlTap = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupConstraintValues()
        setupAttachmentCollectionView()
        updateViewComponents()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        setupConstraintValues()
    }
    
    override func updateStaticTexts() {
        updateViewComponents()
    }
    
    private func setupConstraintValues() {
        contentBottomConstraint.constant = self.view.safeAreaInsets.bottom
        self.contentView.layoutIfNeeded()
        
        // reload layout & transition to short
        panModalSetNeedsLayoutUpdate()
        panModalTransitionTo(state: .long)
    }
    
    override func hw_gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    override func showDragIndicator() -> Bool {
        return false
    }
    
    override func shortFormHeight() -> PanModalHeight {
        return PanModalHeight(type: .content, height: contentView.frame.height)
    }
    
    override func longFormHeight() -> PanModalHeight {
        return PanModalHeight(type: .content, height: contentView.frame.height)
    }
    
    func setupAttachmentCollectionView() {
        collectionView.register(UINib(nibName: SubscriptionAttachmentItemCell.nibName, bundle: nil), forCellWithReuseIdentifier: SubscriptionAttachmentItemCell.identifier)
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }

    private func updateViewComponents() {
        viewTitleLabel.text = AppStrings.Subscription.CreateEditText.photosTitle
        collectionView.reloadData()
    }
}

extension SubscriptionAttachmentSlideShowVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = self.imageNames.count
        collectionViewPageControl.numberOfPages = count
        collectionViewPageControl.currentPage = 0
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SubscriptionAttachmentItemCell.identifier, for: indexPath) as! SubscriptionAttachmentItemCell
        cell.model = SubscriptionImage(imageKey: imageNames[indexPath.row])
        cell.hideRemoveBtn = true
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

extension SubscriptionAttachmentSlideShowVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == collectionView else { return }
        guard isAttachmentPageControlTap else { return }
        let witdh = scrollView.frame.width - (scrollView.contentInset.left*2)
        let index = scrollView.contentOffset.x / witdh
        let roundedIndex = round(index)
        self.collectionViewPageControl.currentPage = Int(roundedIndex)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == collectionView else { return }
        collectionViewPageControl?.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        isAttachmentPageControlTap = true
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView == collectionView else { return }
        collectionViewPageControl?.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        isAttachmentPageControlTap = true
    }
}
