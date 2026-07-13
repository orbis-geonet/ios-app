//
//  TextEditPopupViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 22/06/2021.
//

import UIKit
import KMPlaceholderTextView

enum TextEditContentType: String {
    case address
    case website
    case telephone
    case freeText
}

class TextEditPopupViewController: PopupViewController {
    
    @IBOutlet weak var contentView: RoundedView!
    @IBOutlet weak var contentTitleLabel: UILabel!
    @IBOutlet weak var textEditView: KMPlaceholderTextView!
    @IBOutlet weak var contentErrorLabel: UILabel!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    
    var saveBtnTitle = AppStrings.save
    var textViewPlaceholder = AppStrings.enterYourText
    var contentTitle: String = ""
    var contentText: String = ""
    var shouldProceedWithUnchanged = false
    var textViewKeyboardType: UIKeyboardType = .default
    var contentType: TextEditContentType = .freeText
    
    var onSave: ((String) -> Void)?
    
    @IBAction func didTapCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapSave(_ sender: Any) {
        trySave()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewComponents()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textEditView.becomeFirstResponder()
    }
    
    private func setupViewComponents() {
        saveBtn.setTitle(saveBtnTitle, for: .normal)
        textEditView.delegate = self
        textEditView.placeholder = textViewPlaceholder
        textEditView.keyboardType = textViewKeyboardType
        contentTitleLabel.text = contentTitle
        textEditView.text = contentText
        contentErrorLabel.isHidden = true
    }
    
    private func trySave() {
        if let error = ifContentValueValid() {
            contentErrorLabel.text = error.description
            contentErrorLabel.isHidden = false
            return
        }
        if contentText != textEditView.text {
            self.dismiss(animated: true) {
                [weak self] in
                guard let self = self else { return }
                self.onSave?(self.textEditView.text)
            }
        }
        else {
            if shouldProceedWithUnchanged {
                self.dismiss(animated: true) {
                    [weak self] in
                    guard let self = self else { return }
                    self.onSave?(self.textEditView.text)
                }
            }
            else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    private func ifContentValueValid() -> ValidationErrors? {
        switch self.contentType {
        case .address:
            if textEditView.text.isEmpty {
                return ValidationErrors.emptyPlaceAddress
            }
            return nil
        case .website:
            if textEditView.text.isEmpty {
                return ValidationErrors.emptyPlaceWebsite
            } else if textEditView.text.isValidLink {
                return nil
            }
            return ValidationErrors.invalidPlaceWebsite
        case .telephone:
            if textEditView.text.isEmpty {
                return ValidationErrors.emptyPlaceTelephone
            }
            return nil
        default:
            return nil
        }
    }
}

extension TextEditPopupViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        contentErrorLabel.text = ""
        contentErrorLabel.isHidden = true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        contentErrorLabel.text = ""
        contentErrorLabel.isHidden = true
    }
}
