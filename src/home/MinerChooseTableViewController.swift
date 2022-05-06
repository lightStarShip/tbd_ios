//
//  MinerChooseTableViewController.swift
//  Pirate
//
//  Created by hyperorchid on 2020/3/2.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit
import IosLib
import SwiftyJSON
class MinerChooseViewController: UIViewController {

        @IBOutlet weak var minerListView: UITableView!
        
    
        var minerArray:[CDMiner] = []
        var curPool:String?
        var curMiner:String?
        var curCell:MinerDetailsTableViewCell?
        
        override func viewDidLoad() {
                super.viewDidLoad()
                
                minerListView.rowHeight = 97
                curPool = AppSetting.coreData?.poolAddrInUsed
                curMiner = AppSetting.coreData?.minerAddrInUsed
                
                AppSetting.workQueue.async {
                        Miner.LoadCache()
                }
                NotificationCenter.default.addObserver(self, selector: #selector(minerSynced(_:)),
                                                       name: HopConstants.NOTI_MINER_SYNCED.name, object: nil)
                
                NotificationCenter.default.addObserver(self, selector: #selector(minerSynced(_:)),
                                                       name: HopConstants.NOTI_MINER_CACHE_LOADED.name, object: nil)
        }
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        @objc func minerSynced(_ notification: Notification?) {
                minerArray = Miner.ArrayData()
                DispatchQueue.main.async {
                        self.minerListView.reloadData()
                }
        }
        
        override func viewDidDisappear(_ animated: Bool) {
                super.viewDidDisappear(animated)
                
                if curMiner?.lowercased() != AppSetting.coreData?.minerAddrInUsed?.lowercased(){
                        AppSetting.coreData?.minerAddrInUsed = curMiner
                        DataShareManager.saveContext(DataShareManager.privateQueueContext())
                        PostNoti(HopConstants.NOTI_MINER_INUSE_CHANGED)
                }
        }
        
        @IBAction func LoadRandomMiners(_ sender: Any) {
                self.showIndicator(withTitle: "", and: "Loading miners......".locStr)
                AppSetting.workQueue.async {
                        Miner.SyncMinerUnder(pool: self.curPool!)
                        self.hideIndicator()
                }
        }
        
        @IBAction func PingAction(_ sender: UIButton) {
                let m_data = self.minerArray[sender.tag]
                self.showIndicator(withTitle: "", and: "Ping......".locStr)
                
                BasUtil.queue.async {
                        defer {
                                self.hideIndicator()
                                DispatchQueue.main.async {
                                       self.minerListView.reloadData()
                                }
                       }
                        
                        let miner_addr = m_data.subAddr!
                        guard let ret = IosLibTestPing(miner_addr) else{
                                m_data.ipAddr = "no bas".locStr
                                return
                        }
                        let jsonData = JSON(ret)
                        m_data.ipAddr = jsonData["IP"].string
                        m_data.ping = jsonData["Ping"].double ?? -1
                }
        }
        
        
        @IBAction func PingAllMiners(_ sender: Any) {
                
                guard self.minerArray.count > 0 else {
                        return
                }
                self.showIndicator(withTitle: "", and: "Ping all nodes......".locStr)

                BasUtil.queue.async {
                        let dispatchGrp = DispatchGroup()
                        
                        for miner in self.minerArray{
                                dispatchGrp.enter()
                                
                                guard let ret = IosLibTestPing(miner.subAddr!) else{
                                        miner.ipAddr = "no bas".locStr
                                        dispatchGrp.leave()
                                        continue
                                }
                                let jsonData = JSON(ret)
                                miner.ipAddr = jsonData["IP"].string
                                miner.ping = jsonData["Ping"].double ?? -1
                                
                                dispatchGrp.leave()
                        }
                        
                        dispatchGrp.notify(queue: DispatchQueue.main){
                                self.minerListView.reloadData()
                                self.hideIndicator()
                        }
                }

        }

}

// MARK: - Table view data source

extension MinerChooseViewController:UITableViewDelegate, UITableViewDataSource{
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MinerItemToChoose", for: indexPath)
                
                if let c = cell as? MinerDetailsTableViewCell{
                        var m_data = self.minerArray[indexPath.row]
                        let checked = curMiner?.lowercased() == m_data.subAddr?.lowercased()
                        c.initWith(minerData:&m_data, isChecked: checked, index: indexPath.row)
                        if checked{
                                self.curCell = c
                        }
                        
                        return c
                }
                return cell
        }
        
        
        func numberOfSections(in tableView: UITableView) -> Int {
                return 1
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
           return self.minerArray.count
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                let miner = self.minerArray[indexPath.row]
                self.curCell?.update(check:false)
                curMiner = miner.subAddr
                guard let c = tableView.cellForRow(at: indexPath) as? MinerDetailsTableViewCell else{
                        return
                }
                c.update(check:true)
                self.curCell = c
        }
}
