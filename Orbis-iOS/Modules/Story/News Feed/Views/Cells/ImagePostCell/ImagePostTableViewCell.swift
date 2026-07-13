//
//  ImagePostTableViewCell.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 27/03/2021.
//

import UIKit
import SDWebImage


protocol FeedImageFullViewDelegate: AnyObject {
    func didTapImage(at index: Int, inCell cell: UITableViewCell)
}

class ImagePostTableViewCell: UITableViewCell {
    
    @IBOutlet weak var postOwnerProPicView: UIImageView!
    @IBOutlet weak var postOwnerProPicContainer: RoundedView!
    @IBOutlet weak var postOwnerNameLabel: UILabel!
    @IBOutlet weak var postedDateLabel: UILabel!
    @IBOutlet weak var postedLocationLabel: UILabel!
    @IBOutlet weak var locationStackView: UIStackView!
    @IBOutlet weak var imageCollectionView: UICollectionView!
    @IBOutlet weak var imageCountPageControl: UIPageControl!
    @IBOutlet weak var imageCountIndicatorView: RoundedView!
    @IBOutlet weak var imageCountLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: OrbisActiveLabel!
    
    @IBOutlet weak var likeIconView: UIImageView!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var commentIconView: UIImageView!
    @IBOutlet weak var commentCountLabel: UILabel!

    @IBOutlet weak var bottomUserInfoView: UIStackView!
    @IBOutlet weak var bottomStackViewSpacer: UIView!
    @IBOutlet weak var moreBtnView: UIView!
    @IBOutlet weak var likeStackView: UIStackView!
    @IBOutlet weak var commentStackView: UIStackView!
    
    
    @IBOutlet weak var subPosterNameLabel: UILabel!
    @IBOutlet weak var subPosterImageView: UIImageView!
    
    @IBOutlet weak var richTextContentStack: UIStackView!
    @IBOutlet weak var externalUrlImageView: UIImageView!
    @IBOutlet weak var externalUrlDomainLabel: UILabel!
    @IBOutlet weak var externalUrlTitleLabel: UILabel!
    @IBOutlet weak var externalUrlDescriptionLabel: UILabel!
    @IBOutlet weak var viewMoreBtn: UIButton!
    
    @IBAction func moreTapped(_ sender: Any) {
        actionDelegate?.didTapMore(onCell: self, tappedView: moreBtnView, post: viewModel.model)
    }
    
    @IBAction func expandTextTapped(_ sender: Any) {
        var newPost = viewModel.model!
        newPost.isDescriptionExpanded = !newPost.isDescriptionExpanded
        actionDelegate?.didTapViewMore(onCell: self, post: newPost, maxLines: descriptionLabel.calculateMaxLines())
    }
    
    @IBAction func pageControlValueChanged(_ sender: Any) {
        guard imageCountPageControl != nil else { return }
        guard isTap else {
            updateCurrentDisplayImageIndicator()
            return
        }
        isTap = false
        let currentPage = imageCountPageControl.currentPage
        let pageWidth = self.imageCollectionView.frame.size.width
        let scrollTo = CGPoint(x: pageWidth * currentPage.toCGFloat, y: 0)
        imageCollectionView.setContentOffset(scrollTo, animated: true)
        updateCurrentDisplayImageIndicator()
    }
    
    var sliderCurrentIndex: Int = 0
    var isTap = true
    
    var viewModel: ImagePostCellViewModel! {
        didSet {
            updateViewContent()
        }
    }
    
    weak var imageFullSizeDeleage: FeedImageFullViewDelegate?
    weak var actionDelegate: PostCellActionDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        let commentTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapCommentStack(_:)))
        commentStackView.isUserInteractionEnabled = true
        commentStackView.addGestureRecognizer(commentTapGesture)
        configureImageCollectionView()
        
        let likeTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapLikeStack(_:)))
        likeIconView.isUserInteractionEnabled = true
        likeIconView.addGestureRecognizer(likeTapGesture)
        
        let richContentTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapRichContent(_:)))
        richTextContentStack.isUserInteractionEnabled = true
        richTextContentStack.addGestureRecognizer(richContentTapGesture)
        
        let locationTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapLocationStack(_:)))
        locationStackView.isUserInteractionEnabled = true
        locationStackView.addGestureRecognizer(locationTapGesture)
        
        let postOwnerNameTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPostOwner(_:)))
        let postOwnerPicTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPostOwner(_:)))
        postOwnerNameLabel.isUserInteractionEnabled = true
        postOwnerNameLabel.addGestureRecognizer(postOwnerNameTapGesture)
        postOwnerProPicContainer.isUserInteractionEnabled = true
        postOwnerProPicContainer.addGestureRecognizer(postOwnerPicTapGesture)
        
        let postUserStackTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPostUser(_:)))
        bottomUserInfoView.isUserInteractionEnabled = true
        bottomUserInfoView.addGestureRecognizer(postUserStackTapGesture)
    }
    
    @objc private func didTapPostUser(_ gesture: UIGestureRecognizer) {
        guard let user = viewModel.model.user else { return }
        actionDelegate?.didTapUserStack(onCell: self, user: user)
    }
    
    @objc private func didTapPostOwner(_ gesture: UIGestureRecognizer) {
        guard let group = viewModel.model.group else {
            if let user = viewModel.model.user {
                actionDelegate?.didTapUserStack(onCell: self, user: user)
            }
            return
        }
        actionDelegate?.didTapGroupName(onCell: self, group: group)
    }
    
    private func configureImageCollectionView() {
        imageCollectionView.register(UINib(nibName: "ImagePostImageContentCellCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "imageItemCell")
        imageCollectionView.delegate = self
        imageCollectionView.dataSource = self
    }
    
    @objc private func didTapLocationStack(_ gesture: UIGestureRecognizer) {
        guard let place = viewModel.model.place else { return }
        actionDelegate?.didTapLocationStack(onCell: self, place: place)
    }
    
    @objc private func didTapCommentStack(_ gesture: UIGestureRecognizer) {
        actionDelegate?.didTapCommentStack(onCell: self, post: viewModel.model)
    }
    
    @objc private func didTapLikeStack(_ gesture: UIGestureRecognizer) {
        actionDelegate?.didTapLikeStack(onCell: self, post: viewModel.model)
    }

    @objc private func didTapRichContent(_ gesture: UIGestureRecognizer) {
        guard let urlString = viewModel.richContent?.originalUrl, let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateViewContent() {
        postOwnerProPicContainer.borderColor = viewModel.posterBaseColor
        postOwnerNameLabel.text = viewModel.posterFullName
        postedDateLabel.text = viewModel.datePostedString
        postedLocationLabel.text = viewModel.locationString
        descriptionLabel.text = viewModel.description
        descriptionLabel.isHidden = viewModel.description.isEmpty
        fillRichTextContent()
        let likeColor = viewModel.likeIconColor
        likeIconView.tintColor = likeColor
        likeCountLabel.textColor = likeColor
        likeCountLabel.text = viewModel.likeCountString
        commentCountLabel.text = viewModel.commentCountString
        bottomUserInfoView.isHidden = !viewModel.shouldShowBottomUser
        bottomStackViewSpacer.isHidden = viewModel.shouldShowBottomUser
        locationStackView.isHidden = viewModel.locationString.isEmpty
        fillSubPosterDetail()
        updateProfilePic()
        updatePageControlUI(withCount: 0)
        imageCollectionView.reloadData()
        if viewModel.imageCount > 0 {
            imageCollectionView.scrollToItem(at: IndexPath(row: viewModel.currentPageIndex, section: 0), at: .centeredVertically, animated: false)
        }
        descriptionLabel.numberOfLines = viewModel.numberOfLines
        viewMoreBtn.isHidden = !(descriptionLabel.calculateMaxLines() > AppValues.postTextMaxLines)
        updateTextMoreBtnText()
    }
    
    private func updateTextMoreBtnText() {
        let title = (descriptionLabel.numberOfLines == 0) ? AppStrings.viewLess : AppStrings.viewMore
        viewMoreBtn.setTitle(title, for: .normal)
    }
    
    private func fillRichTextContent() {
        richTextContentStack.isHidden = !viewModel.hasRichTextContent
        if var imageUrl = viewModel.richContent?.imageUrl, !imageUrl.isEmpty {
            self.externalUrlImageView.isHidden = false
            if !imageUrl.contains("http") && !imageUrl.contains("www.") {
                if let originalUrl = viewModel.richContent?.originalUrl, !originalUrl.isEmpty {
                    imageUrl = originalUrl + "/\(imageUrl)"
                }
            }
            imageUrl = imageUrl.toProperURLString
            externalUrlImageView.sd_setImage(with: URL(string: imageUrl)) {
                [weak self] image, error, _ , _ in
                if image == nil || error != nil {
                    self?.externalUrlImageView.isHidden = true
                }
            }
        }
        else {
            self.externalUrlImageView.isHidden = true
        }
        externalUrlTitleLabel.text = viewModel.richContent?.title ?? ""
        externalUrlDomainLabel.text = viewModel.richContent?.canonicalUrl?.uppercased() ?? ""
        externalUrlDescriptionLabel.text = viewModel.richContent?.description ?? ""
    }
    
    private func updateCurrentDisplayImageIndicator() {
        let count = viewModel.imageCount
        let currentImageIndex = sliderCurrentIndex + 1
        imageCountLabel.text = "\(currentImageIndex)/\(count)"
    }
    
    private func updateProfilePic() {
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.posterProPicLink.isEmpty else {
            postOwnerProPicView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.posterProPicLink
        
        postOwnerProPicView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: (viewModel.model.group != nil) ? .groupPictures : .profilePictures, sizeModifier: .fourHundred)
    }
    
    private func fillSubPosterDetail() {
        subPosterNameLabel.text = viewModel.subPosterFullName
        let placeholderImage = UIImage(named: "map-user-head-ic")
        guard !viewModel.subPosterProPicLink.isEmpty else {
            subPosterImageView.image = placeholderImage
            return
        }
        let proPicLink = viewModel.subPosterProPicLink
        subPosterImageView.setSDWebImage(urlString: proPicLink, placeholderImage: placeholderImage, storageDirectory: .profilePictures, sizeModifier: .fourHundred)
    }
    
    private func updatePageControlUI(withCount count: Int) {
        imageCountPageControl.numberOfPages = count
        imageCountPageControl.currentPage = sliderCurrentIndex
        imageCountPageControl.isHidden = count <= 1
        imageCountIndicatorView.isHidden = count <= 1
        updateCurrentDisplayImageIndicator()
    }
    
}

extension ImagePostTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard viewModel != nil else {
            return 0
        }
        let count = viewModel.imageCount
        updatePageControlUI(withCount: count)
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageItemCell", for: indexPath) as! ImagePostImageContentCellCollectionViewCell
        let url: String? = viewModel.isPendingPost ? nil : viewModel.getImageLink(at: indexPath.row)
        let image: UIImage? = viewModel.isPendingPost ? viewModel.getImage(at: indexPath.row) : nil
        cell.setImage(url: url, image: image)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.imageFullSizeDeleage?.didTapImage(at: indexPath.row, inCell: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 260.toCGFloat.relativeToIphone8Width())
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

extension ImagePostTableViewCell: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == imageCollectionView else { return }
        guard isTap else { return }
        let witdh = scrollView.frame.width - (scrollView.contentInset.left*2)
        let index = scrollView.contentOffset.x / witdh
        let roundedIndex = round(index)
        self.sliderCurrentIndex = Int(roundedIndex)
        self.imageCountPageControl.currentPage = Int(roundedIndex)
        self.viewModel.currentPageIndex = self.imageCountPageControl.currentPage
        updateCurrentDisplayImageIndicator()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == imageCollectionView else { return }
        self.sliderCurrentIndex = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        imageCountPageControl?.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        updateCurrentDisplayImageIndicator()
        self.viewModel.currentPageIndex = self.imageCountPageControl.currentPage
        isTap = true
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView == imageCollectionView else { return }
        self.sliderCurrentIndex = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        imageCountPageControl?.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        isTap = true
        self.viewModel.currentPageIndex = self.imageCountPageControl.currentPage
        updateCurrentDisplayImageIndicator()
    }
}
