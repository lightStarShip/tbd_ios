//
//  Utils+ViewController.swift
//  Pirate
//
//  Created by wesley on 2020/9/18.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit
import MBProgressHUD

func generateQRCode(from message: String) -> UIImage? {
        
        guard let data = message.data(using: .utf8) else{
                return nil
        }
        
        guard let qr = CIFilter(name: "CIQRCodeGenerator",
                                parameters: ["inputMessage":
                                        data, "inputCorrectionLevel":"M"]) else{
                return nil
        }
        
        guard let qrImage = qr.outputImage?.transformed(by: CGAffineTransform(scaleX: 5, y: 5)) else{
                return nil
        }
        let context = CIContext()
        let cgImage = context.createCGImage(qrImage, from: qrImage.extent)
        let uiImage = UIImage(cgImage: cgImage!)
        return uiImage
}

public func instantiateViewController(storyboardName: String, viewControllerIdentifier: String) -> UIViewController {
    let storyboard = UIStoryboard(name: storyboardName, bundle: Bundle.main);
    return storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier);
}


func SwitchTab(Idx:Int, action:((_ tab:UITabBarController)->Void)? = nil) {
        DispatchQueue.main.async {
                guard let tabbarController = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController else { return }
                tabbarController.selectedIndex = Idx
                guard let act = action else{
                        return
                }
                act(tabbarController)
        }
}

public struct AlertPayload {
        var title:String!
        var placeholderTxt:String?
        var securityShow:Bool = true
        var keyType:UIKeyboardType = .default
        var action:((String?, Bool)->Void)!
}

extension UIViewController {
        
        func alertMessageToast(title:String) ->Void {DispatchQueue.main.async {
            let hud : MBProgressHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
            hud.mode = MBProgressHUDMode.text
            hud.detailsLabel.text = title
            hud.removeFromSuperViewOnHide = true
            hud.margin = 10
            hud.offset.y = 250.0
            hud.hide(animated: true, afterDelay: 3)
        }}
        
        func showIndicator(withTitle title: String, and Description:String) {DispatchQueue.main.async {
                let Indicator = MBProgressHUD.showAdded(to: self.view, animated: true)
                Indicator.label.text = title
                Indicator.isUserInteractionEnabled = false
                Indicator.detailsLabel.text = Description
                Indicator.show(animated: true)
        }}
        
        func createIndicator(withTitle title: String, and Description:String) -> MBProgressHUD{
                let Indicator = MBProgressHUD.showAdded(to: self.view, animated: true)
                Indicator.label.text = title
                Indicator.isUserInteractionEnabled = false
                Indicator.detailsLabel.text = Description
                return Indicator
        }
        
        func toastMessage(title:String) ->Void {DispatchQueue.main.async {
            let hud : MBProgressHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
            hud.mode = MBProgressHUDMode.text
            hud.detailsLabel.text = title
            hud.removeFromSuperViewOnHide = true
            hud.margin = 10
            hud.offset.y = 250.0
            hud.hide(animated: true, afterDelay: 3)
        }}
        
        
        func ConfirmAlert(title:String? = nil, msg:String? = nil, YesAction:@escaping (()->Void), NoAction:(()->Void)? = nil){ DispatchQueue.main.async {
                
                guard let alertVC = instantiateViewController(storyboardName: "Main",
                                      viewControllerIdentifier:"ConfirmViewControllerID") as? ConfirmViewController else{
                        return
                }
                
                alertVC.titleTxt = title
                alertVC.msgTxt = msg
                alertVC.OKAction = YesAction
                alertVC.CancelAction = NoAction
                
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert);
                alertController.setValue(alertVC, forKey: "contentViewController");
                self.present(alertController, animated: true, completion: nil);
                }
        }
        
        func CustomerAlert(name:String){ DispatchQueue.main.async {
                
                let alertVC = instantiateViewController(storyboardName: "Main", viewControllerIdentifier:name)
                
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert);
                alertController.setValue(alertVC, forKey: "contentViewController");
                self.present(alertController, animated: true, completion: nil);
                }
        }
        
        func hideIndicator() {DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
        }}
        
        func ShowTips(msg:String){
                DispatchQueue.main.async {
                        let ac = UIAlertController(title: "Tips!".locStr, message: msg, preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                }
        }
        
        func ShowOneInput(title: String, placeHolder:String?, securityShow:Bool = false, type:UIKeyboardType = .default, nextAction:((String?, Bool)->Void)?) {
                
                let ap = AlertPayload(title: title,
                                      placeholderTxt: placeHolder,
                                      securityShow:securityShow,
                                      keyType: type,
                                      action: nextAction)
                
                LoadAlertFromStryBoard(payload: ap)
        }
        
        func ShowOnePassword(nextAction:(()->Void)? = nil) {
                
                self.showIndicator(withTitle:"",  and: "Opening......".locStr)
                
                let ap = AlertPayload(title: "Unlock Account".locStr, placeholderTxt: "Password".locStr){
                        (password, isOK) in
                        
                        defer{
                                self.hideIndicator()
                        }
                        guard let pwd = password, isOK else{
                                return
                        }
                        if Wallet.WInst.OpenWallet(auth: pwd) == false{
                                self.ShowTips(msg: "Auth Failed".locStr)
                                return
                        }
                        nextAction?()
                }
                
                LoadAlertFromStryBoard(payload: ap)
        }
        
        func LoadAlertFromStryBoard(payload:AlertPayload){ DispatchQueue.main.async {
                
                        guard let alertVC = instantiateViewController(storyboardName: "Main",
                                                                     viewControllerIdentifier: "PasswordViewControllerID")
                            as? PasswordViewController else{
                            return
                        }
                        
                        alertVC.payload = payload;
                        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert);
                        alertController.setValue(alertVC, forKey: "contentViewController");
                        self.present(alertController, animated: true, completion: nil);
                }
        }
        
        
        func ShowQRAlertView(image:UIImage?){
                guard let alertVC = instantiateViewController(storyboardName: "Main",
                                                             viewControllerIdentifier: "QRCodeShowViewControllerSID")
                    as? QRCodeShowViewController else{
                    return
                }
                alertVC.QRImage = image;
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert);
                alertController.setValue(alertVC, forKey: "contentViewController");
                self.present(alertController, animated: true, completion: nil);
        }
        
        func ShowQRAlertView(data:String){
                guard let image = generateQRCode(from: data) else { return }
                self.ShowQRAlertView(image: image)
        }
        
}
extension MBProgressHUD{
        
        func setDetailText(msg:String) {
                 DispatchQueue.main.async {
                        self.detailsLabel.text = msg
                }
        }
}
