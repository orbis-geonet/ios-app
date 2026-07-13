//
//  PostCellActionView.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 04/04/2021.
//

import UIKit

class PostCellActionView: UIView {
    
    enum PostCellActionType {
        case share
        case cancel
        case report
        case delete
    }
    
    @IBOutlet weak var shareTitleLabel: UILabel!
    @IBOutlet weak var reportTitleLabel: UILabel!
    @IBOutlet weak var deleteTitleLabel: UILabel!
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var actionBtnContainer: RoundedView!
    @IBOutlet weak var deleteActionView: UIView!
    @IBOutlet weak var reportActionView: UIView!
    @IBOutlet weak var shareActionView: UIView!
    
    @IBOutlet weak var btnLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnTopConstraint: NSLayoutConstraint!
    
    @IBAction func outsideViewTapped(_ sender: Any) {
        hideActionBtn(type: .cancel)
    }
    
    @IBAction func shareBtnTapped(_ sender: Any) {
        hideActionBtn(type: .share)
    }
    
    @IBAction func reportBtnTapped(_ sender: Any) {
        hideActionBtn(type: .report)
    }
    
    @IBAction func deleteBtnTapped(_ sender: Any) {
        hideActionBtn(type: .delete)
    }
    
    var onOutsideViewTapped: (() -> Void)?
    var onShareTapped: (() -> Void)?
    var onDeleteTapped: (() -> Void)?
    var onReportTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit(){
        Bundle.main.loadNibNamed("PostCellActionView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        updateStaticTexts()
    }
    
    func updateStaticTexts() {
        shareTitleLabel.text = AppStrings.Group.MoreActionTexts.share
        reportTitleLabel.text = AppStrings.Group.MoreActionTexts.report
        deleteTitleLabel.text = AppStrings.Group.MoreActionTexts.delete
    }
    
    private func hideActionBtn(type: PostCellActionType) {
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
                case .report:
                    self?.onReportTapped?()
                    break
                case .share:
                    self?.onShareTapped?()
                    break
            }
        }
    }
}
