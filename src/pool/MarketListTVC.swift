//
//  MarketListTVC.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/15.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit
import BigInt
import web3swift

class MarketListTVC: UITableViewController {
        // MARK: - Table view variables
    
    let dbContext = DataShareManager.privateQueueContext()
        var poolList:[Pool] = []
        var poolAddrToRecharge:String?
        
        // MARK: - Table view init
        override func viewDidLoad() {
                super.viewDidLoad()
    
                self.poolList = Pool.ArrayData()
                
                self.tableView.estimatedRowHeight = 170
                self.tableView.rowHeight = 170
                self.tableView.allowsSelection = false
            
                refreshControl = UIRefreshControl()
                refreshControl!.tintColor = UIColor.red
                refreshControl!.addTarget(self, action: #selector(self.reloadPoolList(_:)), for: .valueChanged)
                tableView.addSubview(refreshControl!)
                
                
                NotificationCenter.default.addObserver(self, selector: #selector(poolLoaded(_:)), name: HopConstants.NOTI_POOL_CACHE_LOADED.name, object: nil)
        }
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        @objc func poolLoaded(_ notification: Notification?)  {
                self.poolList = Pool.ArrayData()
                DispatchQueue.main.async {
                        self.tableView.reloadData()
                }
        }
        // MARK: - Table view data source
        override func numberOfSections(in tableView: UITableView) -> Int {
                return 1
        }

        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return poolList.count
        }

        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "PoolDetailInMarketCID", for: indexPath)
                if let c = cell as? PoolDetailsCellTableViewCell{
                        let pool_details = self.poolList[indexPath.row]
                        c.initWith(details:pool_details, index: indexPath.row)
                        c.delegate = self
                        return c
                }
                return cell
        }

        /**/
        // MARK: - Navigation

        // In a storyboard-based application, you will often want to do a little preparation before navigation
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
                if segue.identifier == "ShowRechargePage"{
                        let vc : RechargeViewController = segue.destination as! RechargeViewController
                        vc.poolAddr = self.poolAddrToRecharge!
                }
        }

//        @IBAction func BuyThisPool(_ sender: UIButton) {
//                guard let _ = Wallet.WInst.Address else{
//                        self.ShowTips(msg: "Create your account first".locStr)
//                        return
//                }
//                let tokenSum = 100 * HopConstants.DefaultTokenDecimal2
//                guard Wallet.WInst.approve > tokenSum else{
//                        SwitchTab(Idx: 2){ tab in
//                                tab.alertMessageToast(title: "Please Approve Token Usage".locStr)
//                        }
//                        return
//                }
//
//                let pool_details = self.poolList[sender.tag]
//                self.poolAddrToRecharge = pool_details.Address
//
//                self.performSegue(withIdentifier: "ShowRechargePage", sender: self)
//        }
        
        //MARK: - object c
        @objc func reloadPoolList(_ sender: Any?){
                AppSetting.workQueue.async {
                        Pool.syncPoolFromETH()
                        self.poolList = Pool.ArrayData()
                        DispatchQueue.main.async {
                                self.refreshControl?.endRefreshing()
                                self.tableView.reloadData()
                        }
                }
        }
}

extension MarketListTVC: PoolDetailCellDelegate {
    
    func clickJoinPool(_ idx: Int) {
        guard let _ = Wallet.WInst.Address else{
                self.ShowTips(msg: "Create your account first".locStr)
                return
        }
        let tokenSum = 100 * HopConstants.DefaultTokenDecimal2
        guard Wallet.WInst.approve > tokenSum else{
                SwitchTab(Idx: 2){ tab in
                        tab.alertMessageToast(title: "Please Approve Token Usage".locStr)
                }
                return
        }
        
        let pool_details = self.poolList[idx]
        self.poolAddrToRecharge = pool_details.Address
        
        self.performSegue(withIdentifier: "ShowRechargePage", sender: self)
    }

}
