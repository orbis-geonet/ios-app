//
//  DropDownOptionListView.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 18/08/2023.
//

import UIKit

class DropDownOptionListView: UIView {
    
    enum DropDownOptionActionType {
        case cancel
        case optionSelect
    }
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var actionBtnContainer: RoundedView!
    @IBOutlet weak var optionsListTableView: UITableView!
    
    @IBOutlet weak var btnLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    @IBAction func outsideViewTapped(_ sender: Any) {
        hideActionBtn(type: .cancel)
    }
    
    var onOutsideViewTapped: (() -> Void)?
    var onOptionSelected: ((DropDownOptionItem) -> Void)?
    
    var viewModel: DropDownOptionListViewModel!
    var headerTitle: String?
    
    private var maxTableHeight: CGFloat {
        return UIScreen.main.bounds.height * 0.3
    }
    let minTableHeight = 50.toCGFloat.relativeToIphone8Width()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func updateListSize() {
        optionsListTableView.layoutIfNeeded()
        actionBtnContainer.layoutIfNeeded()
        actionBtnContainer.setNeedsLayout()
        self.layoutIfNeeded()
        self.setNeedsLayout()
    }
    
    private func commonInit(viewModel: DropDownOptionListViewModel? = nil){
        Bundle.main.loadNibNamed("DropDownOptionListView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        setupTableView()
        if let viewM = viewModel {
            self.viewModel = viewM
        }
        else {
            self.viewModel = DropDownOptionListViewModel(options: [])
        }
        optionsListTableView.reloadData()
        updateListSize()
    }
    
    deinit {
        optionsListTableView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let obj = object as? UITableView {
            if obj == self.optionsListTableView && keyPath == "contentSize" {
                var newHeight = obj.contentSize.height + CGFloat(10).relativeToIphone8Width()
                if newHeight > maxTableHeight {
                    newHeight = maxTableHeight
                }
                if newHeight < minTableHeight {
                    newHeight = minTableHeight
                }
                tableViewHeightConstraint.constant = newHeight
                updateListSize()
            }
        }
    }
    
    private func setupTableView() {
        optionsListTableView.register(UINib(nibName: DropDownOptionItemCell.nibName, bundle: nil), forCellReuseIdentifier: DropDownOptionItemCell.identifier)
        optionsListTableView.dataSource = self
        optionsListTableView.delegate = self
        
        optionsListTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    private func hideActionBtn(type: DropDownOptionActionType, option: DropDownOptionItem? = nil) {
        UIView.animate(withDuration: 0.15) {
            [weak self] in
            self?.actionBtnContainer.alpha = 0
        } completion: { [weak self] (true) in
            self?.actionBtnContainer.isHidden = true
            switch type {
            case .cancel:
                self?.onOutsideViewTapped?()
                break
            case .optionSelect:
                guard let selectedOption = option else {
                    self?.onOutsideViewTapped?()
                    return
                }
                self?.onOptionSelected?(selectedOption)
                break
            }
        }
    }
}

extension DropDownOptionListView: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard viewModel != nil else { return 0}
        return viewModel.sectionCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0}
        return viewModel.count(inSection: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: DropDownOptionItemCell.identifier) as! DropDownOptionItemCell
            cell.name = viewModel.getOption(at: indexPath.row).displayName ?? ""
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let option = viewModel.getOption(at: indexPath.row)
            hideActionBtn(type: .optionSelect, option: option)
        }
    }
}
