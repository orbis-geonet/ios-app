//
//  GroupsNearbyTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 03/04/2021.
//

import UIKit

protocol NearByGroupActionDelegate: AnyObject {
    func didSelectGroup(at index: Int)
}

class GroupsNearbyTableViewCell: UITableViewCell {
    
    @IBOutlet weak var feedLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nearbyGroupsCollectionView: UICollectionView!
    
    struct CellConfig {
        static let cellSeparation: CGFloat = 20.toCGFloat.relativeToIphone8Width()
    }
    
    var viewModel: PlaceNearbyGroupsCellViewModel! {
        didSet {
            viewModel.calculateAndStoreCellWidths(withFullWidth: UIScreen.main.bounds.width - 30.toCGFloat.relativeToIphone8Width())
            nearbyGroupsCollectionView.reloadData()
        }
    }
    
    weak var actionDelegate: NearByGroupActionDelegate?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        collectionViewsSetup()
        updateStaticTexts()
        addLanguageUpdateObserver()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func addLanguageUpdateObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateLanguage), name: NSNotification.Name(rawValue: AppNotificationKeys.userLanguageDidUpdate), object: nil)
    }
    
    @objc private func didUpdateLanguage(_ notification: NSNotification) {
        updateStaticTexts()
    }
    
    func collectionViewsSetup() {
        nearbyGroupsCollectionView.register(UINib(nibName: "NearbyGroupItemCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "nearbyGroupItemCell")
        nearbyGroupsCollectionView.dataSource = self
        nearbyGroupsCollectionView.delegate = self
    }
    
    func updateStaticTexts() {
        titleLabel.text = AppStrings.Places.groupsInPlace
        feedLabel.text = AppStrings.feed
    }
}

extension GroupsNearbyTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard viewModel != nil else {
            return 0
        }
        let count = viewModel.count
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "nearbyGroupItemCell", for: indexPath) as! NearbyGroupItemCollectionViewCell
        cell.viewModel = NearbyGroupCellItemViewModel(group: viewModel.getGroup(at: indexPath.row))
        cell.updateViewContent(atIndex: indexPath.row, count: viewModel.count)
        cell.layer.zPosition = (viewModel.count - indexPath.row).toCGFloat
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: viewModel.getCellWidth(at: indexPath.row, separation: CellConfig.cellSeparation), height: collectionView.frame.size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 15.toCGFloat.relativeToIphone8Width(), bottom: 0, right: 15.toCGFloat.relativeToIphone8Width())
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return -CellConfig.cellSeparation
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return -CellConfig.cellSeparation
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        actionDelegate?.didSelectGroup(at: indexPath.row)
    }
}
