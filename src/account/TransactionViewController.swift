//
//  TransactionViewController.swift
//  Pirate
//
//  Created by wesley on 2020/9/22.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class TransactionViewController: UIViewController {

        var tableData:[Transaction] = Transaction.CachedArray()
        var refreshControl: UIRefreshControl! = UIRefreshControl()
        @IBOutlet weak var tableview: UITableView!
        
        override func viewDidLoad() {
                super.viewDidLoad()
                tableview.rowHeight = 80
                refreshControl.tintColor = UIColor.red
                refreshControl.addTarget(self, action: #selector(self.reloadCachedTx(_:)), for: .valueChanged)
                tableview.addSubview(refreshControl)
                
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(txChanged(_:)),
                                                       name: HopConstants.NOTI_TX_STATUS_CHANGED.name,
                                                       object: nil)
        }
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        @objc private func reloadCachedTx(_ sender: Any?){
                AppSetting.workQueue.async {
                        Transaction.reLoad()
                        self.tableData = Transaction.CachedArray()
                        DispatchQueue.main.async { [self] in
                                self.refreshControl.endRefreshing()
                                self.tableview.reloadData()
                        }
                }
        }
        
        @objc func txChanged(_ notification: Notification?) {
                guard let tx = notification?.userInfo?["data"] as? String else{
                        return
                }
                
                Transaction.updateStatus(forTx: tx)
                DispatchQueue.main.async {
                        self.tableview.reloadData()
                }
        }
}

extension TransactionViewController:UITableViewDelegate, UITableViewDataSource{
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return self.tableData.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableview.dequeueReusableCell(withIdentifier: "TransactionTableViewCellID")
                guard let c = cell as? TransactionTableViewCell else {
                        return cell!
                }
                
                let tx = self.tableData[indexPath.row]
                c.fieldUP(tx)
                return c
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                let tx = self.tableData[indexPath.row]
                let urlStr = "\(HopConstants.EthScanUrl)\(tx.txHash!)"
                if let url = URL(string: urlStr) {
                        UIApplication.shared.open(url)
                }
        }
}
