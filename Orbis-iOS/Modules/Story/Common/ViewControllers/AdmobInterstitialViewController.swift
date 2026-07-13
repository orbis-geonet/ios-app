//
//  AdmobInterstitialViewController.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 09/09/2021.
//

import UIKit
import GoogleMobileAds

protocol AdmobInterstitalViewDelegate: AnyObject {
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error)
    func adDidPresentFullScreenContent(_ ad: FullScreenPresentingAd)
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd)
}

class AdmobInterstitialViewController: UIViewController {
    
    @IBOutlet weak var countDownView: RoundedView!
    @IBOutlet weak var countDownLabel: UILabel!
    
    
    var ad: InterstitialAd!
    var isAdPresenting = false
    var hasTimerStarted = false
    weak var viewDelegate: AdmobInterstitalViewDelegate?
    var countDownTimer = Timer()
    private let adViewTime: Double = Double(AppFirebaseConfigManager.shared.interstitialAdTimeout)
    var countDownValue = AppFirebaseConfigManager.shared.interstitialAdTimeout
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ad.fullScreenContentDelegate = self
        countDownLabel.text = "\(countDownValue)"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !isAdPresenting else { return }
        ad.present(from: self)
        guard !hasTimerStarted else { return }
        hasTimerStarted = true
        self.countDownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] timer in
            guard let self = self else { return }
            if self.countDownValue > 0 {
                self.countDownValue -= 1
                self.countDownLabel.text = "\(self.countDownValue)"
            }
        })
        Timer.scheduledTimer(withTimeInterval: adViewTime, repeats: false) { [weak self] timer in
            guard let self = self else { return }
            self.countDownTimer.invalidate()
            self.adDidDismissFullScreenContent(self.ad)
            timer.invalidate()
        }
    }

}

extension AdmobInterstitialViewController: FullScreenContentDelegate {
    /// Tells the delegate that the ad failed to present full screen content.
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        self.dismiss(animated: true) { [weak self] in
            self?.viewDelegate?.ad(ad, didFailToPresentFullScreenContentWithError: error)
        }
    }
    
    /// Tells the delegate that the ad presented full screen content.
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        isAdPresenting = true
        viewDelegate?.adDidPresentFullScreenContent(ad)
    }
    
    /// Tells the delegate that the ad dismissed full screen content.
    //    private func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAdFullScreenPresentingAd) {
    //        self.dismiss(animated: false) { [weak self] in
    //            self?.viewDelegate?.adDidDismissFullScreenContent(ad)
    //        }
    //    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        self.dismiss(animated: false) { [weak self] in
            self?.viewDelegate?.adDidDismissFullScreenContent(ad)
        }
    }
    
}
