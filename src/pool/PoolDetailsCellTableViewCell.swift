//
//  PoolDetailsCellTableViewCell.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/27.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

protocol PoolDetailCellDelegate {
    func clickJoinPool(_ idx: Int)
}

class PoolDetailsCellTableViewCell: UITableViewCell {
        let BackGroudColor:[UIColor] = [UIColor.init(red: CGFloat(109)/255, green: CGFloat(151)/255, blue: CGFloat(206)/255, alpha: 1),
                                        UIColor.init(red: CGFloat(247)/255, green: CGFloat(170)/255, blue: CGFloat(110)/255, alpha: 1),
                                        UIColor.init(red: CGFloat(76)/255, green: CGFloat(194)/255, blue: CGFloat(208)/255, alpha: 1)]
        
        @IBOutlet weak var backGroundView: UIView!
        @IBOutlet weak var buyButton: UIButton!
//        @IBOutlet weak var GTN: UILabel!
        @IBOutlet weak var shortName: UILabel!
    
        @IBOutlet weak var lastDayUsed: UILabel!
        @IBOutlet weak var lastMonthUsed: UILabel!
        @IBOutlet weak var totalUsed: UILabel!
        @IBOutlet weak var totalRecharge: UILabel!
    
        var delegate: PoolDetailCellDelegate?
        var cellIndex: Int?
//        @IBOutlet weak var address: UILabel!
        
        override func awakeFromNib() {
                super.awakeFromNib()
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
        }
        
        override func layoutSubviews() {
                super.layoutSubviews()
                self.backGroundView.layer.cornerRadius = 10
        }
        
        public func initWith(details d:Pool, index:Int){
                self.shortName.text = d.Name
//                self.email.text = d.Email
//                self.url.text = d.Url ?? "NAN".locStr
                
            self.lastDayUsed.text = String(d.lastDayUsed ?? 0.0)
            self.lastMonthUsed.text = String(d.lastMonUsed ?? 0.0)
            self.totalUsed.text = String(d.totalUsed ?? 0.0)
            self.totalRecharge.text = String(d.totalRechage ?? 0)
            
            
                let color = BackGroudColor[index%3]
                self.buyButton.setTitleColor(color, for: .normal)
                self.backGroundView.backgroundColor = color
                self.buyButton.tag = index
            self.cellIndex = index
        }
    
        @IBAction func BuyThisPool(_ sender: UIButton) {
            if let index = cellIndex {
                self.delegate?.clickJoinPool(index)
            }
            
        }
    
}
