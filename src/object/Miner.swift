//
//  Miner.swift
//  Pirate
//
//  Created by hyperorchid on 2020/10/5.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import CoreData
import Simple
import SwiftyJSON

class Miner : NSObject {
        var coreData:CDMiner?
        
        public static var CachedMiner:[String: CDMiner] = [:]
        
        public static func ArrayData() ->[CDMiner]{
                return Array(CachedMiner.values)
        }
        
        public static func LoadCache(){
                CachedMiner.removeAll()
                let dbContext = DataShareManager.privateQueueContext()
                guard let minerArr = NSManagedObject.findEntity(HopConstants.DBNAME_MINER,
                                                                context: dbContext) as? [CDMiner] else{
                        return
                }
                
                if minerArr.count == 0{
                        SyncMinerListFromBlockChain()
                        return
                }
                
                for cData in minerArr{
                        CachedMiner[cData.addr!.lowercased()] = cData
                }
                
                PostNoti(HopConstants.NOTI_MINER_CACHE_LOADED)
        }
        
        
        public static func SyncMinerListFromBlockChain(){
                guard let data = SimpleSyncServerList()  else{
                        print("------>>>empty server list")
                        return
                }
                
                let json = JSON(data)
                CachedMiner.removeAll()
                
                let dbContext = DataShareManager.privateQueueContext()
                let request = CDMiner.fetchRequest()
                var dataInDB : [String:CDMiner] = [:]
                if let oldOnes = try? dbContext.fetch(request){
                        for item in oldOnes{
                                dataInDB[item.addr!] = item
                        }
                }
                
                for (_, subJson):(String, JSON) in json {
                        guard let minerAddr = subJson["Addr"].string, let host = subJson["Host"].string else{
                                continue
                        }
                        guard let dbItem = dataInDB[minerAddr] else{
                                let cData = CDMiner.newMiner(addr: minerAddr, host: host)
                                CachedMiner[minerAddr.lowercased()] = cData
                                print("------>>>new server item", cData.addr!, cData.host!)
                                continue
                        }
                        dbItem.host = host
                        CachedMiner[minerAddr.lowercased()] = dbItem
                        dataInDB.removeValue(forKey: minerAddr)
                        print("------>>>update server item", dbItem.addr!, dbItem.host!)
                }
                
                for (_, obj) in dataInDB{
                        dbContext.delete(obj)
                        print("------>>>remove old server item", obj.addr!, obj.host!)
                }
                
                DataShareManager.saveContext(dbContext)
                DataShareManager.syncAllContext(dbContext)
                PostNoti(HopConstants.NOTI_MINER_CACHE_LOADED)
                PostNoti(HopConstants.NOTI_MINER_SYNCED)
        }
        
        public static func prepareMiner(mid:String) throws ->(String, Int32) {
                
                guard let m_data = Miner.CachedMiner[mid.lowercased()] else{
                        throw HopError.minerErr("no such miner details".locStr)
                }
                guard let host = m_data.host else{
                        throw HopError.minerErr("invalid miner detail for host".locStr)
                }
                let port = SimpleMinerPort(mid)
                return (host, port)
        }
}

extension CDMiner{
        public static func newMiner(addr:String, host:String) -> CDMiner {
                
                let dbContext = DataShareManager.privateQueueContext()
                let data = CDMiner(context: dbContext)
                data.ping = -1
                data.host = host
                data.addr = addr
                return data
        }
}
