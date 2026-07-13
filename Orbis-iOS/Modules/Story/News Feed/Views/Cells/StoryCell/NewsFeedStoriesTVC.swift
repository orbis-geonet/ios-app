//
//  NewsFeedStoriesTVC.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/03/2021.
//

import UIKit

protocol StoryItemTapResponseDelegate: AnyObject {
    func didTapStoryCell(atIndex index: Int)
    func didLongTapStoryCell(atIndex index: Int)
    func didTriggerPagination()
}

class NewsFeedStoriesTVC: UITableViewCell {
    @IBOutlet weak var storiesCollectionView: UICollectionView!
    
    var viewModel: FeedStoriesViewModel!
    weak var storyCellTapResponseDelegate: StoryItemTapResponseDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        collectionViewsSetup()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func collectionViewsSetup() {
        storiesCollectionView.register(UINib(nibName: "StoryItemCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "storyItemCell")
        storiesCollectionView.dataSource = self
        storiesCollectionView.delegate = self
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleCellLongPress(sender:)))
        storiesCollectionView.addGestureRecognizer(longTapGesture)
    }
    
    @objc private func handleCellLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: storiesCollectionView)
            if let indexPath = storiesCollectionView.indexPathForItem(at: touchPoint) {
                storyCellTapResponseDelegate?.didLongTapStoryCell(atIndex: indexPath.row)
            }
        }
    }
}

extension NewsFeedStoriesTVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard viewModel != nil else {
            return 0
        }
        return viewModel.storyCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "storyItemCell", for: indexPath) as! StoryItemCollectionViewCell
        cell.viewModel = StoryItemViewModel(user: viewModel.getModel(at: indexPath.row))
        cell.tapDelegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 65.toCGFloat.relativeToIphone8Width(), height: 65.toCGFloat.relativeToIphone8Width())
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.toCGFloat.relativeToIphone8Width(), left: 15.toCGFloat.relativeToIphone8Width(), bottom: 10.toCGFloat.relativeToIphone8Width(), right: 15.toCGFloat.relativeToIphone8Width())
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 15.toCGFloat.relativeToIphone8Width()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 15.toCGFloat.relativeToIphone8Width()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.row == viewModel.storyCount - 1 else { return }
        storyCellTapResponseDelegate?.didTriggerPagination()
    }
}

extension NewsFeedStoriesTVC: StoryItemTapDelegate {
    func didTapStoryCell(cell: StoryItemCollectionViewCell) {
        guard let indexPath = storiesCollectionView.indexPath(for: cell) else {
            return
        }
        self.storyCellTapResponseDelegate?.didTapStoryCell(atIndex: indexPath.row)
    }
}
