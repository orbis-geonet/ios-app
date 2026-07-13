
import UIKit
import SDWebImage


class CarouselViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // Closure for cell visibility
    var onCellVisibility_ChangeFocusedPlace: ((Int, PolygonPlaceDetails) -> Void)?
    
    var onMaxHeightCellBack: ((CGFloat) -> Void)?

    private var collectionView: UICollectionView!
    
    private var cardData: [PolygonPlaceDetails] = []
            
    private var lastVisibleIndex: IndexPath?
    
    private var maxHeightCell: CGFloat = 0
    
    var onCellSelected: ((PolygonPlaceDetails) -> Void)?
    
    


    // Custom initializer
    init(withCardData: [PolygonPlaceDetails]) {
        self.cardData = withCardData
        super.init(nibName: nil, bundle: nil) // Call to superclass initializer
    }
    
    func populateWithData(withCardData: [PolygonPlaceDetails]) {
        maxHeightCell = 0
        self.cardData = withCardData
        self.collectionView.reloadData()
        self.scrollToIndex(0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: { [weak self] in
            self?.onMaxHeightCellBack!(self!.maxHeightCell)
        })

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .clear
        setupCollectionView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    private func setupCollectionView() {
        
        let layout = CarouselFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false

        collectionView.decelerationRate = .fast
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CardCell.self, forCellWithReuseIdentifier: "CardCell")
        // Add left and right insets
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 8, bottom: 13, right: 8)

        //collectionView.backgroundColor = .orange
        view.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
        ])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemWidth: CGFloat
        let sideMargin: CGFloat = 16

        var titlePading : CGFloat = 24
        
        if cardData.count == 1 {
            itemWidth = collectionView.bounds.width - (sideMargin)
            titlePading = 80
        } else {
            itemWidth = collectionView.bounds.width * 0.80
        }

        let fontSize = 16 * (UIScreen.main.bounds.width/414)
        
        
        let titleHeight = heightForText(cardData[indexPath.item].name ?? "", font: UIFont.boldSystemFont(ofSize: fontSize), width: itemWidth - titlePading)
        
        
        let fixedRatingHeight = UIFont.systemFont(ofSize: 12).lineHeight

        //let fixedDescriptionHeight = UIFont.systemFont(ofSize: 12).lineHeight
        
        let fixedDescriptionHeight = heightForText(cardData[indexPath.item].description ?? "", font: UIFont.systemFont(ofSize: 12), width: itemWidth - titlePading)
        
        let extraSpace = 34 * (UIScreen.main.bounds.width/414)

        // Add up the heights and include padding
        var totalHeight = titleHeight + fixedRatingHeight + fixedDescriptionHeight + extraSpace // Add padding and other components
        
        //print("sizeForItemAt totalHeight === \(totalHeight)")
            
        if let imageName = cardData[indexPath.item].imageName, !imageName.isEmpty {
            if totalHeight < 120 {
                totalHeight = 120
                //print("sizeForItemAt change totalHeight === \(totalHeight)")
            }
        }
        
        if totalHeight > maxHeightCell {
            maxHeightCell = totalHeight
            //print("sizeForItemAt change maxHeightCell === \(maxHeightCell)")
            
            if totalHeight > 130 {
                maxHeightCell = 130
                totalHeight = 130
            }
        }
        
        return CGSize(width: itemWidth, height: totalHeight)
    }

    private func heightForText(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading], // Ensure precise height with font leading
            attributes: [.font: font],
            context: nil
        )
        return ceil(boundingBox.height) // Round up to ensure it fits
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cardData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
  
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCell", for: indexPath) as! CardCell
        cell.configure(with: cardData[indexPath.item], Index: indexPath.row)
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        setParentViewHeight()
                
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: { [weak self] in
            self?.setParentViewHeight()

        })
    }

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedData = cardData[indexPath.item]
        onCellSelected?(selectedData)
    }
    
    // Method to scroll to a specific index
    func scrollToIndex(_ index: Int) {
        guard index >= 0 && index < cardData.count else { return }
        let indexPath = IndexPath(item: index, section: 0)
        lastVisibleIndex = indexPath
        
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }
}

extension CarouselViewController {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        guard let _ = scrollView as? UICollectionView else { return }
        self.onSetVisibleCellSelection()
    }


    private func onSetVisibleCellSelection() {
        
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        if let indexPath = collectionView.indexPathForItem(at: visiblePoint) {
            // Check if it's the same as the last visible index
            if indexPath != lastVisibleIndex {
                lastVisibleIndex = indexPath
                //print("Current item index: \(indexPath.item)")
                // Perform actions for the new visible item here
                let selectedData = cardData[indexPath.item]
                onCellVisibility_ChangeFocusedPlace?(indexPath.row, selectedData)
            }
        }
    }
    
    
    private func setParentViewHeight() {
        self.onMaxHeightCellBack!((self.maxHeightCell + 15))
    }

}

