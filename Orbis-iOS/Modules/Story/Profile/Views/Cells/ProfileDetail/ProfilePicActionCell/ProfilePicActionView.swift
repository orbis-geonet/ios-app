//
//  ProfilePicActionView.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 02/04/2021.
//

import UIKit

class ProfilePicActionView: UIView {
    
    @IBOutlet weak var uploadPhotoLabel: UILabel!
    @IBOutlet weak var getDirectionLabel: UILabel!
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var actionBtnContainer: RoundedView!
    @IBOutlet weak var secondButtonView: RoundedView!
    
    @IBOutlet weak var btnLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnTopConstraint: NSLayoutConstraint!
    
    @IBAction func outsideViewTapped(_ sender: Any) {
        hideActionBtn(isActionTapped: false, isSecondaryTapped: false)
    }
    
    @IBAction func actionBtnTapped(_ sender: Any) {
        hideActionBtn(isActionTapped: true, isSecondaryTapped: false)
    }
    @IBAction func secondaryBtnTapped(_ sender: Any) {
        hideActionBtn(isActionTapped: false, isSecondaryTapped: true)
    }
    
    var onOutsideViewTapped: (() -> Void)?
    var onActionBtnTapped: (() -> Void)?
    var onSecondaryActionBtnTapped: (() -> Void)?
    var hideSecondaryButton: Bool = true {
        didSet {
            secondButtonView.isHidden = hideSecondaryButton
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit(){
        Bundle.main.loadNibNamed("ProfilePicActionView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        secondButtonView.isHidden = hideSecondaryButton
        updateStaticTexts()
    }
    
    func updateStaticTexts() {
        uploadPhotoLabel.text = AppStrings.uploadPhoto
        getDirectionLabel.text = AppStrings.Places.getDirection
    }
    
    private func hideActionBtn(isActionTapped: Bool, isSecondaryTapped: Bool) {
        UIView.animate(withDuration: 0.15) {
            [weak self] in
            self?.actionBtnContainer.alpha = 0
            self?.secondButtonView.alpha = 0
        } completion: { [weak self] (true) in
            self?.actionBtnContainer.isHidden = true
            self?.secondButtonView.isHidden = true
            if isActionTapped {
                self?.onActionBtnTapped?()
            }
            else if isSecondaryTapped {
                self?.onSecondaryActionBtnTapped?()
            }
            else {
                self?.onOutsideViewTapped?()
            }
        }
    }

}
