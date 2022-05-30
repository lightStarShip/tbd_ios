//
//  AccountViewController.swift
//  Pirate
//
//  Created by wesley on 2020/9/18.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController {

        @IBOutlet weak var walletView: UIView!
        @IBOutlet weak var appVerLabel: UILabel!
        @IBOutlet weak var shareView: UIView!
        @IBOutlet weak var telegramView: UIView!
        @IBOutlet weak var walletAddrLabel: UILabel!
        @IBOutlet weak var streamModeSwitch: UISwitch!
        @IBOutlet weak var showManualView: UIView!
        
        var appVersion: String? {
            return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        }
        
        override func viewDidLoad() {
                super.viewDidLoad()
                
                walletAddrLabel.text = Wallet.WInst.Address
                appVerLabel.text = appVersion
                streamModeSwitch.isOn = AppSetting.isStreamModel
               
                
                let tap = UITapGestureRecognizer(target: self, action: #selector(openTelegram))
                tap.numberOfTapsRequired = 1
                telegramView.addGestureRecognizer(tap)
              
                
                let tap4 = UITapGestureRecognizer(target: self, action: #selector(shareApp))
                tap4.numberOfTapsRequired = 1
                shareView.addGestureRecognizer(tap4)
                
                let tap5 = UITapGestureRecognizer(target: self, action: #selector(copyAddress))
                tap5.numberOfTapsRequired = 1
                walletView.addGestureRecognizer(tap5)
                
                let tap6 = UITapGestureRecognizer(target: self, action: #selector(showUserManual))
                tap6.numberOfTapsRequired = 1
                showManualView.addGestureRecognizer(tap6)
                
                let frame = walletView.frame
                let newFrame = CGRect(origin: CGPoint(x:0,y:0),
                                      size: CGSize(width: self.view.frame.width - 2 * frame.minX,
                                                   height: frame.height))
                walletView.layer.insertSublayer(gradientLayer(frame: newFrame), at: 0)
        }
 
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        private func gradientLayer(frame:CGRect)-> CAGradientLayer{
                let rightColor = UIColor(red: 0xFF/255, green: 0xB4/255, blue: 0x72/255, alpha: 1)
                let leftColor = UIColor(red: 0xFF/255, green: 0x7D/255, blue: 0x3E/255, alpha: 1)
                let gradientColors = [leftColor.cgColor, rightColor.cgColor]
                let gradientLocations:[NSNumber] = [0.0, 1.0]
                
                let g = CAGradientLayer()
                g.colors = gradientColors
                g.locations = gradientLocations
                g.startPoint = CGPoint(x: 0, y: 0)
                g.endPoint = CGPoint(x: 1, y: 0)
                g.frame = frame
                g.cornerRadius = 4
                return g
        }
        
        
        // MARK: - Embedded Actions
       
        
        @objc func openTelegram() {
                let screenName = "simplemeta"
                let appURL = NSURL(string: "tg://resolve?domain=\(screenName)")!
                let webURL = NSURL(string: "https://t.me/\(screenName)")!
                if UIApplication.shared.canOpenURL(appURL as URL) {
                        UIApplication.shared.open(appURL as URL, options: [:])
                }
                else {
                        UIApplication.shared.open(webURL as URL, options: [:])
                }
        }
        

        @objc func shareApp() {
                let items = [URL(string: "https://apps.apple.com/app/id1624442074")!,
                             URL(string: "https://testflight.apple.com/join/KxaTKBJ8")!]
                let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
                present(ac, animated: true)
        }

        
        @objc func copyAddress() {
                UIPasteboard.general.string = Wallet.WInst.Address
                self.ShowTips(msg: "Copy Success".locStr)
        }
        
        @objc func showUserManual() {
                self.performSegue(withIdentifier: "ShowManualPages", sender: self)
        }

        // MARK: - Button Actions
        
        @IBAction func ChangeStreamMode(_ sender: UISwitch) {
                AppSetting.changeStreamMode(sender.isOn)
        }
     
        
        @IBAction func ShowAdressQR(_ sender: UIButton) {
                self.ShowQRAlertView(data: Wallet.WInst.Address!)
        }

        
        // MARK: - Navigation
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        }
}
