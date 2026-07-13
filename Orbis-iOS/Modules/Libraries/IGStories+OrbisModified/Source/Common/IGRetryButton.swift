//
//  IGRetryButton.swift
//  InstagramStories
//
//  Created by Boominadha Prakash on 15/07/18.
//  Copyright © 2018 DrawRect. All rights reserved.
//

import Foundation
import UIKit

protocol RetryBtnDelegate: AnyObject {
    func retryButtonTapped()
}

public class IGRetryLoaderButton: UIButton {
    var contentURL: String?
    var contentSuperView: UIView?
    weak var delegate: RetryBtnDelegate?
    convenience init(withURL url: String) {
        self.init()
        self.backgroundColor = UIColor.black
        self.frame = CGRect(x: 0, y: 0, width: 60.toCGFloat.relativeToIphone8Width(), height: 60.toCGFloat.relativeToIphone8Width())
        self.setImage(#imageLiteral(resourceName: "reload-story-ic"), for: .normal)
        self.tintColor = UIColor.white
        self.addTarget(self, action: #selector(didTapRetryBtn), for: .touchUpInside)
        self.contentURL = url
        self.tag = 100
    }
    @objc func didTapRetryBtn() {
        delegate?.retryButtonTapped()
    }
}

extension UIView {
    func removeRetryButton() {
        self.subviews.forEach({v in
            if(v.tag == 100){v.removeFromSuperview()}
        })
    }
    
}
