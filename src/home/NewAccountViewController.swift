//
//  NewAccountViewController.swift
//  Pirate
//
//  Created by wesley on 2020/9/18.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class NewAccountViewController: UIViewController {
        
        @IBOutlet weak var Password1: UITextField!
        @IBOutlet weak var Password2: UITextField!
        @IBOutlet weak var importBtn: UIButton!
        @IBOutlet weak var createBtn: UIButton!
        @IBOutlet weak var right_coin1: UIImageView!
        @IBOutlet weak var right_coin2: UIImageView!
        
        var imagePicker: UIImagePickerController!
        var showImport:Bool = true
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
        
        override func viewDidLoad() {
                super.viewDidLoad()
                let frame = createBtn.frame
                let newFrame = CGRect(origin: CGPoint(x:0,y:0),
                                      size: CGSize(width: self.view.frame.width - 2 * frame.minX,
                                                   height: frame.height))
                createBtn.layer.insertSublayer(gradientLayer(frame: newFrame), at: 0)
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(self.textChanged(notification:)),
                    name: UITextField.textDidChangeNotification,
                    object: nil)
                
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
                self.view.addGestureRecognizer(tapGesture)
                if !showImport{
                        importBtn.isHidden = true
                }
        }
        
        @objc func textChanged (notification: NSNotification) {
                guard let txtFid = notification.object as? UITextField else{
                        return
                }
                if txtFid.tag == 1{
                        right_coin1.isHidden = txtFid.text?.count ?? 0 <= 2
                }else if txtFid.tag == 2{
                        right_coin2.isHidden = txtFid.text != Password1.text
                }
        }
        
        @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
                Password1.resignFirstResponder()
                Password2.resignFirstResponder()
        }
        
        @IBAction func CreateAccount(_ sender: UIButton) {
                guard Password1.text == Password2.text else {
                        self.ShowTips(msg: "2 passwords are not equal".locStr)
                        return
                }
                
                guard let password = Password1.text,  password != ""else {
                        self.ShowTips(msg: "Invalid password".locStr)
                        return
                }
                
                self.showIndicator(withTitle: "", and: "Creating Account".locStr)
                AppSetting.workQueue.async {
                        
                        defer{self.hideIndicator()}
                        
                        if false == Wallet.NewInst(auth: password){
                                return
                        }
                        _ = AppSetting.save(password: password,
                                            service: HopConstants.SERVICE_NME_FOR_OSS,
                                            account: Wallet.WInst.SubAddress!)
                        DispatchQueue.main.async {
                                self.dismiss(animated: true)
                        }
                }
        }
        private func importFromLib(){
                self.imagePicker =  UIImagePickerController()
                self.imagePicker.delegate = self
                self.imagePicker.sourceType = .photoLibrary
                self.present(self.imagePicker, animated: true, completion: nil)
        }
        
        @IBAction func ImportAccount(_ sender: UIButton) {
                
                let alert = UIAlertController(title: "", message:"Please Select an Option".locStr, preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: "Import QR image".locStr, style: .default , handler:{ (UIAlertAction)in
                        self.importFromLib()
                }))
                
                alert.addAction(UIAlertAction(title: "Scan QR Code".locStr, style: .default , handler:{ (UIAlertAction)in
                        self.performSegue(withIdentifier: "ShowQRScanerID", sender: self)
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel".locStr, style: .cancel, handler:{ (UIAlertAction)in
                        NSLog("=======>User click Dismiss button")
                }))
                
                alert.popoverPresentationController?.sourceView = self.view;
                alert.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: 1, height: 1) //(0,0,1.0,1.0);
                self.present(alert, animated: true)
        }
        // Mark View Action
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                if segue.identifier == "ShowQRScanerID"{
                        let vc : ScannerViewController = segue.destination as! ScannerViewController
                        vc.delegate = self
                }
        }
}

extension NewAccountViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate, ScannerViewControllerDelegate{
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
                
                imagePicker.dismiss(animated: true, completion: nil)
                guard let qrcodeImg = info[.originalImage] as? UIImage else {
                        self.ShowTips(msg: "Image not found!".locStr)
                        return
                }
                
                let detector:CIDetector=CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
                let ciImage:CIImage=CIImage(image:qrcodeImg)!
                
                let features=detector.features(in: ciImage)
                var codeStr = ""
                for feature in features as! [CIQRCodeFeature] {
                        codeStr += feature.messageString!
                }
                
                if codeStr == "" {
                        self.ShowTips(msg: "Parse image failed".locStr)
                        return
                }else{
                        NSLog("=======>image QR string message: \(codeStr)")
                        self.codeDetected(code: codeStr)
                }
                
        }
        
        func codeDetected(code: String){
                self.showIndicator(withTitle: "", and: "Importing......".locStr)
                NSLog("=======>Scan result:=>[\(code)]")
                
                self.ShowOneInput(title: "Import Account".locStr,
                                  placeHolder: "Password For Import".locStr,
                                  securityShow: true,
                                  nextAction: { (password, isOK) in
                        defer{self.hideIndicator()}
                        guard let pwd = password, isOK else{
                                return
                        }
                        
                        guard Wallet.ImportWallet(auth: pwd, josn:code) else{
                                self.ShowTips(msg: "Import Failed".locStr)
                                return
                        }
                        
                        _ = AppSetting.save(password: pwd,
                                            service: HopConstants.SERVICE_NME_FOR_OSS,
                                            account: Wallet.WInst.SubAddress!)
                        self.dismiss(animated: true)
                })
        }
}
