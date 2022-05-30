//
//  RoundedCornerView.swift
//  Pirate
//
//  Created by wesley on 2020/9/22.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedCornerView: UIView {
        
    // if cornerRadius variable is set/changed, change the corner radius of the UIView
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
        
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }
        
}

