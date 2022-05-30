//
//  MinerDetailsTableViewCell.swift
//  Pirate
//
//  Created by hyperorchid on 2020/3/3.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class MinerDetailsTableViewCell: UITableViewCell {

        @IBOutlet weak var checkIcon: UIImageView!
        @IBOutlet weak var IP: UILabel!
        @IBOutlet weak var Address: UILabel!
        @IBOutlet weak var Ping: UILabel!
        @IBOutlet weak var PingBtn: UIButton!
        
        override func awakeFromNib() {
                super.awakeFromNib()
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
        }

        func initWith(minerData:inout CDMiner, isChecked:Bool, index:Int) {
               
                self.IP.text = minerData.host ?? "0.0.0.0"
                self.Ping.text = String(format: "%.2f "+"ms".locStr, minerData.ping )
                self.Address.text = minerData.addr
                checkIcon.isHidden = !isChecked
                self.PingBtn.tag = index
        }
        func update(check:Bool){
                self.checkIcon.isHidden = !check
        }
}
