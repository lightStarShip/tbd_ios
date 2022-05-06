//
//  RechargeViewController.swift
//  Pirate
//
//  Created by wesley on 2020/9/28.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class RechargeViewController: UIViewController {
        
        var poolAddr:String = ""
        
        @IBOutlet weak var TokenNoTFD: UITextField!
        @IBOutlet weak var AddressTFD: UITextField!
        @IBOutlet weak var pasteBtn: UIButton!
        @IBOutlet weak var PriceLabel: UILabel!
        
        
        override func viewDidLoad() {
                super.viewDidLoad()
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
                self.view.addGestureRecognizer(tapGesture)
                
                PriceLabel.text = AppSetting.servicePrice.ToPackets()
                AddressTFD.text = Wallet.WInst.Address
        }
        @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
                TokenNoTFD.resignFirstResponder()
                AddressTFD.resignFirstResponder()
        }
    
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                let content = UIPasteboard.general.string
                
                if let str = content, Wallet.IsValidAdress(addrStr: str){
                        pasteBtn.isHidden = false
                }else{
                        pasteBtn.isHidden = true
                }
        }
        
        
        @IBAction func PasteCopiedAddress(_ sender: UIButton) {
                guard let content = UIPasteboard.general.string,Wallet.IsValidAdress(addrStr:content) else{
                        pasteBtn.isHidden = true
                        return
                }
                AddressTFD.text = content
        }
        
        private func buyAction(token:Double, user:String, pool:String){
                self.showIndicator(withTitle: "", and: "Applying......".locStr)
                AppSetting.workQueue.async {
                        [weak self] in
                        
                        defer{self?.hideIndicator()}
                        
                        if false == Transaction.BuyPacket(userAddr: user, poolAddr: pool, token: token){
                                self?.ShowTips(msg: "Apply Failed".locStr)
                                return
                        }
                        
                        DispatchQueue.main.async {
                                self?.dismiss(animated: false){
                                        SwitchTab(Idx: 2){tab in
                                                guard let uinav = tab.selectedViewController  as? UINavigationController,
                                                      let vc = uinav.topViewController as? AccountViewController else{
                                                        return
                                                }
                                                
                                                vc.performSegue(withIdentifier: "ShowTransactionDetailsSegID", sender: self)
                                        }
                                }
                                self?.navigationController?.popViewController(animated: false)
                        }
                }
        }
        
        @IBAction func BuyPackets(_ sender: UIButton) {
                
                guard let user = AddressTFD.text, Wallet.IsValidAdress(addrStr: user) else {
                        self.ShowTips(msg:"Account Address Invalid")
                        AddressTFD.becomeFirstResponder()
                        return
                }
                guard AppSetting.servicePrice > 0 else {
                        self.ShowTips(msg: "Service Price Invalid")
                        return
                }
                
                var tokenNo = Double(0.0)
                if sender.tag == -1{
                        guard let tn = Double(TokenNoTFD.text ?? "0") else{
                                self.ShowTips(msg: "Token No Is Empty")
                                TokenNoTFD.becomeFirstResponder()
                                return
                        }
                        tokenNo = tn
                }else{
                        tokenNo = Double(sender.tag) * 1e9 / Double(AppSetting.servicePrice)
                }
                
                guard tokenNo >= 1 else {
                        self.ShowTips(msg: "Token No Too Small".locStr)
                        return
                }
                
                let tokenSum = tokenNo * HopConstants.DefaultTokenDecimal2
                
                guard Wallet.WInst.approve > tokenSum else{
                        SwitchTab(Idx: 2){tab in
                                tab.alertMessageToast(title: "Please Approve Token Usage".locStr)
                        }
                        return
                }
                
                if Wallet.WInst.tokenBalance < tokenSum{
                        self.ShowTips(msg: "Token Insufficient")
                        return
                }
                
                guard Wallet.WInst.IsOpen() else {
                        self.ShowOnePassword(){
                                self.buyAction(token: tokenNo, user: user, pool: self.poolAddr)
                        }
                        return
                }
                
                self.buyAction(token: tokenNo, user: user, pool: self.poolAddr)
        }
        
        /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
