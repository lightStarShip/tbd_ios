//
//  CDMembership.swift
//  Pirate
//
//  Created by hyperorchid on 2020/10/7.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON
import web3swift

class MembershipEX:NSObject{
        
        public static var membership:CDMemberShip!
        public static var minerCredit:CDMinerCredit!
        
        public static func Membership(user:String, pool:String, miner:String) -> Bool{
                let dbContext = DataShareManager.privateQueueContext()
                var w = NSPredicate(format: "mps == %@ AND userAddr == %@ AND poolAddr == %@",
                                    HopConstants.DefaultPaymenstService,
                                    user, pool)//"0xfa0628a247e35ba340eb1d4a058ab8a9755dd044"

                
                guard let result =  NSManagedObject.findOneEntity(HopConstants.DBNAME_MEMBERSHIP,
                                             where: w,
                                             context: dbContext) as? CDMemberShip else{
                        NSLog("--------->Invalid Membership user=\(user) pool=\(pool)")
                        return false
                }
                
                w = NSPredicate(format: "mps == %@ AND userAddr == %@ AND minerID == %@", HopConstants.DefaultPaymenstService, user, miner)
                guard let mc = NSManagedObject.findOneEntity(HopConstants.DBNAME_MINERCREDIT,
                                                             where: w,
                                                             context: dbContext) as? CDMinerCredit else{
                        NSLog("--------->Invalid miner credit user=\(user) miner=\(miner)")
                        return false
                }
                NSLog("--------->\(result.toString())")
                membership = result
                
                NSLog("--------->\(mc.toString())")
                minerCredit = mc
                return true
        }
        
        public static func syncData() {
                let dbContext = DataShareManager.privateQueueContext()
                DataShareManager.saveContext(dbContext)
                DataShareManager.syncAllContext(dbContext)
        }
        
}

extension CDMemberShip{
        
        func toString() -> String{
                
                return "\nUserAccount =>{\nUserAddr=\(self.userAddr!)\n PoolAddr=\(self.poolAddr!)\n TokenBalance=\(self.tokenBalance)\n RemindPacket=\(self.packetBalance)\n  usedTraffic=\(self.usedTraffic)\n } "
        }
        
        public func update(tx: TransactionData){
                self.usedTraffic = tx.usedTraffic!
        }
}

extension CDMinerCredit{
        
        public func toString()->String{
                return "{\nuserAddr=\(self.userAddr!)\nminerID=\(self.minerID!)\ninCharge=\(self.inCharge)\ncredit=\(self.credit)}"
        }
        
        public func update(tx:TransactionData){
                self.credit = tx.minerCredit!
                self.inCharge -= tx.minerAmount!
                if self.inCharge < 0{
                        self.inCharge = 0
                }
        }
}
