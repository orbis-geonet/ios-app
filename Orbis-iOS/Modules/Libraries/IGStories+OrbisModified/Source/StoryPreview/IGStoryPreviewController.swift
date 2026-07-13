//
//  OrbisStoryPreviewController.swift
//  InstagramStories
//
//  Created by Boominadha Prakash on 06/09/17.
//  Copyright © 2017 DrawRect. All rights reserved.
//

import UIKit
import HWPanModal
import GoogleMobileAds

fileprivate let isClearCacheEnabled = true
internal var isDeleteSnapEnabled = false

protocol OrbisStoryActionDelegate: AnyObject {
    func didDismissStoryPreview()
    func didSeenStory(key: String)
}

/**Road-Map: Story(CollectionView)->Cell(ScrollView(nImageViews:Snaps))
 If Story.Starts -> Snap.Index(Captured|StartsWith.0)
 While Snap.done->Next.snap(continues)->done
 then Story Completed
 */
final class OrbisStoryPreviewController: UIViewController, UIGestureRecognizerDelegate {
    
    //MARK: - Private Vars
    private var _view: OrbisStoryPreviewView {return view as! OrbisStoryPreviewView}
    private var viewModel: OrbisStoryPreviewModel?
    
    private var stories: [OrbisStory]
    /** This index will tell you which Story, user has picked*/
    private(set) var handPickedStoryIndex: Int //starts with(i)
    /** This index will tell you which Snap, user has picked*/
    private(set) var handPickedSnapIndex: Int //starts with(i)
    /** This index will help you simply iterate the story one by one*/
    
    private var nStoryIndex: Int = 0 //iteration(i+1)
    private var story_copy: OrbisStory?
    private(set) var layoutType: IGLayoutType
    private(set) var executeOnce = false
    
    //check whether device rotation is happening or not
    private(set) var isTransitioning = false
    private(set) var currentIndexPath: IndexPath?
    
    var storyViewedCount = 0
    private var interstitialAd: InterstitialAd?
    
    private let dismissGesture: UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer()
        gesture.direction = .down
        return gesture
    }()
    private let showActionSheetGesture: UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer()
        gesture.direction = .up
        return gesture
    }()
    private var currentCell: OrbisStoryPreviewCell? {
        guard let indexPath = self.currentIndexPath else {
            debugPrint("Current IndexPath is nil")
            return nil
        }
        return self._view.snapsCollectionView.cellForItem(at: indexPath) as? OrbisStoryPreviewCell
    }
    lazy private var actionSheetController: UIAlertController = {
        let alertController = UIAlertController(title: "Orbis Stories", message: "More Options", preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteSnap()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.currentCell?.resumeEntireSnap()
        }
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        return alertController
    }()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    weak var storyActionDelegate: OrbisStoryActionDelegate?
    
    //MARK: - Overriden functions
    override func loadView() {
        super.loadView()
        view = OrbisStoryPreviewView.init(layoutType: self.layoutType)
        viewModel = OrbisStoryPreviewModel.init(self.stories, self.handPickedStoryIndex)
        _view.snapsCollectionView.decelerationRate = .fast
        dismissGesture.delegate = self
        dismissGesture.addTarget(self, action: #selector(didSwipeDown(_:)))
        _view.snapsCollectionView.addGestureRecognizer(dismissGesture)
        
        // This should be handled for only currently logged in user story and not for all other user stories.
        if(isDeleteSnapEnabled) {
            showActionSheetGesture.delegate = self
            showActionSheetGesture.addTarget(self, action: #selector(showActionSheet))
            _view.snapsCollectionView.addGestureRecognizer(showActionSheetGesture)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addObservers()
        loadGoogleAds()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // AppUtility.lockOrientation(.portrait)
        // Or to rotate and lock
        if UIDevice.current.userInterfaceIdiom == .phone {
            IGAppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        }
        if !executeOnce {
            DispatchQueue.main.async {
                self._view.snapsCollectionView.delegate = self
                self._view.snapsCollectionView.dataSource = self
                let indexPath = IndexPath(item: self.handPickedStoryIndex, section: 0)
                self._view.snapsCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                self.handPickedStoryIndex = 0
                self.executeOnce = true
            }
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let currentCell = currentCell, currentCell.hasStoryBeenStopped {
            currentCell.restartSnap()
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if UIDevice.current.userInterfaceIdiom == .phone {
            // Don't forget to reset when view is being removed
            IGAppUtility.lockOrientation(.portrait)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        isTransitioning = true
        _view.snapsCollectionView.collectionViewLayout.invalidateLayout()
    }
    init(layout:IGLayoutType = .cubic,stories: [OrbisStory],handPickedStoryIndex: Int, handPickedSnapIndex: Int = 0) {
        self.layoutType = layout
        self.stories = stories
        self.handPickedStoryIndex = handPickedStoryIndex
        self.handPickedSnapIndex = handPickedSnapIndex
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func loadGoogleAds() {
        let request = Request()
        InterstitialAd.load(with: APPKeys.Admob.interstitialAdUnitKey,
                               request: request,
                               completionHandler: { [self] ad, error in
                                if let error = error {
                                    print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                                    return
                                }
                                interstitialAd = ad
                               })
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(commentCountUpdated(_:)), name: NSNotification.Name(AppNotificationKeys.Comment.commentCountUpdated), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(postUpdated(_:)), name: NSNotification.Name(AppNotificationKeys.Post.postUpdated), object: nil)
    }
    
    @objc private func postUpdated(_ notification: NSNotification) {
        guard let post = notification.object as? OrbisFeedPost else { return }
        guard let storyObj = self.stories.first(where: {$0.posts.contains(where: {$0.postKey == post.postKey})}), let storyIndex = self.stories.firstIndex(where: {$0.storyKey == storyObj.storyKey}) else { return }
        if let postIndex = storyObj.posts.firstIndex(where: {$0.postKey == post.postKey}) {
            storyObj.posts[postIndex] = post
            self.stories[storyIndex] = storyObj
        }
    }
    
    @objc private func commentCountUpdated(_ notification: NSNotification) {
        guard let countTuple = notification.object as? (String, Int) else { return }
        let key = countTuple.0
        let count = countTuple.1
        guard let storyObj = self.stories.first(where: {$0.posts.contains(where: {$0.postKey == key})}), let storyIndex = self.stories.firstIndex(where: {$0.storyKey == storyObj.storyKey}) else { return }
        guard var post = storyObj.posts.first(where: {$0.postKey == key }), let postIndex = storyObj.posts.firstIndex(where: {$0.postKey == key}) else { return }
        post.commentsCount = count
        storyObj.posts[postIndex] = post
        self.stories[storyIndex] = storyObj
    }
    
    @objc private func showActionSheet() {
        self.present(actionSheetController, animated: true) { [weak self] in
            self?.currentCell?.pauseEntireSnap()
        }
    }
    private func deleteSnap() {
        guard let indexPath = currentIndexPath else {
            debugPrint("Current IndexPath is nil")
            return
        }
        let cell = _view.snapsCollectionView.cellForItem(at: indexPath) as? OrbisStoryPreviewCell
        cell?.deleteSnap()
    }
    //MARK: - Selectors
    @objc func didSwipeDown(_ sender: Any) {
        storyActionDelegate?.didDismissStoryPreview()
        dismiss(animated: true, completion: nil)
    }
}

//MARK:- Extension|UICollectionViewDataSource
extension OrbisStoryPreviewController:UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let model = viewModel else {return 0}
        return model.numberOfItemsInSection(section)
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrbisStoryPreviewCell.reuseIdentifier, for: indexPath) as? OrbisStoryPreviewCell else {
            fatalError()
        }
        let story = viewModel?.cellForItemAtIndexPath(indexPath)
        cell.story = story
        cell.delegate = self
        currentIndexPath = indexPath
        nStoryIndex = indexPath.item
        return cell
    }
}

//MARK:- Extension|UICollectionViewDelegate
extension OrbisStoryPreviewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? OrbisStoryPreviewCell else {
            return
        }
        
        //Taking Previous(Visible) cell to store previous story
        let visibleCells = collectionView.visibleCells.sortedArrayByPosition()
        let visibleCell = visibleCells.first as? OrbisStoryPreviewCell
        if let vCell = visibleCell {
            vCell.story?.isCompletelyVisible = false
            vCell.pauseSnapProgressors(with: (vCell.story?.lastPlayedSnapIndex)!)
            story_copy = vCell.story
        }
        //Prepare the setup for first time story launch
        if story_copy == nil {
            cell.willDisplayCellForZerothIndex(with: cell.story?.lastPlayedSnapIndex ?? 0, handpickedSnapIndex: handPickedSnapIndex)
            return
        }
        if indexPath.item == nStoryIndex {
            let s = stories[nStoryIndex+handPickedStoryIndex]
            cell.willDisplayCell(with: s.lastPlayedSnapIndex)
        }
        /// Setting to 0, otherwise for next story snaps, it will consider the same previous story's handPickedSnapIndex. It will create issue in starting the snap progressors.
        let unseenStoryIndex = self.stories[indexPath.row].posts.firstIndex(where: {$0.seen == false}) ?? 0
        handPickedSnapIndex = unseenStoryIndex
    }
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let visibleCells = collectionView.visibleCells.sortedArrayByPosition()
        let visibleCell = visibleCells.first as? OrbisStoryPreviewCell
        guard let vCell = visibleCell else {return}
        guard let vCellIndexPath = _view.snapsCollectionView.indexPath(for: vCell) else {
            return
        }
        vCell.story?.isCompletelyVisible = true
        
        if vCell.story == story_copy {
            nStoryIndex = vCellIndexPath.item
            if vCell.longPressGestureState == nil {
                vCell.resumePreviousSnapProgress(with: (vCell.story?.lastPlayedSnapIndex)!)
            }
            if (vCell.story?.posts[vCell.story?.lastPlayedSnapIndex ?? 0])?.postType == .videoPost {
                vCell.resumePlayer(with: vCell.story?.lastPlayedSnapIndex ?? 0)
            }
            vCell.longPressGestureState = nil
        }else {
            if let cell = cell as? OrbisStoryPreviewCell {
                cell.stopPlayer()
            }
            vCell.startProgressors()
        }
        if vCellIndexPath.item == nStoryIndex {
            vCell.didEndDisplayingCell()
        }
    }
}

//MARK:- Extension|UICollectionViewDelegateFlowLayout
extension OrbisStoryPreviewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        /* During device rotation, invalidateLayout gets call to make cell width and height proper.
         * InvalidateLayout methods call this UICollectionViewDelegateFlowLayout method, and the scrollView content offset moves to (0, 0). Which is not the expected result.
         * To keep the contentOffset to that same position adding the below code which will execute after 0.1 second because need time for collectionView adjusts its width and height.
         * Adjusting preview snap progressors width to Holder view width because when animation finished in portrait orientation, when we switch to landscape orientation, we have to update the progress view width for preview snap progressors also.
         * Also, adjusting progress view width to updated frame width when the progress view animation is executing.
         */
        if isTransitioning {
            let visibleCells = collectionView.visibleCells.sortedArrayByPosition()
            let visibleCell = visibleCells.first as? OrbisStoryPreviewCell
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) { [weak self] in
                guard let strongSelf = self,
                    let vCell = visibleCell,
                    let progressIndicatorView = vCell.getProgressIndicatorView(with: vCell.snapIndex),
                    let pv = vCell.getProgressView(with: vCell.snapIndex) else {
                        fatalError("Visible cell or progressIndicatorView or progressView is nil")
                }
                vCell.scrollview.setContentOffset(CGPoint(x: CGFloat(vCell.snapIndex) * collectionView.frame.width, y: 0), animated: false)
                vCell.adjustPreviousSnapProgressorsWidth(with: vCell.snapIndex)
                
                if pv.state == .running {
                    pv.igWidthConstraint?.constant = progressIndicatorView.frame.width
                }
                strongSelf.isTransitioning = false
            }
        }
        if #available(iOS 11.0, *) {
            return CGSize(width: _view.snapsCollectionView.safeAreaLayoutGuide.layoutFrame.width, height: _view.snapsCollectionView.safeAreaLayoutGuide.layoutFrame.height)
        } else {
            return CGSize(width: _view.snapsCollectionView.frame.width, height: _view.snapsCollectionView.frame.height)
        }
    }
}

//MARK:- Extension|UIScrollViewDelegate<CollectionView>
extension OrbisStoryPreviewController {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let vCell = _view.snapsCollectionView.visibleCells.first as? OrbisStoryPreviewCell else {return}
        vCell.pauseSnapProgressors(with: (vCell.story?.lastPlayedSnapIndex)!)
        vCell.pausePlayer(with: (vCell.story?.lastPlayedSnapIndex)!)
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let sortedVCells = _view.snapsCollectionView.visibleCells.sortedArrayByPosition()
        guard let f_Cell = sortedVCells.first as? OrbisStoryPreviewCell else {return}
        guard let l_Cell = sortedVCells.last as? OrbisStoryPreviewCell else {return}
        let f_IndexPath = _view.snapsCollectionView.indexPath(for: f_Cell)
        let l_IndexPath = _view.snapsCollectionView.indexPath(for: l_Cell)
        let numberOfItems = collectionView(_view.snapsCollectionView, numberOfItemsInSection: 0)-1
        if l_IndexPath?.item == 0 {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.2) {
                guard let vCell = self._view.snapsCollectionView.visibleCells.first as? OrbisStoryPreviewCell else {return}
                vCell.tryResumeSnap(with: (vCell.story?.lastPlayedSnapIndex)!)
//                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }else if f_IndexPath?.item == numberOfItems {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.2) {
                self.storyActionDelegate?.didDismissStoryPreview()
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

//MARK:- StoryPreview Protocol implementation
extension OrbisStoryPreviewController: StoryPreviewProtocol {
    func didFinishPlayingStory() -> Bool {
        guard AppFirebaseConfigManager.shared.isAdsEnabled else { return false}
        storyViewedCount += 1
        if storyViewedCount >= AppFirebaseConfigManager.shared.storyAdsFrequency {
            storyViewedCount = 0
            if interstitialAd != nil {
                let admobInterstitialVC = UIStoryboard.getViewController(inStoryboard: "Common", identifier: "admobInterstitialVC") as! AdmobInterstitialViewController
                admobInterstitialVC.modalPresentationStyle = .overCurrentContext
                admobInterstitialVC.ad = interstitialAd!
                admobInterstitialVC.viewDelegate = self
                self.present(admobInterstitialVC, animated: false, completion: nil)
            }
            return true
        }
        return false
    }
    
    func didCompletePreview() {
        let n = handPickedStoryIndex+nStoryIndex+1
        if n < stories.count {
            //Move to next story
            story_copy = stories[nStoryIndex+handPickedStoryIndex]
            nStoryIndex = nStoryIndex + 1
            let nIndexPath = IndexPath.init(row: nStoryIndex, section: 0)
            //_view.snapsCollectionView.layer.speed = 0;
            _view.snapsCollectionView.scrollToItem(at: nIndexPath, at: .right, animated: true)
            /**@Note:
             Here we are navigating to next snap explictly, So we need to handle the isCompletelyVisible. With help of this Bool variable we are requesting snap. Otherwise cell wont get Image as well as the Progress move :P
             */
        }else {
            storyActionDelegate?.didDismissStoryPreview()
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    func moveToPreviousStory() {
        //let n = handPickedStoryIndex+nStoryIndex+1
        let n = nStoryIndex+1
        if n <= stories.count && n > 1 {
            story_copy = stories[nStoryIndex+handPickedStoryIndex]
            nStoryIndex = nStoryIndex - 1
            let nIndexPath = IndexPath.init(row: nStoryIndex, section: 0)
            _view.snapsCollectionView.scrollToItem(at: nIndexPath, at: .left, animated: true)
        } else {
            storyActionDelegate?.didDismissStoryPreview()
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    func didTapCloseButton() {
        storyActionDelegate?.didDismissStoryPreview()
        self.navigationController?.dismiss(animated: true, completion:nil)
    }
    func didSeenStory(postKey: String) {
        guard let storyObj = self.stories.first(where: {$0.posts.contains(where: {$0.postKey == postKey})}), let storyIndex = self.stories.firstIndex(where: {$0.storyKey == storyObj.storyKey}) else { return }
        guard var post = storyObj.posts.first(where: {$0.postKey == postKey }), let postIndex = storyObj.posts.firstIndex(where: {$0.postKey == postKey}) else { return }
        post.seen = true
        storyObj.posts[postIndex] = post
        self.stories[storyIndex] = storyObj
        storyActionDelegate?.didSeenStory(key: postKey)
    }
    
    func pushViewController(viewController: UIViewController) {
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func panPresentViewController(viewController: UIViewController) {
        presentPanModal(viewController)
    }
}

extension OrbisStoryPreviewController: AdmobInterstitalViewDelegate {
    /// Tells the delegate that the ad failed to present full screen content.
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content.")
        if let currentCell = currentCell, currentCell.hasStoryBeenStopped {
            currentCell.restartSnap()
        }
    }
    
    /// Tells the delegate that the ad presented full screen content.
    func adDidPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Ad did present full screen content.")
        if let currentCell = currentCell, currentCell.hasStoryBeenStopped {
            currentCell.stopEntireSnap()
        }
    }
    
    /// Tells the delegate that the ad dismissed full screen content.
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Ad did dismiss full screen content.")
        interstitialAd = nil
        loadGoogleAds()
        if let currentCell = currentCell, currentCell.hasStoryBeenStopped {
            currentCell.restartSnap()
        }
    }
}
