//
//  DropDownSearchListView.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 04/04/2021.
//

import UIKit

class DropDownSearchListView: UIView {
    
    enum DropdownActionType {
        case cancel
        case userSelect
        case groupSelect
    }
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var actionBtnContainer: RoundedView!
    @IBOutlet weak var userSearchTextField: UITextField!
    @IBOutlet weak var userListTableView: UITableView!
    
    @IBOutlet weak var btnLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    @IBAction func outsideViewTapped(_ sender: Any) {
        hideActionBtn(type: .cancel)
    }
    @IBAction func searchIconTapped(_ sender: Any) {
        userSearchTextField.becomeFirstResponder()
    }
    
    var onOutsideViewTapped: (() -> Void)?
    var onUserSelected: ((OrbisUser) -> Void)?
    var onGroupSelected: ((Group) -> Void)?
    var onSearchReturnTap: ((String) -> Void)?
    
    var viewModel: DropdownSearchListViewModel!
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
    
    private func commonInit(viewModel: DropdownSearchListViewModel? = nil){
        Bundle.main.loadNibNamed("DropdownSearchListView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        setupTableView()
        if let viewM = viewModel {
            self.viewModel = viewM
        }
        else {
            self.viewModel = DropdownSearchListViewModel(users: FeedManager().getStoryUsers(), groups: GroupManager().getRandomGroupList())
        }
        userListTableView.reloadData()
        userSearchTextField.delegate = self
        updateStaticTexts()
    }
    
    deinit {
        userListTableView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    func updateStaticTexts() {
        userSearchTextField.placeholder = AppStrings.Group.groupNameSearchPlaceholder
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let obj = object as? UITableView {
            if obj == self.userListTableView && keyPath == "contentSize" {
                var newHeight = obj.contentSize.height + CGFloat(10).relativeToIphone8Width()
                if newHeight > maxTableHeight {
                    newHeight = maxTableHeight
                }
                if newHeight < minTableHeight {
                    newHeight = minTableHeight
                }
                tableViewHeightConstraint.constant = newHeight
                userListTableView.layoutIfNeeded()
                actionBtnContainer.setNeedsLayout()
                self.layoutIfNeeded()
            }
        }
    }
    
    private func setupTableView() {
        userListTableView.register(UINib(nibName: "SearchedDropdownUserItemTVC", bundle: nil), forCellReuseIdentifier: "userItemCell")
        userListTableView.dataSource = self
        userListTableView.delegate = self
        
        userListTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    private func hideActionBtn(type: DropdownActionType, user: OrbisUser? = nil, group: Group? = nil) {
        UIView.animate(withDuration: 0.15) {
            [weak self] in
            self?.actionBtnContainer.alpha = 0
        } completion: { [weak self] (true) in
            self?.actionBtnContainer.isHidden = true
            switch type {
            case .cancel:
                self?.onOutsideViewTapped?()
                break
            case .userSelect:
                guard let selectedUser = user else {
                    self?.onOutsideViewTapped?()
                    return
                }
                self?.onUserSelected?(selectedUser)
                break
            case .groupSelect:
                guard let selectedGroup = group else {
                    self?.onOutsideViewTapped?()
                    return
                }
                self?.onGroupSelected?(selectedGroup)
                break
            }
        }
    }
}

extension DropDownSearchListView: UITableViewDataSource, UITableViewDelegate {
    
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
            let groupItemCell = tableView.dequeueReusableCell(withIdentifier: "userItemCell") as! SearchedDropdownUserItemTVC
            groupItemCell.viewModel = SearchDropDownItemViewModel(user: viewModel.getUser(at: indexPath.row), group: nil, type: .user)
            return groupItemCell
        }
        else {
            let groupItemCell = tableView.dequeueReusableCell(withIdentifier: "userItemCell") as! SearchedDropdownUserItemTVC
            groupItemCell.viewModel = SearchDropDownItemViewModel(user: nil, group: viewModel.getGroup(at: indexPath.row), type: .group)
            return groupItemCell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let user = viewModel.getUser(at: indexPath.row)
            hideActionBtn(type: .userSelect, user: user)
        }
        else if indexPath.section == 1 {
            let group = viewModel.getGroup(at: indexPath.row)
            hideActionBtn(type: .groupSelect, group: group)
        }
    }
}

extension DropDownSearchListView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        hideActionBtn(type: .cancel)
        onSearchReturnTap?(textField.text ?? "")
        return true
    }
}
