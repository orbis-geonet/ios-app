
import UIKit


class MapUpdatingView: UIView {
    
    var progressCallBack: ((Float) -> Void)?

    private var timer: Timer?
    private var currentProgress: Float = 0.0


    
    // Initializer with parent view
    init(parentView: UIView, leftView:UIView, rightView:UIView) {
        super.init(frame: .zero)
        setupView()
        
        // Add this view to the parent view
        parentView.addSubview(self)
        
        // Set up constraints for this view relative to the parent view
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            self.centerYAnchor.constraint(equalTo: leftView.centerYAnchor),
            self.leadingAnchor.constraint(equalTo: leftView.trailingAnchor, constant: 15),
            self.trailingAnchor.constraint(equalTo: rightView.leadingAnchor, constant: -15),
        ])
        
        // Add a timer to simulate progress
       // startProgressSimulation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    func titleLabel(title : String)  {
        titleLabel.text = title
    }
    
    func subtitleLabel(subTitle : String)  {
        subtitleLabel.text = subTitle
    }

    
    func progressBar(progress: Float) {
       
        print("MapUpdatingView  normalizedProgress ===== \(progress)")
        self.progressBar.progress = progress
        progressCallBack?(self.progressBar.progress)

    }
    
    func setAlphaForSubTitleLabel(alpha: CGFloat){
        subtitleLabel.alpha = alpha
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Tribal map is updating".localized
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Just a few more seconds".localized
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressBar: UIProgressView = {
        
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = 0.0 // Example progress
        progressView.trackTintColor = .lightGray
        progressView.progressTintColor = .darkGray
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        // Increase the height using scaling
        progressView.transform = CGAffineTransform(scaleX: 1.0, y: 2.0) // Scale Y to increase height
        
        // Make corners rounded
        progressView.layer.cornerRadius = 4.0 // Adjust the radius as needed
        progressView.clipsToBounds = true
        progressView.layer.sublayers?.forEach { $0.cornerRadius = 4.0 } // Ensure sublayers also have rounded corners
        progressView.subviews.forEach { $0.clipsToBounds = true } // Apply to subviews if needed
        
        return progressView
    }()
    
    
    private func setupView() {
        // Your existing setup code for labels, progress bar, etc.
//        backgroundColor = .white
//        layer.cornerRadius = 10
//        layer.borderWidth = 1
//        layer.borderColor = UIColor.lightGray.cgColor
        
        
        // Add subviews
        addSubview(titleLabel)
        addSubview(progressBar)
        addSubview(subtitleLabel)
        
        // Add constraints
        NSLayoutConstraint.activate([
            // Title label constraints
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            
            // Progress bar constraints
            progressBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            progressBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            // Subtitle label constraints
            subtitleLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }
    
    private func startProgressSimulation() {
        currentProgress = 0.0
        // Create a timer to update progress every 0.1 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.currentProgress < 1.0 {
                self.currentProgress += 0.01 // Increment progress by 1%
                self.progressBar(progress: currentProgress)
            } else {
                self.timer?.invalidate() // Stop the timer when progress reaches 100%
                self.timer = nil
            }
        }
    }
}

