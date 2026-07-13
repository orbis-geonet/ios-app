//
//  TableViewExtension.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/03/2021.
//

import UIKit

extension UITableView {
    open override func awakeFromNib() {
        self.tableFooterView = UIView(frame: .zero)
    }
    
    func scrollToLastItem(animated: Bool = true) {
        let sections = self.numberOfSections
        let rows = self.numberOfRows(inSection: sections - 1)
        if (rows > 0){
            DispatchQueue.main.async {
                self.scrollToRow(at: IndexPath(row: rows - 1, section: sections - 1), at: .bottom, animated: animated)
            }
        }
    }
}

extension UIScrollView {

    func scrollToBottom(animated: Bool) {
        var y: CGFloat = 0.0
        let HEIGHT = self.frame.size.height
        if self.contentSize.height > HEIGHT {
            y = self.contentSize.height - HEIGHT
        }
        DispatchQueue.main.async {
            self.setContentOffset(CGPoint(x: 0, y: y), animated: animated)
        }
    }
}
