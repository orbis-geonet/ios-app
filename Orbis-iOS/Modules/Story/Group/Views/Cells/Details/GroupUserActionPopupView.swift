//
//  GroupUserActionPopupView.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 03/05/2021.
//


import UIKit

class GroupUserActionPopupView: UIView {
    
    
    @IBOutlet weak var flagLabel: UILabel!
    @IBOutlet weak var deleteLabel: UILabel!
    @IBOutlet weak var followUnfollowLabel: UILabel!
    @IBOutlet weak var leaveLabel: UILabel!
    @IBOutlet weak var unhideStoriesLabel: UILabel!
    @IBOutlet weak var leaveView: UIView!
    @IBOutlet weak var followUnfollowView: UIView!
    @IBOutlet weak var deleteView: UIView!
    @IBOutlet weak var flagView: UIView!
    @IBOutlet weak var unhideStoriesView: UIView!
    @IBOutlet weak var activateSubscriptionView: UIView!
    @IBOutlet weak var activateSubscriptionLabel: UILabel!
    @IBOutlet weak var deactivateSubscriptionLabel: UILabel!
    @IBOutlet weak var deactivateSubscriptionView: UIView!
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var actionBtnContainer: RoundedView!
    
    @IBOutlet weak var btnTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnTopConstraint: NSLayoutConstraint!
    
    @IBAction func outsideViewTapped(_ sender: Any) {
        hideActionBtn(type: .cancel)
    }
    
    @IBAction func leaveBtnTapped(_ sender: Any) {
        hideActionBtn(type: .leave)
    }
    
    @IBAction func followUnfollowBtnTapped(_ sender: Any) {
        hideActionBtn(type: .followUnfollow)
    }
    
    @IBAction func deleteBtnTapped(_ sender: Any) {
        hideActionBtn(type: .delete)
    }
    
    @IBAction func flagBtnTapped(_ sender: Any) {
        hideActionBtn(type: .flag)
    }
    
    @IBAction func unhideStoriesTapped(_ sender: Any) {
        hideActionBtn(type: .unhideStories)
    }
    
    @IBAction func activateSubscriptionBtnTapped(_ sender: Any) {
        hideActionBtn(type: .activateSubscription)
    }
    
    @IBAction func deactivateSubscriptionTapped(_ sender: Any) {
        hideActionBtn(type: .deactivateSubscription)
    }
    
    enum GroupActionType {
        case leave
        case followUnfollow
        case flag
        case delete
        case unhideStories
        case cancel
        case deactivateSubscription
        case activateSubscription
    }
    var onOutsideViewTapped: (() -> Void)?
    var onLeaveTapped: (() -> Void)?
    var onFollowUnfollowTapped: (() -> Void)?
    var onDeleteTapped: (() -> Void)?
    var onReportTapped: (() -> Void)?
    var onUnhideStoriesTapped: (() -> Void)?
    var onActivateSubscriptionTapped: (() -> Void)?
    var onDeactivateSubscriptionTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit(){
        Bundle.main.loadNibNamed("GroupUserActionPopupView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func updateStaticTexts() {
        
    }
    
    private func hideActionBtn(type: GroupActionType) {
        UIView.animate(withDuration: 0.15) {
            [weak self] in
            self?.actionBtnContainer.alpha = 0
        } completion: { [weak self] (true) in
            self?.actionBtnContainer.isHidden = true
            switch type {
            case .cancel:
                self?.onOutsideViewTapped?()
                break
            case .delete:
                self?.onDeleteTapped?()
                break
            case .followUnfollow:
                self?.onFollowUnfollowTapped?()
                break
            case .leave:
                self?.onLeaveTapped?()
            case .flag:
                self?.onReportTapped?()
                break
            case .unhideStories:
                self?.onUnhideStoriesTapped?()
                break
            case .activateSubscription:
                self?.onActivateSubscriptionTapped?()
                break
            case .deactivateSubscription:
                self?.onDeactivateSubscriptionTapped?()
                break
            }
        }
    }
    
}
