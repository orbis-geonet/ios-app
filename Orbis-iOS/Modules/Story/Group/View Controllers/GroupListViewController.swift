//
//  GroupListViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 30/03/2021.
//

import UIKit
import Combine

class GroupListViewController: OrbisLocalizableViewController {

    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var resultTableView: UITableView!
    
    //MARK: kamran variables
    private var cancellables: Set<AnyCancellable> = []
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func searchTapped(_ sender: Any) {
        searchTextField.becomeFirstResponder()
    }
    @IBAction func createNewTapped(_ sender: Any) {
        openCreateNewGroupView()
    }
    @IBAction func newsFeedTapped(_ sender: Any) {
        gotoNewsFeedView()
    }
    @IBAction func mapTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    var viewModel: GroupListViewModel!
    var isLoading = false
    var searchTimer = Timer()
    var refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = GroupListViewModel(searchText: "")
        setupTableView()
        handleViewModelActionHandlers()
        updateStaticTexts()
        
        guard !isLoading else { return }
       // resetData() original code
        //loadData() original code
        //MARK: cachek code injected
        callCachedData()
    }
    func callCachedData(){
        setupCacheObserver()
        viewModel.getCachedGroups(city: Constants.groupCity ?? "", userLoggedIn: viewModel.isLoggedIn)
        resultTableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func updateStaticTexts() {
        titleLabel.text = AppStrings.Group.groups
        
        print(AppStrings.Group.searchGroupPlaceholder)
        
        searchTextField.placeholder = AppStrings.Group.searchGroupPlaceholder
    }
    
    func setupTableView() {
        resultTableView.dataSource = self
        resultTableView.delegate = self
        
        searchTextField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        resultTableView.addSubview(refreshControl)
    }
    
    @objc func refresh(_ sender: AnyObject) {
        refreshList()
    }
    
    private func refreshList() {
        resetData()
        loadData()
    }
    
    func resetData(textDidChangeTrue: Bool = false) {
        if (!textDidChangeTrue){
            viewModel.deleteCachedGroups(city: Constants.groupCity ?? "", loggedIn: self.viewModel.isLoggedIn)
        }
        viewModel.initializePagination()
        isLoading = false
        resultTableView.reloadData()
    }
    
    func loadData() {
        isLoading = true
        self.showOrbisLoader()
        viewModel.loadGroups()
    }
    
    func loadMore() {
        isLoading = true
        self.showOrbisLoader()
        viewModel.loadMoreGroups()
    }
    private func handleViewModelActionHandlers() {
        viewModel.onGroupsRankingFetched = { [weak self] in
            self?.refreshControl.endRefreshing()
            self?.hideOrbisLoader()
            self?.resultTableView.reloadData()
            self?.isLoading = false
            self?.loadData()
            //rating observer
            if let groups = self?.viewModel.model {
                self?.viewModel.cacheGroups(groups: [groups], city: Constants.groupCity ?? "", loggedIn: self?.viewModel.isLoggedIn ?? false)
            }
        }
        viewModel.onGroupsFetched = { [weak self] in
            self?.refreshControl.endRefreshing()
            self?.hideOrbisLoader()
            self?.resultTableView.reloadData()
            self?.isLoading = false
            if let groups = self?.viewModel.model {
                //self?.viewModel.deleteCachedGroups(city: Constants.groupCity ?? "", loggedIn: self?.viewModel.isLoggedIn ?? false)
                self?.viewModel.cacheGroups(groups: [groups], city: Constants.groupCity ?? "", loggedIn: self?.viewModel.isLoggedIn ?? false)
            }
        }
        viewModel.onGroupsFetchedCompletePagination = { [weak self] in
            self?.refreshControl.endRefreshing()
            self?.hideOrbisLoader()
            self?.resultTableView.reloadData()
            self?.isLoading = false
        }
        viewModel.onGroupsFetchLateResponse = {
            [weak self] in
            self?.refreshControl.endRefreshing()
            self?.hideOrbisLoader()
        }
        viewModel.onGroupsFetchError = { [weak self] (error) in
            self?.refreshControl.endRefreshing()
            self?.hideOrbisLoader()
            self?.handleError(error: error)
            self?.isLoading = false
        }
    }
    
    private func openCreateNewGroupView() {
        guard let _ = UserSessionManager.shared.currentUser else {
            gotoAuthView()
            return
        }
        let createGroupView = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "createGroupVC") as! CreateGroupViewController
        createGroupView.viewModel = CreateGroupViewModel()
        self.navigationController?.pushViewController(createGroupView, animated: true)
    }
    
    private func gotoAuthView() {
        if UserSessionManager.shared.hasLoginOnboardingBeenShown {
            let authView = UIStoryboard.getViewController(inStoryboard: "Auth", identifier: "authMainVC") as! AuthMainViewController
            authView.defaultSelectionIndex = 0
            self.navigationController?.pushViewController(authView, animated: true)
        }
        else {
            UserSessionManager.shared.setLoginOnboardingShown()
            let authOptionPickerVC = UIStoryboard.getViewController(inStoryboard: "Auth", identifier: "authOptionPickerVC") as! AuthOptionPickerViewController
            self.navigationController?.pushViewController(authOptionPickerVC, animated: true)
        }
    }
    
    private func gotoNewsFeedView() {
        let newsFeedVC = UIStoryboard.getViewController(inStoryboard: "NewsFeed", identifier: "newsFeedTabVC") as! NewsFeedTabViewController
        self.navigationController?.pushViewController(newsFeedVC, animated: true)
    }
    
    // MARK:- Text Field Delegate methods
    
    @objc private func textDidChange(_ textField: UITextField) {
        searchTimer.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { [weak self] (timer) in
            self?.resetData(textDidChangeTrue: true)
            self?.viewModel.searchText = textField.text ?? ""
            self?.showOrbisLoader()
            self?.viewModel.loadGroups()
        })
    }
}

extension GroupListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard isViewLoaded else { return 0 }
        guard viewModel != nil else { return 0}
        return viewModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let groupItemCell = tableView.dequeueReusableCell(withIdentifier: "groupItemCell") as! GroupListItemTableViewCell
        groupItemCell.viewModel = GroupItemViewModel(item: viewModel.getGroupItem(at: indexPath.row))
        return groupItemCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 105.toCGFloat.relativeToIphone8Width()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = .clear
        return footer
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15.toCGFloat.relativeToIphone8Width()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear
        return header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let group = viewModel.getGroupItem(at: indexPath.row)
        gotoGroupDetailView(withModel: group)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let loadMoreIndex = viewModel.count - 1
        if indexPath.row == loadMoreIndex && !isLoading && !viewModel.hasItemsLastPageReached {
            self.loadMore()
        }
    }
    
    private func gotoGroupDetailView(withModel model: Group) {
        let groupDetailsVC = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "groupDetailVC") as! GroupDetailsViewController
        groupDetailsVC.viewModel = GroupDetailViewModel(group: model)
        self.navigationController?.pushViewController(groupDetailsVC, animated: true)
    }
}
//MARK: Cache Management functionalities
extension GroupListViewController {
   func setupCacheObserver(){
       
       viewModel.$cachedGroups
           .receive(on: DispatchQueue.main) // Ensure it runs on the main thread
           .sink { [weak self] cachedGroups in
       
                guard let self = self else { return }

               // Check the specific initial load flag for mapPolygonPlaces
               if self.viewModel.isInitialcachedGroupsLoad {
                   self.viewModel.isInitialcachedGroupsLoad = false
                   return
               }
               
                // First session discards cache
                if Constants.newRankGroupSession {
                    self.resetData()
                    //Kamran Code
                    loadData()
                    //End of Kamran Code
                    Constants.newRankGroupSession = false
                    return
                }

                for group in cachedGroups {
                    if !self.contain(group: group) {
                        //self.groups.append(group)
                        self.viewModel.model.append(group.toGroup())
                    }
                }
               
               if self.viewModel.model.count > 0 {
                   self.resultTableView.reloadData()
               }

                if cachedGroups.isEmpty {
                    if Constants.location != nil {
                        self.viewModel.loadGroups()
                    }
                }

            }
            .store(in: &cancellables)
    }
    
    func contain(group: GroupDetails) -> Bool {
        for g in viewModel.model {
            if g.groupKey == group.groupKey {
                return true
            }
        }
        return false
    }

}
