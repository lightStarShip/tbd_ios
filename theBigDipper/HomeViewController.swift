//
//  ViewController.swift
//  theBigDipper
//
//  Created by wesley on 2022/5/28.
//

import UIKit
import NetworkExtension

class HomeViewController: UIViewController {
        
        var targetManager: NEVPNManager = NEVPNManager.shared()
        override func viewDidLoad() {
                super.viewDidLoad()
        }
        
        @IBAction func startVPN(_ sender: UIButton) {
        }
}

