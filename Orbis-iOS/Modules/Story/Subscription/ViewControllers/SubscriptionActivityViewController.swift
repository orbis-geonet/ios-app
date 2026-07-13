//
//  SubscriptionActivityViewController.swift
//  Orbis-iOS
//
//  Created by Vikas Sharma on 05/11/22.
//

import UIKit

class SubscriptionActivityViewController: OrbisLocalizableViewController {

    // MARK: - Outlets
    @IBOutlet weak var titleLabel: UILabel!

    // MARK: - Properties

    var group: Group!

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        updateStaticTexts()
    }

    override func updateStaticTexts() {
        titleLabel.text = AppStrings.Subscription.Activity.title
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? SubscriptionActivityTabViewController {
            vc.viewModel = SubscriptionActivityViewModel(group: group)
        }
    }

    // MARK: - Action Methods
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
