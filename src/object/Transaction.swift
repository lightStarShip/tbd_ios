//
//  Transaction.swift
//  Pirate
//
//  Created by wesley on 2020/9/22.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit
import IosLib
import CoreData

public enum TransactionStatus:Int16 {
        case pending
        case success
        case fail
        case nosuch
        
        var name:String {
                switch self {
                case .pending:
                        return "Pending".locStr
                case .fail:
                        return "Failed".locStr
                case .success:
                        return "Success".locStr
                case .nosuch:
                        return "No suche TX".locStr
                }
        }
        var StatusBGColor:UIColor{
                switch self {
                case .success:
                        return UIColor.init(hex: "#458AF933")!
                case .fail:
                        return UIColor.init(hex: "#F9704533")!
                case .pending, .nosuch:
                        return UIColor.init(hex: "#FFAC0033")!
                }
        }
        
        var StatusBorderColor:CGColor{
                switch self {
                case .success:
                        return UIColor.init(hex: "#458AF94D")!.cgColor
                case .fail:
                        return UIColor.init(hex: "#F970454D")!.cgColor
                case .pending, .nosuch:
                        return UIColor.init(hex: "#FFAC004D")!.cgColor
                }
        }
        
        var StatusTxtColor:UIColor{
                switch self {
                case .success:
                        return UIColor.init(hex: "#458AF9FF")!
                case .fail:
                        return UIColor.init(hex: "#F97045FF")!
                case .pending, .nosuch:
                        return UIColor.init(hex: "#FFB214FF")!
                }
        }
}


public enum TransactionType:Int16 {
        case unknown
        case applyEth
        case applyToken
        case authorize
        case buyPool
        
        var name:String{
                switch self {
                case .applyEth:
                        return "Apply GAS".locStr
                case .applyToken:
                        return "Apply Token".locStr
                case .buyPool:
                        return "Apply Service".locStr
                case .unknown:
                        return "Unknown".locStr
                case .authorize:
                        return "APP Authorization".locStr
                }
        }
        
}
        
        
class Transaction : NSObject {
        
        public static var CachedTX:[String : Transaction] = [:]
        
        var coreData:CDTransaction?
        var txValue:Double = 0
        var txStatus:TransactionStatus = .pending
        var txHash:String?
        var txType:TransactionType = .unknown
        
        override init() {
                super.init()
        }
        
        public static func reLoad(){
                
                guard let addr = Wallet.WInst.Address else{
                        return
                }
                CachedTX.removeAll()
                let dbContext = DataShareManager.privateQueueContext()
                let w = NSPredicate(format: "walletAddr == %@", addr)
                let order = [NSSortDescriptor.init(key: "time", ascending: false)]
                guard let txArr = NSManagedObject.findEntity(HopConstants.DBNAME_TRASACTION,
                                                             where: w,
                                                             orderBy: order,
                                                             context: dbContext) as? [CDTransaction] else{
                        return
                }
                
                for cData in txArr{
                        let txObj = Transaction(coredata:cData)
                        CachedTX[txObj.txHash!] = txObj
                        
                        if txObj.txStatus == .pending || txObj.txStatus == .nosuch{
                                let statusInt = IosLibTXStatus(txObj.txHash)
                                txObj.txStatus = TransactionStatus(rawValue:statusInt) ?? .nosuch
                                txObj.coreData?.status = txObj.txStatus.rawValue
                        }
                }
                
                PostNoti(HopConstants.NOTI_TX_SYNC_SUCCESS)
        }
        
        public static func updateStatus(forTx tx: String){
                guard let obj = CachedTX[tx] else{
                        return
                }
                let status = IosLibTXStatus(tx)
                obj.coreData?.status = status
                obj.txStatus = TransactionStatus(rawValue: status) ?? .nosuch
                
                DataShareManager.saveContext(DataShareManager.privateQueueContext())
        }
        
        public init(tx:String, typ:TransactionType, value:Double? = nil){
                super.init()
                txHash = tx
                txType = typ
                txValue = value ?? 0
                txStatus = .pending
        }
        
        public init(coredata:CDTransaction){
                super.init()
                coreData = coredata
                self.txValue = coredata.txValue
                self.txStatus = TransactionStatus(rawValue: coredata.status) ?? .pending
                self.txType = TransactionType(rawValue: coredata.actType) ?? .unknown
                self.txHash = coredata.txHash
        }
        
        public static func applyFreeEth(forAddr address:String) -> Bool{
                guard address != ""  else {
                        return false
                }
                
                let txHash = IosLibApplyFreeEth(address)
                if txHash == ""{
                        return false
                }
                
                let obj = Transaction(tx: txHash, typ: .applyEth, value: 0.1)
                saveTX(obj, forAddress: address)
                return true
        }
        
        public static func applyFreeToken(forAddr address:String) -> Bool{
                guard address != ""  else {
                        return false
                }
                
                let txHash = IosLibApplyFreeToken(address)
                if txHash == ""{
                        return false
                }
                let obj = Transaction(tx: txHash, typ: .applyToken, value: 1000)
                saveTX(obj, forAddress: address)
                return true
        }
        
        public static func CachedArray() -> [Transaction]{
                return Array(Transaction.CachedTX.values)
        }
        
        private static func saveTX(_ obj:Transaction, forAddress address:String){
                
                CachedTX[obj.txHash!] = obj
                
                let dbCtx = DataShareManager.privateQueueContext()
                let cdata = CDTransaction(context: dbCtx)
                cdata.initByObj(obj: obj, addr: address)
                obj.coreData = cdata
                
                IosLibMonitorTx(obj.txHash, HopConstants.NOTI_TX_STATUS_CHANGED.name.rawValue)
                DataShareManager.saveContext(dbCtx)
                PostNoti(HopConstants.NOTI_TX_SYNC_SUCCESS)
        }
        
        
        public static func ApproveThisApp(forAddress addr: String) -> Bool{
               
                let txHash = IosLibApproveAPP()
                if txHash == ""{
                        return false
                }
                let obj = Transaction(tx: txHash, typ: .authorize, value: 0)
                saveTX(obj, forAddress: addr)
                return true
        }
        
        public static func BuyPacket(userAddr:String, poolAddr:String, token:Double) ->Bool{
                let txHash = IosLibBuyPackets(userAddr, poolAddr, token)
                if txHash == ""{
                        return false
                }
                
                let obj = Transaction(tx: txHash, typ: .buyPool, value: token)
                saveTX(obj, forAddress: Wallet.WInst.Address!)
                return true
        }
}

extension CDTransaction{
        
        func initByObj(obj:Transaction, addr:String){
                self.walletAddr = addr
                self.txHash = obj.txHash
                self.actType = obj.txType.rawValue
                self.status = obj.txStatus.rawValue
                self.txValue = obj.txValue
                self.time = Int64(Date.init().timeIntervalSince1970)
        }
}
