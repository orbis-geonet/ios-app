//
//  OrbisExpandableLabel.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 05/05/2021.
//

import ExpandableLabel

class OrbisExpandableLabel: ExpandableLabel {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.textReplacementType = .character
    }
}
