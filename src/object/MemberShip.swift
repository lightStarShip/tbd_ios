//
//  MemberShip.swift
//  Pirate
//
//  Created by wesley on 2020/9/29.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import CoreData
import IosLib
import SwiftyJSON

class MembershipUI:NSObject{
        public static var Cache:[String:CDMemberShip] = [:]
        
        var coreData:CDMemberShip?
        
        public static func MemberArray() ->[CDMemberShip]{
                return Array(Cache.values)
        }
        
        override init() {
                super.init()
        }
        
        public static func reLoad(){
                
                guard let addr = Wallet.WInst.Address else{
                        return
                }
                
                Cache.removeAll()
                
                let dbContext = DataShareManager.privateQueueContext()
                let w = NSPredicate(format: "mps == %@ AND userAddr == %@ AND available == true", HopConstants.DefaultPaymenstService, addr)
                let order = [NSSortDescriptor.init(key: "epoch", ascending: false)]
                guard let memberArr = NSManagedObject.findEntity(HopConstants.DBNAME_MEMBERSHIP,
                                                             where: w,
                                                             orderBy: order,
                                                             context: dbContext) as? [CDMemberShip] else{
                        return
                }
                
                if memberArr.count == 0{
                        AppSetting.workQueue.async {
                                syncAllMyMemberships()
                        }
                        return
                }
        
                for cData in memberArr{
                        cData.available = false
                        Cache[cData.poolAddr!.lowercased()] = cData
                }
                
                PostNoti(HopConstants.NOTI_MEMBERSHIPL_CACHE_LOADED)
                guard let data = IosLibAvailablePools(addr) else{
                        return
                }
                
                let poolJson = JSON(data)
                var needSync = false
                for (poolAddr, _):(String, JSON) in poolJson{
                        guard let obj = Cache[poolAddr.lowercased()] else{
                                needSync = true
                                continue
                        }
                        obj.available = true
                }
                
                if needSync{
                        AppSetting.workQueue.async {
                                syncAllMyMemberships()
                        }
                }
        }
        
        //TODO:: test this carefully
        public static func syncAllMyMemberships(){
                guard let addr = Wallet.WInst.Address else{
                        return
                }
                
                Cache.removeAll()
                guard let data = IosLibMemberShipData(addr) else {
                        return
                }
                
                let json = JSON(data)
                let dbContext = DataShareManager.privateQueueContext()
                
                for (poolAddr, subJson):(String, JSON) in json {
                        
                        let w = NSPredicate(format: "mps == %@ AND userAddr == %@ AND poolAddr == %@",
                                            HopConstants.DefaultPaymenstService,
                                            addr,
                                            poolAddr)
                        
                        let request = NSFetchRequest<NSFetchRequestResult>(entityName: HopConstants.DBNAME_MEMBERSHIP)
                        request.predicate = w
                        guard let result = try? dbContext.fetch(request).last as? CDMemberShip else{
                                let cData = CDMemberShip.newMembership(json: subJson, pool:poolAddr, user:addr)
                                Cache[poolAddr.lowercased()] = cData
                                continue
                        }
                        
                        result.updateByETH(json: subJson, addr: addr)
                        Cache[poolAddr.lowercased()] = result
                }
                
                DataShareManager.saveContext(dbContext)
                DataShareManager.syncAllContext(dbContext)
                PostNoti(HopConstants.NOTI_MEMBERSHIP_SYNCED)
                PostNoti(HopConstants.NOTI_MEMBERSHIPL_CACHE_LOADED)
        }
        
//        public func syncMemberDetailFromETH(){
//                guard let addr = Wallet.WInst.Address else{
//                        return
//                }
//
//                guard let data = IosLibUserDataOnBlockChain(coreData?.userAddr, self.poolAddr) else{
//                        return
//                }
//
//                let json = JSON(data)
//                let dbContext = DataShareManager.privateQueueContext()
//                let w = NSPredicate(format: "mps == %@ AND userAddr == %@ AND poolAddr == %@",
//                                    HopConstants.DefaultPaymenstService,
//                                    addr,
//                                    obj.poolAddr)
//
//                let request = NSFetchRequest<NSFetchRequestResult>(entityName: HopConstants.DBNAME_MEMBERSHIP)
//                request.predicate = w
//                guard let result = try? dbContext.fetch(request).last as? CDMemberShip else{
//                        let cData = CDMemberShip(context: dbContext)
//                        cData.populate(obj: obj, addr: addr)
//                        obj.coreData = cData
//                        MemberShip.Cache[obj.poolAddr] = obj
//                        return
//                }
//                result.updateByObj(obj: obj, addr: addr)
//
//                DataShareManager.saveContext(dbContext)
//                DataShareManager.syncAllContext(dbContext)
//        }
}

extension CDMemberShip{
        
        public static func newMembership(json:JSON, pool:String, user:String) -> CDMemberShip {
                let dbContext = DataShareManager.privateQueueContext()
                let data = CDMemberShip(context: dbContext)
                data.poolAddr = pool
                data.userAddr = user
                data.mps = HopConstants.DefaultPaymenstService
                data.nonce = json["Nonce"].int64 ?? 0
                data.tokenBalance = json["TokenBalance"].double ?? 0
                data.packetBalance = json["RemindPacket"].double ?? 0
                data.expire = json["Expire"].string ?? ""
                data.epoch = json["Epoch"].int64 ?? 0
                data.microNonce = json["ClaimedMicNonce"].int64 ?? 0
                data.credit = 0
                data.curTXHash = nil
                data.inRecharge = 0
                data.available = true
                return data
        }
        
        func updateByETH(json:JSON, addr:String){
                
                self.available = true
                guard let nonce = json["Nonce"].int64 else{
                        return
                }
                if self.nonce >= nonce{
                        NSLog("======>[updateByETH]:nothing to update for pool[\(self.poolAddr ?? "")]")
                        return
                }
                
                let epoch = json["Epoch"].int64 ?? 0
                if self.epoch > epoch{
                        NSLog("======>[updateByETH]: [self opech =\(self.epoch)]invalid epoch[\(epoch)] info for pool[\(self.poolAddr ?? "")]")
                        return
                }
                
                guard let tokenBalance = json["TokenBalance"].double,
                      let packetBalance = json["RemindPacket"].double,
                      let expire = json["Expire"].string else{
                        NSLog("======>[updateByETH]: invalid josn[\(json)]")
                        return
                }
                
                if self.epoch == epoch{
                        self.nonce = nonce
                        self.tokenBalance = tokenBalance
                        self.packetBalance = packetBalance
                        self.expire = expire
                        
                        NSLog("======>[updateByETH]: update sucess nonce=[\(nonce)] epoch=[\(epoch)]")
                        return
                }
                
                guard let microNonce = json["ClaimedMicNonce"].int64,
                      let claimedAmount = json["ClaimedAmount"].int64 else{
                        NSLog("======>[updateByETH]: invalid josn[\(json)]")
                        return
                }
                
                if self.microNonce < microNonce{
                        NSLog("======>[updateByETH]: invalid microNonce=[\(microNonce)]")
                        return
                }
                
                self.nonce = nonce
                self.tokenBalance = tokenBalance
                self.packetBalance = packetBalance
                self.expire = expire
                self.microNonce = microNonce
                self.epoch = epoch
                
                let reminder = self.credit + self.inRecharge - claimedAmount
                if reminder < 0{
                        self.credit = 0
                        self.inRecharge = 0
                        NSLog("======>[updateByETH]:Something wrong [credit=\(self.credit)] [claimedAmount=\(claimedAmount)]")
                } else {
                        self.credit = reminder
                        self.inRecharge = 0
                        self.curTXHash = nil
                }
        }
}
