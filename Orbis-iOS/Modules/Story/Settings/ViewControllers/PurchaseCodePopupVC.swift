//
//  PurchaseCodePopupVC.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 21/08/2023.
//

import UIKit
import HWPanModal

class PurchaseCodePopupVC: OrbisLocalizableViewController {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var viewTitleLabel: UILabel!
    @IBOutlet weak var contentTableView: UITableView!
    @IBOutlet weak var contentTableViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var contentBottomConstraint: NSLayoutConstraint!
    
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    struct Config {
        static var staticContentHeight: CGFloat {
            return 130.toCGFloat.relativeToIphone8Width()
        }
        static var tableViewTopInset: CGFloat {
            return 30.toCGFloat.relativeToIphone8Width()
        }
    }
    
    private var maxTableViewHeight: CGFloat {
        return ((UIScreen.main.bounds.height) - (self.view.safeAreaInsets.top + self.view.safeAreaInsets.bottom) - Config.staticContentHeight - Config.tableViewTopInset) * 0.9
    }
    
    private var minTableViewHeight: CGFloat {
        return 50.toCGFloat.relativeToIphone8Width()
    }
    
    var viewModel: PurchaseCodePopupViewModel!
    
    deinit {
        contentTableView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupConstraintValues()
        setupTableView()
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
    
    // MARK: Initialization Methods
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let obj = object as? UITableView {
            if obj == self.contentTableView && keyPath == "contentSize" {
                var newHeight = obj.contentSize.height
                if newHeight > maxTableViewHeight {
                    newHeight = maxTableViewHeight
                }
                if newHeight < minTableViewHeight {
                    newHeight = minTableViewHeight
                }
                
                contentTableViewHeightConstraint.constant = newHeight
                contentTableView.layoutIfNeeded()
                self.view.layoutIfNeeded()
                
                // reload layout & transition to short
                panModalSetNeedsLayoutUpdate()
                panModalTransitionTo(state: .long)
            }
        }
    }
    
    private func setupTableView() {
        contentTableView.dataSource = self
        contentTableView.delegate = self
        
        contentTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    private func updateViewComponents() {
        viewTitleLabel.text = viewModel.viewTitle
    }
    
}

// MARK: - TableView Delegates

extension PurchaseCodePopupVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0 }
        return viewModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PurchasedCodeItemTVC.identifier) as? PurchasedCodeItemTVC else {
            return UITableViewCell()
        }
        cell.code = viewModel.getCode(at: indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let code = viewModel.getCode(at: indexPath.row)
        let pasteboard = UIPasteboard.general
        pasteboard.string = code
        showToastMessage(message: AppStrings.textCopied)
    }
}
