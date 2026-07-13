import UIKit

enum ImageStyle: Int {
    case squared,rounded
}

typealias SetImageRequester = (IGResult<Bool,Error>) -> Void

extension UIImageView: IGImageRequestable {
    func setImage(url: String,
                  style: ImageStyle = .rounded,
                  firebaseLocation: ProjectStorageDirectories = .none,
                  completion: SetImageRequester? = nil) {
        image = nil

        //The following stmts are in SEQUENCE. before changing the order think twice :P
        isActivityEnabled = true
        layer.masksToBounds = false
        if style == .rounded {
            layer.cornerRadius = frame.height/2
            activityStyle = UIActivityIndicatorView.Style.medium
        } else if style == .squared {
            layer.cornerRadius = 0
            activityStyle = UIActivityIndicatorView.Style.medium
        }
        
        clipsToBounds = true
        if url.isNotUrlLink {
            let ref = url.getFirebaseReference(storage: firebaseLocation, imageSizeResolution: .sixEighty)
            self.showActivityIndicator()
            self.sd_setImage(with: ref, maxImageSize: UInt64(AppValues.thousandHundrenMbInBytes), placeholderImage: nil, options: [.retryFailed]) { _,err,_,_ in
                self.hideActivityIndicator()
                if let error = err{
                    completion?(IGResult.failure(error))
                }
                else {
                    completion?(IGResult.success(true))
                }
            }
        }
        else {
            self.showActivityIndicator()
            self.sd_setImage(with: URL(string: url), placeholderImage: nil, options: [.retryFailed]) { _,err,_,_ in
                self.hideActivityIndicator()
                if let error = err{
                    completion?(IGResult.failure(error))
                }
                else {
                    completion?(IGResult.success(true))
                }
            }
        }
    }
    
    func setImage(url: String?, firebaseLocation: ProjectStorageDirectories, resolution: OrbisImageSizeResolution = .twoHundred, image: UIImage? = nil) {
        if let img = image {
            self.image = img
        }
        else {
            let imageLink = url ?? ""
            if imageLink.isNotUrlLink {
                let ref = imageLink.getFirebaseReference(storage: firebaseLocation, imageSizeResolution: resolution)
                self.sd_setImage(with: ref, maxImageSize: UInt64(AppValues.thousandHundrenMbInBytes), placeholderImage: nil, options: [.retryFailed])
            }
            else {
                self.sd_setImage(with: URL(string: imageLink)!, placeholderImage: nil)
            }
        }
    }
}
