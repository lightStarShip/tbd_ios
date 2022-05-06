//
//  TransactionTableViewCell.swift
//  Pirate
//
//  Created by hyperorchid on 2020/9/22.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class TransactionTableViewCell: UITableViewCell {

        @IBOutlet weak var hashLabel: UILabel!
        @IBOutlet weak var typeLabel: UILabel!
        @IBOutlet weak var statusLabel: UILabel!
        @IBOutlet weak var valueLabel: UILabel!
        
        
        override func awakeFromNib() {
                super.awakeFromNib()
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
        }
        
        public func fieldUP(_ tx:Transaction){
                
                statusLabel.text = tx.txStatus.name
                statusLabel.layer.borderColor = tx.txStatus.StatusBorderColor
                statusLabel.backgroundColor = tx.txStatus.StatusBGColor
                statusLabel.textColor = tx.txStatus.StatusTxtColor
                
                typeLabel.text = tx.txType.name
                valueLabel.text = "\(tx.txValue)"
                hashLabel.text = tx.txHash
        }
}
