//
//  MembershipTableViewCell.swift
//  Pirate
//
//  Created by hyperorchid on 2020/10/1.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

protocol MembershipCellDelegate {
    func rechargeBtnClick(_ idx: Int)
}

class MembershipTableViewCell: UITableViewCell {
    
        var cellIndex: Int?
        var delegate: MembershipCellDelegate?
    
        let BackGroudColor:[UIColor] = [UIColor.init(red: CGFloat(109)/255, green: CGFloat(151)/255, blue: CGFloat(206)/255, alpha: 1),
                                        UIColor.init(red: CGFloat(247)/255, green: CGFloat(170)/255, blue: CGFloat(110)/255, alpha: 1),
                                        UIColor.init(red: CGFloat(76)/255, green: CGFloat(194)/255, blue: CGFloat(208)/255, alpha: 1)]
        
        
        
        @IBOutlet weak var BGView: UIView!
        @IBOutlet weak var poolNameLabel: UILabel!
        @IBOutlet weak var poolAddressLabel: UILabel!
        @IBOutlet weak var balanceLabel: UILabel!
        @IBOutlet weak var moreBtn: UIButton!
        
        override func awakeFromNib() {
                super.awakeFromNib()
        }
        override func layoutSubviews() {
                super.layoutSubviews()
                self.BGView.layer.cornerRadius = 10
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
        }

        func populate(membership obj:CDMemberShip, idx:Int) {
                guard let poolAddr = obj.poolAddr else {
                        return
                }
                let pool = Pool.CachedPool[poolAddr.lowercased()]
                
                let color = BackGroudColor[idx%3]
                self.BGView.backgroundColor = color
                self.moreBtn.setTitleColor(color, for: .normal)
//                self.moreBtn.tag = idx
            
                self.cellIndex = idx
                
                poolNameLabel.text = pool?.Name
                poolAddressLabel.text = pool?.Address
            if obj.available {
                balanceLabel.text = "\(obj.packetBalance.ToPackets())"
            } else {
                balanceLabel.text = "--"
            }
            
        }
    
        @IBAction func RechargeAction(_ sender: UIButton) {
            
            if let index = cellIndex {
                self.delegate?.rechargeBtnClick(index)
            }
            
        }
    
}
