//
//  Orbis_TableViewCellExtension.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 06/05/2021.
//

import UIKit

let cellPendingViewOverlayTag = 20210506
let cellPendingPostLoaderTag = 20210507

extension UITableViewCell {
    func addLoadingOverlay() {
        removeExistingLoadingOverlay()
        let view = UIView()
        view.tag = cellPendingViewOverlayTag
        view.backgroundColor = UIColor.white.withAlphaComponent(0.55)
        view.translatesAutoresizingMaskIntoConstraints = false
        let size = 25.toCGFloat.relativeToIphone8Width()
        let appLoader = UIUtil.getAppPendingPostLoader(height: size, width: size)
        appLoader.backgroundColor = .clear
        appLoader.setRadius(radius: CGFloat(10).relativeToIphone8Width())
        appLoader.tag = cellPendingPostLoaderTag
        view.hideOrbisLoader(withTag: cellPendingPostLoaderTag)
        view.addSubview(appLoader)
        appLoader.translatesAutoresizingMaskIntoConstraints = false
        appLoader.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15.toCGFloat.relativeToIphone8Width()).isActive = true
        appLoader.topAnchor.constraint(equalTo: view.topAnchor, constant: 15.toCGFloat.relativeToIphone8Width()).isActive = true
        appLoader.widthAnchor.constraint(equalToConstant: size).isActive = true
        appLoader.heightAnchor.constraint(equalToConstant: size).isActive = true
        view.bringSubviewToFront(appLoader)
        appLoader.play()
        DispatchQueue.main.async {
            [weak self] in
            guard let self = self else { return }
            self.contentView.addSubview(view)
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
                view.topAnchor.constraint(equalTo: self.contentView.topAnchor),
                view.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
            ])
            self.contentView.bringSubviewToFront(view)
        }
    }
    
    func removeExistingLoadingOverlay() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.contentView.subviews.forEach { view in
                if view.tag == cellPendingViewOverlayTag {
                    view.removeFromSuperview()
                }
            }
        }
    }
    
    func setSelectedUI(color: UIColor = UIColor(named: AppColors.appSelectionBlue.rawValue)!) {
        self.contentView.backgroundColor = color
    }
    
    func setDeselectedSelectedUI(color: UIColor = .white) {
        self.contentView.backgroundColor = color
    }
}
