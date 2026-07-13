//
//  ImagePostItemCollectionViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 07/04/2021.
//

import UIKit

class ImagePostItemCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var postImageView: UIImageView!
    var image: UIImage? {
        didSet {
            postImageView.image = image
        }
    }
}
