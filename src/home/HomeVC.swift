//
//  FirstViewController.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/15.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit
import NetworkExtension
import web3swift
import SwiftyJSON

extension NEVPNStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .disconnected: return "Disconnected".locStr
        case .invalid: return "Invalid".locStr
        case .connected: return "Connected".locStr
        case .connecting: return "Connecting".locStr
        case .disconnecting: return "Disconnecting".locStr
        case .reasserting: return "Reconnecting".locStr
        @unknown default:
                return "unknown".locStr
        }
    }
}

class HomeVC: UIViewController {
        
        @IBOutlet weak var minerBGView: UIView!
        @IBOutlet weak var connectButton: UIButton!
        @IBOutlet weak var vpnStatusLabel: UILabel!
        @IBOutlet weak var minersIDLabel: UILabel!
        @IBOutlet weak var minersIPLabel: UILabel!
        @IBOutlet weak var minerZoneLabel: UILabel!
        @IBOutlet weak var packetBalanceLabel: UILabel!
        @IBOutlet weak var poolNameLabel: UILabel!
        @IBOutlet weak var poolAddrLabel: UILabel!
        @IBOutlet weak var globalModelSeg: UISegmentedControl!
        
        var vpnStatusOn:Bool = false
        var targetManager:NETunnelProviderManager? = nil
        
        override func viewDidLoad() {
                super.viewDidLoad()
                
                reloadManagers()
                
                let img = UIImage(named: "bg_image")!
                self.view.backgroundColor = UIColor(patternImage: img)
                
                setPoolMinersAddress()
                
                NotificationCenter.default.addObserver(self, selector: #selector(VPNStatusDidChange(_:)),
                                                       name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
                
                NotificationCenter.default.addObserver(self, selector: #selector(setPoolBalance(_:)),
                                                       name: HopConstants.NOTI_MEMBERSHIPL_CACHE_LOADED.name, object: nil)
                
                NotificationCenter.default.addObserver(self, selector: #selector(setPoolName(_:)),
                                                       name: HopConstants.NOTI_POOL_CACHE_LOADED.name, object: nil)
                
                NotificationCenter.default.addObserver(self, selector: #selector(setMinerDetails(_:)),
                                                       name: HopConstants.NOTI_MINER_CACHE_LOADED.name, object: nil)
                
                NotificationCenter.default.addObserver(self, selector: #selector(poolChanged(_:)),
                                                       name: HopConstants.NOTI_POOL_INUSE_CHANGED.name, object: nil)
                
                NotificationCenter.default.addObserver(self, selector: #selector(minerChanged(_:)),
                                                       name: HopConstants.NOTI_MINER_INUSE_CHANGED.name, object: nil)
        }
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                guard let addr = Wallet.WInst.Address, addr != "" else {
                        self.showCreateDialog()
                        return
                }
        }
        
        func showCreateDialog(){
                self.performSegue(withIdentifier: "CreateAccountSegID", sender: self)
        }
        
        // MARK:  UI Action
        @IBAction func startOrStop(_ sender: Any) {
                
                guard let conn = self.targetManager?.connection else{
                        reloadManagers()
                        return
                }
                
                guard conn.status == .disconnected || conn.status == .invalid else {
                        conn.stopVPNTunnel()
                        return
                }
                
                guard let pool = AppSetting.coreData?.poolAddrInUsed else {
                        self.ShowTips(msg: "Choose your pool first".locStr)
                        return
                }
                guard let miner = AppSetting.coreData?.minerAddrInUsed else {
                        self.ShowTips(msg: "Choose your node first".locStr)
                        return
                }
                guard let balance = AppSetting.coreData?.tmpBalance, balance != 0 else{
                        self.ShowTips(msg: "Memship is invalid".locStr)
                        return
                }
                guard Int(balance) > HopConstants.RechargePieceSize else{
                        SwitchTab(Idx: 1){tab in
                                tab.alertMessageToast(title: "Insuffcient Founds".locStr)
                        }
                        return
                }
               
                guard  Wallet.WInst.IsOpen() else{
                        self.ShowOnePassword() {
                                do {
                                        try self._startVPN(pool: pool, miner: miner)
                                }catch let err{
                                        self.ShowTips(msg: err.localizedDescription)
                                        self.hideIndicator()
                                }
                        }
                        return
                }
                
                do {
                        try self._startVPN(pool: pool, miner: miner)
                }catch let err{
                        NSLog("=======>Failed to start the VPN: \(err)")
                        self.ShowTips(msg: err.localizedDescription)
                        self.hideIndicator()
                }
        }
        
        private func _startVPN(pool:String, miner:String) throws{
                
                self.showIndicator(withTitle: "VPN", and: "Starting VPN".locStr)
                
                guard let pri = Wallet.WInst.MainPrikey(),
                      let subPri = Wallet.WInst.SubPrikey() else {
                        throw HopError.wallet("No valid key data".locStr)
                }
                let (mIP, mPort) = try Miner.prepareMiner(mid: miner)
                let options = ["MAIN_PRI":pri as NSObject,
                               "SUB_PRI":subPri as NSObject,
                               "POOL_ADDR":pool as NSObject,
                               "USER_ADDR":Wallet.WInst.Address! as NSObject,
                               "USER_SUB_ADDR":Wallet.WInst.SubAddress! as NSObject,
                               "GLOBAL_MODE":AppSetting.isGlobalModel,
                               "STREAM_MODE":AppSetting.isStreamModel,
                               "MINER_ADDR":miner as NSObject,
                               "MINER_IP":mIP as NSObject,
                               "MINER_PORT":mPort as NSObject] as? [String : NSObject]
                
                
                try self.targetManager!.connection.startVPNTunnel(options: options)
        }
        
        @objc func VPNStatusDidChange(_ notification: Notification?) {
                
                defer {
                        if self.vpnStatusOn{
                                connectButton.setBackgroundImage(UIImage.init(named: "Con_icon"), for: .normal)
                        }else{
                                connectButton.setBackgroundImage(UIImage.init(named: "Dis_butt"), for: .normal)
                        }
                }
                
                guard  let status = self.targetManager?.connection.status else{
                        return
                }
                
                NSLog("=======>VPN Status changed:[\(status.description)]")
                self.vpnStatusLabel.text = status.description
                self.vpnStatusOn = status == .connected
                if status == .invalid{
                        self.targetManager?.loadFromPreferences(){
                                err in
                                NSLog("=======>VPN loadFromPreferences [\(err?.localizedDescription  ?? "Success" )]")
                        }
                }
                
                if status == .connected || status == .disconnected{
                        self.hideIndicator()
                }
        }
        
        @IBAction func changeModel(_ sender: UISegmentedControl) {
                let old_model = AppSetting.isGlobalModel
                
                switch sender.selectedSegmentIndex{
                        case 0:
                                AppSetting.isGlobalModel = false
                        case 1:
                                AppSetting.isGlobalModel = true
                default:
                        AppSetting.isGlobalModel = false
                }
                
                self.notifyModelToVPN(sender:sender, oldStatus:old_model)
        }
        
        @IBAction func ShowPoolChooseView(_ sender: Any) {
                self.performSegue(withIdentifier: "ChoosePoolsViewControllerSS", sender: self)
        }
        
        @IBAction func ShowMinerChooseView(_ sender: Any) {
                guard let _ = AppSetting.coreData?.poolAddrInUsed else {
                        self.ShowTips(msg: "Choose your pool first".locStr)
                        return
                }
                
                self.performSegue(withIdentifier: "ChooseMinersViewControllerSS", sender: self)
        }
        
        func setModelStatus(sender: UISegmentedControl, oldStatus:Bool){
                DispatchQueue.main.async {
                        if oldStatus{
                                sender.selectedSegmentIndex = 1
                        }else{
                                sender.selectedSegmentIndex = 0
                        }
                }
        }
        
        // MARK: - VPN Manager
        func reloadManagers() {
                
                NETunnelProviderManager.loadAllFromPreferences() { newManagers, error in
                        if let err = error {
                                NSLog(err.localizedDescription)
                                return
                        }
                        
                        guard let vpnManagers = newManagers else { return }

                        NSLog("=======>vpnManager=\(vpnManagers.count)")
                        if vpnManagers.count > 0{
                                self.targetManager = vpnManagers[0]
                                self.getModelFromVPN()
                        }else{
                                self.targetManager = NETunnelProviderManager()
                        }
                        
                        self.targetManager?.loadFromPreferences(completionHandler: { err in
                                if let err = error {
                                        NSLog(err.localizedDescription)
                                        return
                                }
                                self.setupVPN()
                        })
                }
        }
        
        func setupVPN(){
                
                targetManager?.localizedDescription = "Hyper Orchid Protocol-jack".locStr
                targetManager?.isEnabled = true
                
                let providerProtocol = NETunnelProviderProtocol()
                providerProtocol.serverAddress = "HOP BlockChain -jack".locStr
                targetManager?.protocolConfiguration = providerProtocol
                
                targetManager?.saveToPreferences { err in
                        if let saveErr = err{
                                NSLog("save preference err:\(saveErr.localizedDescription)")
                                return
                        }
                        self.VPNStatusDidChange(nil)
                }
        }
        
        private func getModelFromVPN(){
                guard let session = self.targetManager?.connection as? NETunnelProviderSession,
                        session.status != .invalid else{
                                NSLog("=======>Can't not load global model")
                                return
                }
                guard let message = try? JSON(["GetModel": true]).rawData() else{
                        return
                }
                try? session.sendProviderMessage(message){reponse in
                        guard let rs = reponse else{
                                return
                        }
                        let param = JSON(rs)
                        AppSetting.isGlobalModel = param["Global"].bool ?? false
                        self.setModelStatus(sender: self.globalModelSeg, oldStatus: AppSetting.isGlobalModel)
                        NSLog("=======>Curretn global model is [\(AppSetting.isGlobalModel)]")
                }
        }
        
        private func notifyModelToVPN(sender: UISegmentedControl, oldStatus:Bool){
                
                guard self.vpnStatusOn == true,
                        let session = self.targetManager?.connection as? NETunnelProviderSession,
                        session.status != .invalid else{
                                return
                }
                guard let message = try? JSON(["Global": AppSetting.isGlobalModel]).rawData() else{
                        return
                }
                do{
                        try session.sendProviderMessage(message)
                        
                }catch let err{
                        self.setModelStatus(sender: sender, oldStatus: oldStatus)
                        self.ShowTips(msg: err.localizedDescription)
                }
        }
        
        // MARK - pool changed
        @objc func poolChanged(_ notification: Notification?) {
                guard let poolAddr = AppSetting.coreData?.poolAddrInUsed, poolAddr != "" else{
                        return
                }
                if let mem = MembershipUI.Cache[poolAddr.lowercased()]  {
                        let balance = mem.packetBalance - Double(mem.usedTraffic)
                        AppSetting.coreData?.tmpBalance = balance
                }
                
                self.performSegue(withIdentifier: "ChooseMinersViewControllerSS", sender: self)
        }
        
        @objc func minerChanged(_ notification: Notification?) {
                if self.targetManager?.connection.status == .connected{
                        self.targetManager?.connection.stopVPNTunnel()
                }
                
                setPoolMinersAddress()
                setPoolName(nil)
                setPoolBalance(nil)
                setMinerDetails(nil)
        }
        
        private func setPoolMinersAddress(){
                DispatchQueue.main.async {
                        if let poolAddr = AppSetting.coreData?.poolAddrInUsed, poolAddr != ""{
                                self.poolAddrLabel.text = poolAddr
                                self.packetBalanceLabel.text = AppSetting.coreData?.tmpBalance.ToPackets()
                        }else{
                                self.poolAddrLabel.text = "Choose one pool please".locStr
                                self.packetBalanceLabel.text = "0.0"
                                self.poolNameLabel.text = "NAN".locStr
                        }
                        
                        if let minerAddr = AppSetting.coreData?.minerAddrInUsed, minerAddr != ""{
                                self.minersIDLabel.text = minerAddr
                        }else{
                                self.minersIDLabel.text = "Choose one miner please".locStr
                                self.minerZoneLabel.text = "NAN".locStr
                                self.minersIPLabel.text = "NAN".locStr
                        }
                }
        }
        
        @objc func setPoolName(_ notification: Notification?){
                guard let poolAddr = AppSetting.coreData?.poolAddrInUsed, poolAddr != "" else{return }
                if let pool = Pool.CachedPool[poolAddr]{
                        DispatchQueue.main.async {self.poolNameLabel.text = pool.Name}
                }
                
        }
        
        @objc func setPoolBalance(_ notification: Notification?){
                guard let balance = AppSetting.coreData?.tmpBalance else {
                        return
                }
                DispatchQueue.main.async {self.packetBalanceLabel.text = balance.ToPackets()}
        }
        
        @objc func setMinerDetails(_ notification: Notification?){DispatchQueue.main.async {
                guard let minerAddr = AppSetting.coreData?.minerAddrInUsed, minerAddr != "" else{
                        self.minersIDLabel.text = "Choose one miner please".locStr
                        self.minerZoneLabel.text = "NAN".locStr
                        self.minersIPLabel.text = "NAN".locStr
                        return
                }
                if let m_data = Miner.CachedMiner[minerAddr.lowercased()]{
                        self.minerZoneLabel.text = m_data.zon
                        self.minersIPLabel.text = m_data.ipAddr
                }
        }}
}
