//
//  SettingsLanguageSelectionViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 12/04/2021.
//

import UIKit

class SettingsLanguageSelectionViewController: OrbisLocalizableViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var resultView: UITableView!
    
    @IBAction func backTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func searchIconTapped(_ sender: Any) {
        searchTextField.becomeFirstResponder()
    }
    
    var viewModel: SettingsLanguageListViewModel!
    var onLanguageSelected: ((String) -> Void)?
    
    override func topOffset() -> CGFloat {
        return 0
    }
    
    override func showDragIndicator() -> Bool {
        return false
    }

    override func shouldRespond(toPanModalGestureRecognizer panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        let panGesturePoint = panGestureRecognizer.location(in: self.view)
        if resultView.frame.contains(panGesturePoint) {
            return resultView.contentOffset.y <= 0
        }
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        updateStaticTexts()
    }
    
    override func updateStaticTexts() {
        titleLabel.text = AppStrings.Settings.language
        searchTextField.placeholder = AppStrings.Settings.languageSearchPlaceholder
    }
    
    func setupTableView() {
        resultView.dataSource = self
        resultView.delegate = self
        resultView.reloadData()
    }
}

extension SettingsLanguageSelectionViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel != nil else { return 0}
        return viewModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewModel.getLanguage(at: indexPath.row)
        let cell = tableView.dequeueReusableCell(withIdentifier: "languageItemCell") as! SettingsLanguageItemTableViewCell
        cell.nameLabel.text = model.capitalized
        cell.updateSelection(isSelected: model == viewModel.selectedLanguage)
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = viewModel.getLanguageCode(at: indexPath.row)
        self.dismiss(animated: true) { [weak self] in
            self?.onLanguageSelected?(model)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15.toCGFloat.relativeToIphone8Width()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear
        return header
    }
}

