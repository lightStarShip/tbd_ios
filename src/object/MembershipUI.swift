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
        
        public static func MemberArray() ->[CDMemberShip]{
                return Array(Cache.values)
        }
        
        override init() {
                super.init()
        }
        
        public static func loadCache(){
                
                guard let addr = Wallet.WInst.Address else{
                        return
                }
                
                Cache.removeAll()
                
                let dbContext = DataShareManager.privateQueueContext()
                let w = NSPredicate(format: "mps == %@ AND userAddr == %@", HopConstants.DefaultPaymenstService, addr)
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
                        let poolAddr = cData.poolAddr!.lowercased()
                        Cache[poolAddr] = cData
                        
                        NSLog("=======>Membership addr=\(addr) pool=\(cData.poolAddr ?? "<->")")
                        
                        if cData.needReload{
                                guard let data = IosLibMemberShipData(addr, poolAddr) else {
                                        continue
                                }
                                let json = JSON(data)
                                cData.updateByMemberDetail(json: json, addr: addr)
                        }
                        
                        if AppSetting.coreData?.poolAddrInUsed?.lowercased() == cData.poolAddr!.lowercased(){
                                let balance = cData.packetBalance - Double(cData.usedTraffic)
                                AppSetting.coreData?.tmpBalance = balance
                                PostNoti(HopConstants.NOTI_MEMBERSHIPL_CACHE_LOADED)
                        }
                }
        }
        
        
        public static func syncAllMyMemberships(){
                
                guard let addr = Wallet.WInst.Address, Pool.CachedPool.count > 0 else{
                        return
                }
                let poolAddr = Array(Pool.CachedPool.keys)
                let pool_str = JSON(poolAddr).rawString()
            
                guard let validPoolData = IosLibRandomConn(pool_str) else {
                        NSLog("======>All pools are unavailable")
                        return
                }
                
                guard let validPool = String(data:validPoolData, encoding: .utf8) else {
                        return
                }

                NSLog("======>valid pool to query is[\(validPool)]")
                guard let data = IosLibAvailablePools(addr, validPool) else{return}
                let poolJson = JSON(data)
                
            
                var idx = 0
                Cache.removeAll()
                let dbContext = DataShareManager.privateQueueContext()
                
                while (idx < poolJson.count){
                        let poolAddr = poolJson[idx].string!.lowercased()
                        idx += 1
                    
                        let w = NSPredicate(format: "mps == %@ AND userAddr == %@ AND poolAddr == %@",
                                        HopConstants.DefaultPaymenstService,
                                        addr,
                                        poolAddr)
                        let request = NSFetchRequest<NSFetchRequestResult>(entityName: HopConstants.DBNAME_MEMBERSHIP)
                        request.predicate = w

                        
                        guard let data = IosLibMemberShipData(addr, poolAddr) else {
                                guard let result = try? dbContext.fetch(request).last as? CDMemberShip else {
                                        let cData = CDMemberShip.newUnavailableMembership(pool:poolAddr, user:addr)
                                        Cache[poolAddr] = cData
                                        continue
                                }
                                if result.available {
                                    result.updateUnavailableByMemberDetail(addr: addr)
                                }
                                Cache[poolAddr] = result
                                continue
                        }
                        let json = JSON(data)
                        guard let result = try? dbContext.fetch(request).last as? CDMemberShip else{
                                let cData = CDMemberShip.newMembership(json: json, pool:poolAddr, user:addr)
                                Cache[poolAddr] = cData
                                continue
                        }
                        
                        result.updateByMemberDetail(json: json, addr: addr)
                        Cache[poolAddr] = result
                        if AppSetting.coreData?.poolAddrInUsed?.lowercased() == poolAddr{
                                let balance = result.packetBalance - Double(result.usedTraffic)
                                AppSetting.coreData?.tmpBalance = balance
                                PostNoti(HopConstants.NOTI_MEMBERSHIPL_CACHE_LOADED)
                        }
                }
                
                DataShareManager.saveContext(dbContext)
                DataShareManager.syncAllContext(dbContext)
                PostNoti(HopConstants.NOTI_MEMBERSHIP_SYNCED)
        }
        
}

extension CDMemberShip{
        
        public static func newMembership(json:JSON, pool:String, user:String) -> CDMemberShip {
                let dbContext = DataShareManager.privateQueueContext()
                let data = CDMemberShip(context: dbContext)
                data.poolAddr = pool
                data.userAddr = user
                data.mps = HopConstants.DefaultPaymenstService
                data.tokenBalance = json["left_token_balance"].double ?? 0
                data.packetBalance = json["left_traffic_balance"].double ?? 0
                data.usedTraffic = json["used_traffic"].int64 ?? 0
                data.available = true
                return data
        }

        public static func newUnavailableMembership(pool:String, user:String) -> CDMemberShip {
                let dbContext = DataShareManager.privateQueueContext()
                let data = CDMemberShip(context: dbContext)
                data.poolAddr = pool
                data.userAddr = user
                data.mps = HopConstants.DefaultPaymenstService
                data.tokenBalance = 0
                data.packetBalance = 0
                data.usedTraffic = 0
                data.available = false
                return data
        }
    
        func updateUnavailableByMemberDetail(addr:String){
                self.available = false
        }

        
        //TODO::Make sure how to change local receipt
        func updateByMemberDetail(json:JSON, addr:String){
                self.available = true
                
                self.tokenBalance = json["left_token_balance"].double ?? 0
                self.packetBalance = json["left_traffic_balance"].double ?? 0
                let credit = json["used_traffic"].int64 ?? 0
                self.usedTraffic = credit
        }
}


extension CDMinerCredit{
                
        public static func newEntity(user:String, mid:String) -> CDMinerCredit{
                let dbContext = DataShareManager.privateQueueContext()
                let data = CDMinerCredit(context: dbContext)
                data.credit = 0
                data.inCharge = 0
                data.minerID = mid
                data.mps = HopConstants.DefaultPaymenstService
                data.userAddr = user
                return data
        }
        
        public func update(json:JSON) throws{
                
                let credit = json["miner_credit"].int64 ?? 0
//                if self.credit < credit{
                        self.credit = credit
//                }
                
                let pool = json["pool"].string!
                guard let mem = MembershipUI.Cache[pool.lowercased()] else{
                        throw HopError.minerErr("invalid pool address in tx synced")
                }
                let usedTR = json["used_traffic"].int64 ?? 0
                if mem.usedTraffic < usedTR{
                        mem.usedTraffic = usedTR
                        AppSetting.coreData?.tmpBalance =  mem.packetBalance - Double(mem.usedTraffic)
                        PostNoti(HopConstants.NOTI_MEMBERSHIPL_CACHE_LOADED)
                }
                if mem.usedTraffic < credit{
                        mem.usedTraffic = credit
                }
        }
}
