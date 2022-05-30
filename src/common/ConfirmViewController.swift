//
//  ConfirmViewController.swift
//  Pirate
//
//  Created by wesley on 2020/9/18.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit



class ConfirmViewController: UIViewController {
        
        @IBOutlet weak var CTitle: UILabel!
        @IBOutlet weak var Msg: UILabel!
        
        
        var CancelAction:(()->Void)?
        var OKAction:(()->Void)!
        var titleTxt:String?
        var msgTxt:String?
        
        override func viewDidLoad() {
                super.viewDidLoad()
                if let txt = titleTxt {
                        self.CTitle.text = txt
                }
                
                if let msg = msgTxt{
                        self.Msg.text = msg
                }
        }
        
        @IBAction func Close(_ sender: UIButton) {
                dismiss(animated: true) {
                        self.CancelAction?()
                }
        }
        
        @IBAction func OK(_ sender: UIButton) {
                dismiss(animated: true) {
                        self.OKAction()
                }
        }
}
