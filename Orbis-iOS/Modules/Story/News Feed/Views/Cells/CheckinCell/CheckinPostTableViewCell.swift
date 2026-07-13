//
//  CheckinPostTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/03/2021.
//

import UIKit

class CheckinPostTableViewCell: UITableViewCell {
    @IBOutlet weak var postCollectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var pageControlWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var cvHeightConstraint: AdaptiveLayoutConstraint!
    
    @IBAction func pageControlValueChanged(_ sender: Any) {
        guard pageControl != nil else { return }
        guard isTap else { return }
        isTap = false
        let currentPage = pageControl.currentPage
        let pageWidth = self.postCollectionView.frame.size.width
        let scrollTo = CGPoint(x: pageWidth * currentPage.toCGFloat, y: 0)
        postCollectionView.setContentOffset(scrollTo, animated: true)
    }
    
    var isPlaceCheckinCell = false {
        didSet {
            updateCVheight()
        }
    }
    var isTap = true
    var currentPageControlPage: Int = 0
    
    var viewModel: CheckingPostViewModel! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.postCollectionView.reloadData()
                if self.viewModel.count > 0 {
                    self.postCollectionView.scrollToItem(at: IndexPath(row: self.viewModel.currentPageIndex, section: 0), at: .centeredVertically, animated: false)
                }
            }
        }
    }
    weak var actionDelegate: PostCellActionDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        collectionViewsSetup()
        updateCVheight()
    }
    
    private func updateCVheight() {
        self.cvHeightConstraint.constant = self.isPlaceCheckinCell ? 400.toCGFloat.relativeToIphone8Width() : 340.toCGFloat.relativeToIphone8Width()
        self.postCollectionView.layoutIfNeeded()
        self.layoutIfNeeded()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func collectionViewsSetup() {
        postCollectionView.register(UINib(nibName: "CheckinItemCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "checkinItemCell")
        postCollectionView.register(UINib(nibName: "PlaceCheckinItemCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "placeCheckinItemCell")
        postCollectionView.dataSource = self
        postCollectionView.delegate = self
        
        pageControlWidthConstraint.constant = pageControl.size(forNumberOfPages: 10).width
        pageControl.layoutIfNeeded()
    }
}

extension CheckinPostTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard viewModel != nil else {
            return 0
        }
        let count = viewModel.count
        pageControl.numberOfPages = count
        pageControl.currentPage = self.currentPageControlPage
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isPlaceCheckinCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "placeCheckinItemCell", for: indexPath) as! PlaceCheckinItemCollectionViewCell
            cell.viewModel = CheckingPostItemViewModel(data: viewModel.getCheckinPost(at: indexPath.row))
            cell.actionDelegate = self.actionDelegate
            cell.layoutIfNeeded()
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "checkinItemCell", for: indexPath) as! CheckinItemCollectionViewCell
        cell.viewModel = CheckingPostItemViewModel(data: viewModel.getCheckinPost(at: indexPath.row))
        cell.actionDelegate = self.actionDelegate
        cell.layoutIfNeeded()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if isPlaceCheckinCell {
            return CGSize(width: UIScreen.main.bounds.width, height: 400.toCGFloat.relativeToIphone8Width())
        }
        return CGSize(width: UIScreen.main.bounds.width, height: 340.toCGFloat.relativeToIphone8Width())
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

extension CheckinPostTableViewCell: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == postCollectionView else { return }
        guard isTap else { return }
        let witdh = scrollView.frame.width - (scrollView.contentInset.left*2)
        let index = scrollView.contentOffset.x / witdh
        let roundedIndex = round(index)
        self.currentPageControlPage = Int(roundedIndex)
        self.pageControl.currentPage = Int(roundedIndex)
        self.viewModel.currentPageIndex = self.pageControl.currentPage
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == postCollectionView else { return }
        self.currentPageControlPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        pageControl?.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        isTap = true
        self.viewModel.currentPageIndex = self.pageControl.currentPage
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView == postCollectionView else { return }
        self.currentPageControlPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        pageControl?.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        isTap = true
        self.viewModel.currentPageIndex = self.pageControl.currentPage
    }
}
