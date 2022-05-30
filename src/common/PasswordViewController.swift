//
//  PasswordViewController.swift
//  Pirate
//
//  Created by wesley on 2020/9/18.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class PasswordViewController: UIViewController {

        @IBOutlet weak var titleLab: UILabel!
        @IBOutlet weak var paswordInputTF: UITextField!
        public var payload:AlertPayload!
        override func viewDidLoad() {
                super.viewDidLoad()
                paswordInputTF.leftViewMode = UITextField.ViewMode.always
                paswordInputTF.leftView = UIView(frame:CGRect(x:0, y:0, width:18, height:10))
                paswordInputTF.isSecureTextEntry = self.payload.securityShow
                paswordInputTF.keyboardType = self.payload.keyType
                self.titleLab.text = payload.title
                self.paswordInputTF.placeholder = payload.placeholderTxt
                paswordInputTF.becomeFirstResponder()
        }
        
        @IBAction func OKCation(_ sender: Any) {
                parent?.dismiss(animated: false, completion: nil);
                let password = self.paswordInputTF.text
                self.payload.action(password, true)
        }
        
        @IBAction func CancelAction(_ sender: Any) {
                parent?.dismiss(animated: false, completion: nil);
                payload.action(nil, false)
        }
}
