//
//  CreateGroupViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 30/03/2021.
//

import UIKit
import KMPlaceholderTextView

class CreateGroupViewController: OrbisLocalizableViewController {
    
    @IBOutlet weak var chooseColorLabel: UILabel!
    @IBOutlet weak var parentScrollView: UIScrollView!
    @IBOutlet weak var groupProPicContainerView: RoundedView!
    @IBOutlet weak var groupPhotoImageView: UIImageView!
    @IBOutlet weak var groupColorsCollectionView: UICollectionView!
    @IBOutlet weak var groupNameTextField: UITextField!
    @IBOutlet weak var groupNameLinkLabel: UILabel!
    @IBOutlet weak var groupDescriptionTextView: KMPlaceholderTextView!
    @IBOutlet weak var camerIconView: UIImageView!
    @IBOutlet weak var createBtn: UIButton!
    
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func uploadPhotoTapped(_ sender: Any) {
        openImagePickerView()
    }
    @IBAction func createTapped(_ sender: Any) {
        showCreateAlertView()
    }
    
    var viewModel: CreateGroupViewModel!
    var config: YPImagePickerConfiguration!
    var imagePickerController: YPImagePicker!
    var onGroupEdit: ((Group) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionViewsSetup()
        configureInputFields()
        updateStaticTexts()
    }
    
    override func updateStaticTexts() {
        chooseColorLabel.text = AppStrings.Group.Create.chooseColor
        groupNameTextField.placeholder = AppStrings.Group.Create.groupNamePlaceholder
        groupDescriptionTextView.placeholder = AppStrings.Group.Create.groupDescriptionPlaceholder
        createBtn.setTitle(AppStrings.Group.Create.createGroup, for: .normal)
    }
    
    private func setupImagePickerView() {
        config = YPImagePicker.getAppImageViewConfig()
        imagePickerController = YPImagePicker(configuration: config)
        imagePickerController.didFinishPicking { [weak self] (items, success) in
            guard let strongSelf = self else {
                self?.imagePickerController.dismiss(animated: true, completion: nil)
                return
            }
            if let photo = items.singlePhoto {
                let img = photo.modifiedImage ?? photo.originalImage
                strongSelf.viewModel.selectedImage = img
                strongSelf.updateProPicSelectionUpdate()
            }
            self?.imagePickerController.dismiss(animated: true, completion: nil)
        }
    }
    
    func showCreateAlertView() {
        viewModel.validateFields { [weak self] (data, err) in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                if self?.viewModel.isEditMode == true {
                    self?.proceedEditGroup()
                }
                else {
                    self?.displayCreateAlert()
                }
            }
        }
    }
    
    private func displayCreateAlert() {
        let alertVC = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "createGroupAlertVC") as! CreateGroupAlertViewController
        alertVC.modalPresentationStyle = .overFullScreen
        alertVC.shouldDismissViewOnTapOutside = false
        alertVC.shouldAddFullOverlay = true
        alertVC.onUnderstoodTapped = {
            [weak self] in
            self?.proceedCreateGroup()
        }
        self.present(alertVC, animated: true, completion: nil)
    }
    
    private func proceedEditGroup() {
        self.showOrbisLoader(disableUserInteraction: true)
        self.view.endEditing(true)
        viewModel.tryCreateGroup { [weak self] (data, err) in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.handleCreateSuccess(forGroup: data as! Group)
            }
            self?.hideOrbisLoader()
        }
    }
    
    private func proceedCreateGroup() {
        self.showOrbisLoader(disableUserInteraction: true)
        self.view.endEditing(true)
        viewModel.tryCreateGroup { [weak self] (data, err) in
            if let error = err {
                self?.handleError(error: error)
            }
            else {
                self?.handleCreateSuccess(forGroup: data as! Group)
            }
            self?.hideOrbisLoader()
        }
    }
    
    private func handleCreateSuccess(forGroup group: Group) {
        guard let navigationController = self.navigationController else { return }
        let groupDetailsVC = UIStoryboard.getViewController(inStoryboard: "Group", identifier: "groupDetailVC") as! GroupDetailsViewController
        groupDetailsVC.viewModel = GroupDetailViewModel(group: group)
        self.onGroupEdit?(group)
        self.navigationController?.pushViewController(groupDetailsVC, animated: true)
        var navigationArray = navigationController.viewControllers // To get all UIViewController stack as Array
        navigationArray.remove(at: navigationArray.count - 2) // To remove previous UIViewController
        self.navigationController?.viewControllers = navigationArray
    }
    
    func openImagePickerView() {
        setupImagePickerView()
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    func updateProPicSelectionUpdate() {
        if let img = viewModel.selectedImage {
            self.groupPhotoImageView.image = img
            camerIconView.isHidden = true
        }
        else {
            if let imgLink = viewModel.group.imageName, !imgLink.isEmpty {
                groupPhotoImageView.setSDWebImage(urlString: imgLink, placeholderImage: nil, storageDirectory: .groupPictures, sizeModifier: .fourHundred)
                camerIconView.isHidden = true
            }
            else {
                camerIconView.isHidden = false
            }
        }
    }
    
    func configureInputFields() {
        groupNameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        groupDescriptionTextView.delegate = self
        
        createBtn.setTitle(viewModel.saveText, for: .normal)
        
        groupNameTextField.text = viewModel.name
        groupNameLinkLabel.text = viewModel.staticLinkText + viewModel.name.replacingOccurrences(of: " ", with: "")
        groupDescriptionTextView.text = viewModel.description
        updateProPicSelectionUpdate()
        updateColorSelection()
    }
    
    func collectionViewsSetup() {
        groupColorsCollectionView.dataSource = self
        groupColorsCollectionView.delegate = self
    }
    
    func updateColorSelection() {
        let hasSelectedColor = (viewModel.baseColor != nil)
        groupProPicContainerView.borderWidth = hasSelectedColor ? 6.toCGFloat.relativeToIphone8Width() : 0
        groupProPicContainerView.borderColor = viewModel.baseColor
        groupColorsCollectionView.reloadData()
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        guard textField == groupNameTextField else { return }
        viewModel.name = textField.text ?? ""
        groupNameLinkLabel.text = viewModel.staticLinkText + viewModel.name.replacingOccurrences(of: " ", with: "")
    }
}

extension CreateGroupViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        guard textView == groupDescriptionTextView else { return }
        viewModel.description = textView.text
    }
}

extension CreateGroupViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard viewModel != nil else {
            return 0
        }
        return viewModel.colorCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "colorItem", for: indexPath) as! CGColorSelectionItemCollectionViewCell
        let selectedIndex = viewModel.selectedColorIndex
        cell.updateContent(withColor: viewModel.getColor(at: indexPath.row), isSelected: selectedIndex == indexPath.row)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.height, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 15.toCGFloat.relativeToIphone8Width()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 15.toCGFloat.relativeToIphone8Width()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectedColorIndex = indexPath.row
        updateColorSelection()
    }
}
