//
//  MapMarkerInfoView.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/03/2021.
//

import UIKit
import CoreLocation

class MapMarkerInfoView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var storeIconView: UIImageView!
    @IBOutlet weak var storeNameLabel: UILabel!
    @IBAction func groupNameTapped(_ sender: Any) {
        onGroupNameTapped?(groupId, placeId)
    }
    @IBAction func placeNameTapped(_ sender: Any) {
        onPlaceNameTapped?(placeId)
    }
    
    var markerCoordinate: CLLocationCoordinate2D!
    var placeId: String!
    var groupId: String!
    var onGroupNameTapped: ((String, String) -> Void)?
    var onPlaceNameTapped: ((String) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit(){
        Bundle.main.loadNibNamed("MapMarkerInfoView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }

}
