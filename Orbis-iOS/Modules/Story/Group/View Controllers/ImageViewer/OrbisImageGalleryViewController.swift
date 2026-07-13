//
//  OrbisImageGalleryViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 07/06/2021.
//

import UIKit

class OrbisImageGalleryViewController: OrbisLocalizableViewController {
    @IBOutlet weak var imageCollectionView: UICollectionView!
    @IBOutlet weak var closeBtnLabel: UILabel!
    
    @IBAction func closeTapped(_ sender: Any) {
        onCloseTapped?()
    }
    
    var storageDirectory: ProjectStorageDirectories!
    var imagesString: [String] = []
    var preselectedIndex: Int? = nil
    var onCloseTapped: (() -> Void)?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGallery()
        imageCollectionView.reloadData()
        updateStaticTexts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let index = preselectedIndex {
            imageCollectionView.isPagingEnabled = false
            DispatchQueue.main.async {
                self.imageCollectionView.scrollToItem(
                    at: IndexPath(item: index, section: 0),
                    at: .centeredHorizontally,
                    animated: false
                )
            }
            imageCollectionView.isPagingEnabled = true
            preselectedIndex = nil
        }
    }
    
    override func updateStaticTexts() {
        closeBtnLabel.text = AppStrings.close
    }

    private func setupGallery() {
        imageCollectionView.delegate = self
        imageCollectionView.dataSource = self
    }
    
    
}

extension OrbisImageGalleryViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesString.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "galleryItem", for: indexPath) as! OrbisImageGalleryItemCollectionViewCell
        cell.placeholderImage = nil
        cell.storageDirectory = storageDirectory
        cell.imageString = imagesString[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
