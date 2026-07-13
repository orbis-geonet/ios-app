//
//  StoryLargeTextViewer.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 17/04/2021.
//

import UIKit

class StoryLargeTextViewer: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var readLessBtn: UIButton!
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    
    @IBAction func readLessTapped(_ sender: Any) {
        onReadLessTapped?()
    }
    
    var onReadLessTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit(){
        Bundle.main.loadNibNamed("StoryLargeTextViewer", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }

}
