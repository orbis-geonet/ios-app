//
//  OrbisActiveLabel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/05/2021.
//

import Foundation
import ActiveLabel

struct OrbisActiveLabelConfiguration {
    static let urlUnselectedColor = UIColor(named: AppColors.appBlue.rawValue)!
    static let urlSelectedColor = UIColor(named: AppColors.appWarmGray2.rawValue)!
}

class OrbisActiveLabel: ActiveLabel {
    
//    lazy var expandableButtonLabel = UILabel(frame: .zero)
//    var shouldExpand = false
//    var isExpanded = false {
//        didSet {
//            expandableButtonLabel.text = expandableButtonText
//            self.numberOfLines = isExpanded ? 0 : maxCollapsedLine
//            self.layoutIfNeeded()
//        }
//    }
//    var maxCollapsedLine = 5
//
//    var expandedText: String = "View less"
//    var collapsedText: String = " ...View more"
//    var expandableButtonColor: UIColor = UIColor(named: AppColors.appBlack.rawValue) ?? .blue
//    var expandableButtonFont: UIFont = UIFont(name: "Roboto-Medium", size: 12.toCGFloat.relativeToIphone8Width()) ?? .boldSystemFont(ofSize: 12.toCGFloat.relativeToIphone8Width())
//
//    private var expandableButtonText: String {
//        return isExpanded ? expandedText : collapsedText
//    }
//
//    var onExpandableButtonTapped: ((UILabel) -> Void)?
    
//    override var text: String? {
//        didSet {
//            self.numberOfLines = maxCollapsedLine
//            let lines = self.calculateMaxLines()
//            shouldExpand = lines > maxCollapsedLine
//            if shouldExpand {
//                addExpandableButton()
//                isExpanded = false
//            }
//            else {
//                removeExpandableButton()
//            }
//        }
//    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeOrbisActiveLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeOrbisActiveLabel()
    }
    
//    private func removeExpandableButton() {
//        expandableButtonLabel.removeFromSuperview()
//    }
//
//    private func addExpandableButton() {
//        expandableButtonLabel.removeFromSuperview()
//        expandableButtonLabel = UILabel()
//        expandableButtonLabel.backgroundColor = .white
//        expandableButtonLabel.text = expandableButtonText
//        expandableButtonLabel.font = expandableButtonFont.withSize(self.font.pointSize - 1)
//        expandableButtonLabel.textColor = expandableButtonColor
//        self.addSubview(expandableButtonLabel)
//        expandableButtonLabel.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            expandableButtonLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
//            expandableButtonLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor)
//        ])
//        expandableButtonLabel.isHidden = !shouldExpand
//        expandableButtonLabel.isUserInteractionEnabled = true
//        let expandedTapGesture = UITapGestureRecognizer(target: self, action: #selector(expandableButtonTapped(_:)))
//        expandableButtonLabel.addGestureRecognizer(expandedTapGesture)
//    }
//
//    @objc private func expandableButtonTapped(_ sender: Any) {
//        isExpanded = !isExpanded
//        onExpandableButtonTapped?(self)
//    }
    
    private func initializeOrbisActiveLabel() {
        applyOrbisActiveLabelConfiguration()
        self.handleURLTap { (url) in
            var newUrlString = url.absoluteString
            newUrlString = newUrlString.toProperURLString
            guard let newURL = URL(string: newUrlString) else { return }
            UIApplication.shared.open(newURL, options: [:], completionHandler: nil)
        }
    }
    
    private func applyOrbisActiveLabelConfiguration() {
        self.URLColor = OrbisActiveLabelConfiguration.urlUnselectedColor
        self.URLSelectedColor = OrbisActiveLabelConfiguration.urlSelectedColor
        self.hashtagColor = OrbisActiveLabelConfiguration.urlUnselectedColor
        self.hashtagSelectedColor = OrbisActiveLabelConfiguration.urlUnselectedColor
        self.mentionSelectedColor = OrbisActiveLabelConfiguration.urlUnselectedColor
        self.mentionColor = OrbisActiveLabelConfiguration.urlUnselectedColor
        self.minimumLineHeight = CGFloat(20).relativeToIphone8Width()
    }
}

