import UIKit

class FullSearchBar: UIView {

    let textField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Choose a city"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        self.layer.cornerRadius = 8
        self.backgroundColor = .white
        self.addSubview(textField)
        
        // Add constraints
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8),
            textField.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
            textField.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8)
        ])
    }
}
