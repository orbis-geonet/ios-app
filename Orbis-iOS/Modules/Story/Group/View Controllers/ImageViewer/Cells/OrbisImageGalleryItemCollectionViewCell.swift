//
//  OrbisImageGalleryItemCollectionViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 07/06/2021.
//

import UIKit
import SDWebImage

class OrbisImageGalleryItemCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.maximumZoomScale = 4
            scrollView.minimumZoomScale = 1
            scrollView.delegate = self
        }
    }
    
    var activityIndicator = UIActivityIndicatorView(style: .large)
    var storageDirectory: ProjectStorageDirectories!
    var imageString: String! {
        didSet {
            loadImage()
        }
    }
    var placeholderImage: UIImage?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor)
        ])
        self.contentView.bringSubviewToFront(activityIndicator)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
        activityIndicator.stopAnimating()
    }
    
    private func loadImage() {
        if storageDirectory == ProjectStorageDirectories.none {
            guard let url = URL(string: imageString) else { return }
            activityIndicator.startAnimating()
            imageView.sd_setImage(with: url) {
                [weak self] image, err, cache, ref in
                self?.activityIndicator.stopAnimating()
            }
            return
        }
        guard imageString.isNotUrlLink else {
            guard let url = URL(string: imageString) else { return }
            activityIndicator.startAnimating()
            imageView.sd_setImage(with: url) {
                [weak self] image, err, cache, ref in
                self?.activityIndicator.stopAnimating()
            }
            return
        }
        let ref = imageString.getFirebaseReference(storage: storageDirectory, imageSizeResolution: .sixEighty)
        activityIndicator.startAnimating()
        imageView.sd_setImage(with: ref, placeholderImage: placeholderImage) { [weak self] image, err, cache, ref in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.placeholderImage = image
            self.imageView.image = image
            let hdRef = self.imageString.getFirebaseFileStorageReference(storage: self.storageDirectory)
            self.imageView.sd_setImage(with: hdRef, placeholderImage: self.placeholderImage)
        }
    }
}

extension OrbisImageGalleryItemCollectionViewCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        guard let _ = imageView.image else { return nil}
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.zoomScale > 1 {
            if let image = imageView.image {
                let ratioW = imageView.frame.width / image.size.width
                let ratioH = imageView.frame.height / image.size.height
                
                let ratio = ratioW < ratioH ? ratioW : ratioH
                let newWidth = image.size.width * ratio
                let newHeight = image.size.height * ratio
                let conditionLeft = newWidth*scrollView.zoomScale > imageView.frame.width
                let left = 0.5 * (conditionLeft ? newWidth - imageView.frame.width : (scrollView.frame.width - scrollView.contentSize.width))
                let conditioTop = newHeight*scrollView.zoomScale > imageView.frame.height
                
                let top = 0.5 * (conditioTop ? newHeight - imageView.frame.height : (scrollView.frame.height - scrollView.contentSize.height))
                
                scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
                
            }
        } else {
            scrollView.contentInset = .zero
        }
    }
}
