//
//  SubscriptionStatGraphItemCVC.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 05/01/2023.
//

import UIKit

class SubscriptionStatGraphItemCVC: UICollectionViewCell {
    static let identifier = "subscriptionStatGraphItemCell"
    static let nibName = "SubscriptionStatGraphItemCVC"
    @IBOutlet weak var itemValueLabel: UILabel!
    @IBOutlet weak var graphIndicatorContainer: UIView!
    @IBOutlet weak var graphIndicatorView: RoundedView!
    @IBOutlet weak var barIndicatorHeightConstraint: NSLayoutConstraint!
    
    var data: [String: CGFloat]! {
        didSet {
            updateGraph()
        }
    }
    var isTapped: Bool = false {
        didSet {
            updateItemTapUI()
        }
    }
    var minValue: CGFloat = 0
    var maxValue: CGFloat = 0

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateBarHeight()
    }
    
    private func updateBarHeight() {
        let itemVal = data[data.first?.key ?? ""] ?? 0
        let maxHeight = graphIndicatorContainer.frame.size.height
        var itemHeight: CGFloat = 0
        if(itemVal > 0 && maxValue > 0) {
            itemHeight = (itemVal / maxValue) * maxHeight
        }
        if (itemHeight > maxHeight) {
            itemHeight = maxHeight
        }
        barIndicatorHeightConstraint.constant = itemHeight
        graphIndicatorContainer.layoutIfNeeded()
        graphIndicatorView.layoutIfNeeded()
    }
    
    private func updateGraph() {
        let itemLegend = data.first?.key ?? ""
        itemValueLabel.text = "\(itemLegend)"
        updateItemTapUI()
    }
    
    private func updateItemTapUI() {
        graphIndicatorView.backgroundColor = isTapped ? UIColor(named: AppColors.appBlack.rawValue) : UIColor(named: AppColors.appWarmGray2.rawValue)
        itemValueLabel.isHidden = !isTapped
    }

}
