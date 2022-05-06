//
//  Wallet.swift
//  Pirate
//
//  Created by wesley on 2020/9/19.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import CoreData
import IosLib
import SwiftyJSON
import CryptoSwift
import Curve25519
import web3swift

class Wallet:NSObject{
        
        var Address:String?
        var SubAddress:String?
        var coreData:CDWallet?
        
        var tokenBalance:Double = 0
        var ethBalance:Double = 0
        var approve:Double = 0
        
        public static var WInst = Wallet()
        
        override init() {
                super.init()
                let w = NSPredicate(format:"mps == %@", HopConstants.DefaultPaymenstService)
                guard let core_data = NSManagedObject.findOneEntity(HopConstants.DBNAME_WALLET,
                                                              where: w,
                                                              context: DataShareManager.privateQueueContext()) as? CDWallet else{
                                return
                }
                
                guard let jsonStr = core_data.walletJSON, jsonStr != "" else {
                        return
                }
                
                guard IosLibLoadWallet(jsonStr) else {
                        NSLog("=======>[Wallet init] parse json failed[\(jsonStr)]")
                        return
                }

                self.Address = core_data.address
                self.SubAddress = core_data.subAddress
                self.tokenBalance = core_data.tokenBalance
                self.ethBalance = core_data.ethBalance
                self.approve = core_data.approve
                coreData = core_data
        }
        
        public func queryBalance(){
                
                guard let addr = self.Address, addr != "" else {
                        return
                }
                
                guard let bData = IosLibBalance(addr) else{
                        return
                }
                
                let jsonObj = JSON(bData)
                self.ethBalance = jsonObj["Eth"].double ?? 0
                self.tokenBalance = jsonObj["Hop"].double ?? 0
                self.approve = jsonObj["Approved"].double ?? 0
                
                self.coreData?.approve = self.approve
                self.coreData?.tokenBalance = self.tokenBalance
                self.coreData?.ethBalance = self.ethBalance
        }
        
        public func initByJson(_ jsonData:Data){
                let jsonObj = JSON(jsonData)
                self.Address = jsonObj["mainAddress"].string
                self.SubAddress = jsonObj["subAddress"].string
        }
        
        public static func NewInst(auth:String) -> Bool{
                guard let jsonData = IosLibNewWallet(auth) else{
                        return false
                }
                populateWallet(data: jsonData)
                
                return true
        }
        
        private static func populateWallet(data:Data){
                WInst.initByJson(data)
                
                let context = DataShareManager.privateQueueContext()
                let w = NSPredicate(format:"mps == %@", HopConstants.DefaultPaymenstService)
                var core_data = NSManagedObject.findOneEntity(HopConstants.DBNAME_WALLET,
                                                              where: w,
                                                              context: context) as? CDWallet
                if core_data == nil{
                        core_data = CDWallet(context: context)
                        core_data!.mps = HopConstants.DefaultPaymenstService
                }
                
                core_data!.walletJSON = String(data: data, encoding: .utf8)
                core_data!.address = WInst.Address
                core_data!.subAddress = WInst.SubAddress
                WInst.coreData = core_data
                DataShareManager.saveContext(context)
        }
        
        public static func ImportWallet(auth:String, josn:String) -> Bool{
                guard IosLibImportWallet(josn, auth) else {
                        return false
                }
                populateWallet(data: Data(josn.utf8))
                AppSetting.workQueue.async {
                        MembershipUI.syncAllMyMemberships()
                        PostNoti(HopConstants.NOTI_TX_STATUS_CHANGED)
                }
                
                return true
        }
        
        public static func IsValidAdress(addrStr:String)->Bool{
                return IosLibValidateAddress(addrStr)
        }
        
        public func IsOpen() -> Bool{
                return IosLibIsOpen()
        }
        
        public func OpenWallet(auth:String) -> Bool{
                return IosLibOpenWallet(auth)
        }
        
        public func MainPrikey() -> Data?{
                return IosLibPriKeyData()
        }
        
        public func SubPrikey() -> Data?{
                return IosLibSubPriKeyData()
        }
        
        func test() {
                
                if OpenWallet(auth: "123"){
                        
                        let priData = IosLibPriKeyData()!
                        NSLog("\(priData)")
                        
                        let addr1 = SECP256K1.privateToPublic(privateKey: priData)
                        let addr2 = SECP256K1.privateToPublic(privateKey: priData, compressed: true)
                        NSLog("--------->addr1==>\(addr1!.toHexString())--->addr2==>\(addr2!.toHexString())")
                        
                        
                        let data = "foo".data(using: .utf8)
                        let hash = data!.sha3(.keccak256)
                        NSLog("--------->hash data==>\(hash.toHexString())")
                        
                        let (sig, _) = SECP256K1.signForHash(hash: hash, privateKey: priData)
                        NSLog("--------->sig data==>\(sig!.toHexString())")
                        
                        let sig2 = IosLibVerify(data, sig)!
                        NSLog("--------->sig2 data==>\(sig2.toHexString())")
                       
                        let pubKey = SECP256K1.recoverPublicKey(hash: hash, signature: sig2, compressed: true)
                        NSLog("--------->recoverd pubKey==>\(pubKey!.toHexString())")
                        
                        let addr = Web3.Utils.publicToAddress(pubKey!)!
                        NSLog("--------->recoverd pubKey==>\(addr.address)")
                }
        }
        
        func test2() {
                
                if !OpenWallet(auth: "123"){
                    return
                }
                
                let priData = IosLibPriKeyData()!
                let _ = HopMessage.rcpSynMsg(from: HopConstants.DefaultPaymenstService,
                                                  pool: HopConstants.DefaultTokenAddr,
                                                  sigKey: priData)
 
                
        }
}
