//
//  CreateSubscriptionAddressViewController.swift
//  Orbis-iOS
//
//  Created by Vikas Sharma on 01/11/22.
//

import UIKit

class CreateSubscriptionAddressViewController: OrbisLocalizableViewController {

    // MARK: - Outlets
    

    // MARK: - Properties
    var subscriptionCreated: ((_ status: Bool) -> Void)?

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    // MARK: - Action Methods
    @IBAction func actionButtonBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: false)
    }

    @IBAction func actionButtonNext(_ sender: UIButton) {
        subscriptionCreated?(true)
        self.navigationController?.popViewController(animated: true)
    }
}
