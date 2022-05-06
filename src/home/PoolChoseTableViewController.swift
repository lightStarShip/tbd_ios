//
//  PoolChoseTableViewController.swift
//  Pirate
//
//  Created by hyperorchid on 2020/3/2.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class PoolChoseItemTableViewCell: UITableViewCell {
        
        @IBOutlet weak var poolAddrLabel: UILabel!
        @IBOutlet weak var poolNameLabel: UILabel!
        @IBOutlet weak var checkImg: UIImageView!
        var checked: Bool = false
        
        
        public func initWith(member:CDMemberShip, isSelected:Bool){
                poolAddrLabel.text = member.poolAddr
                let pool = Pool.CachedPool[(member.poolAddr?.lowercased()) ?? "-1"]
                poolNameLabel.text = pool?.Name
                checkImg.isHidden = !isSelected
                checked = isSelected
        }
        
        func update(check:Bool){
                checkImg.isHidden = !check
        }
}

class PoolChoseTableViewController: UITableViewController {

        var validPoolArr:[CDMemberShip] = []
        var curPoolAddr:String?
        var curCell:PoolChoseItemTableViewCell?
        
        override func viewDidLoad() {
                super.viewDidLoad()
                
                self.tableView.rowHeight = 64
                validPoolArr =  MembershipUI.MemberArray()
                curPoolAddr = AppSetting.coreData?.poolAddrInUsed?.lowercased()
                
                refreshControl = UIRefreshControl()
                refreshControl?.tintColor = UIColor.red
                refreshControl?.addTarget(self, action: #selector(self.reloadMembership(_:)), for: .valueChanged)
                tableView.addSubview(refreshControl!)
        }
        
        override func viewDidDisappear(_ animated: Bool) {
                super.viewDidDisappear(animated)
                if curPoolAddr?.lowercased() != AppSetting.coreData?.poolAddrInUsed?.lowercased(){
                        AppSetting.coreData?.poolAddrInUsed = curPoolAddr?.lowercased()
                        AppSetting.coreData?.minerAddrInUsed = ""
                        DataShareManager.saveContext(DataShareManager.privateQueueContext())
                        PostNoti(HopConstants.NOTI_POOL_INUSE_CHANGED)
                }
        }
        
        @objc private func reloadMembership(_ sender: Any?){
                AppSetting.workQueue.async {
                        MembershipUI.syncAllMyMemberships()
                        self.validPoolArr =  MembershipUI.MemberArray()
                        DispatchQueue.main.async {
                                self.refreshControl?.endRefreshing()
                                self.tableView.reloadData()
                        }
                }
        }
        
        // MARK: - Table view data source

        override func numberOfSections(in tableView: UITableView) -> Int {
                return 1
        }

        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return self.validPoolArr.count
        }

    
        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "PoolItemToChooseID", for: indexPath)
                if let c = cell as? PoolChoseItemTableViewCell{
                        let p_data = self.validPoolArr[indexPath.row]
                        let is_checked = p_data.poolAddr?.lowercased() == self.curPoolAddr?.lowercased()
                        c.initWith(member: p_data, isSelected: is_checked)
                        if is_checked{
                                self.curCell = c
                                self.curPoolAddr = p_data.poolAddr?.lowercased()
                        }
                }
                
                return cell
        }
        
        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                guard let cell = tableView.cellForRow(at: indexPath) as? PoolChoseItemTableViewCell else{
                        return
                }
                let p_data = self.validPoolArr[indexPath.row]
                self.curCell?.update(check:false)
                self.curPoolAddr = p_data.poolAddr?.lowercased()
                
                cell.update(check: true)
                self.curCell = cell
        }
}
