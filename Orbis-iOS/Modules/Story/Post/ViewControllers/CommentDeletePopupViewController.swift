//
//  CommentDeletePopupViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 12/08/2021.
//

import Foundation
import UIKit

class CommentDeletePopupViewController: PopupViewController {

    
    @IBAction func deleteTapped(_ sender: Any) {
        self.dismiss(animated: true) {
            [weak self] in
            guard let self = self else { return }
            self.onDeleteTapped?(self.commentModel.commentKey)
        }
    }
    
    var commentModel: PostComment!
    
    var onDeleteTapped: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}
