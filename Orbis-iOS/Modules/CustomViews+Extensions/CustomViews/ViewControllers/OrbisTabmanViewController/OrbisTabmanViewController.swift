//
//  OrbisTabmanViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 01/04/2021.
//

import Foundation
import Tabman
import Pageboy

protocol OrbisTabmanScrollDelegate: AnyObject {
    func orbisPageboyViewController(_ pageboyViewController: PageboyViewController, didScrollToPageAt index: TabmanViewController.PageIndex, direction: PageboyViewController.NavigationDirection, animated: Bool)
}

class OrbisTabmanViewController: TabmanViewController {
    
    weak var orbisTabmanScrollDelegate: OrbisTabmanScrollDelegate?
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController, didScrollToPageAt index: TabmanViewController.PageIndex, direction: PageboyViewController.NavigationDirection, animated: Bool) {
        super.pageboyViewController(pageboyViewController, didScrollToPageAt: index, direction: direction, animated: animated)
        orbisTabmanScrollDelegate?.orbisPageboyViewController(pageboyViewController, didScrollToPageAt: index, direction: direction, animated: animated)
    }
}
