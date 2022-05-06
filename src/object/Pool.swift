//
//  PoolEntity.swift
//  Pirate
//
//  Created by wesley on 2020/9/27.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import CoreData
import IosLib
import SwiftyJSON

class Pool : NSObject {
        
        var Name:String?
        var Address:String!
        var Url:String?
        var Email:String?
    
        var lastDayUsed:Double?
        var lastMonUsed:Double?
        var totalUsed:Double?
        var totalRechage:Int64?
    
        var coreData:CDPool?
            
        public static var CachedPool:[String: Pool] = [:]
        
        override init() {
                super.init()
        }
        
        public static func reloadCachedPool()  {
                
                let dbContext = DataShareManager.privateQueueContext()
                let w = NSPredicate(format: "mps == %@", HopConstants.DefaultPaymenstService)
                let order = [NSSortDescriptor.init(key: "address", ascending: false)]
                
                guard let poolArr = NSManagedObject.findEntity(HopConstants.DBNAME_POOL,
                                                             where: w,
                                                             orderBy: order,
                                                             context: dbContext) as? [CDPool] else{
                        return
                }
                
                CachedPool.removeAll()
                if poolArr.count == 0{
                        syncPoolFromETH()
                        return
                }
                
                for cData in poolArr{
                        let obj = Pool(coredata:cData)
                        CachedPool[obj.Address.lowercased()] = obj
                }
                
                PostNoti(HopConstants.NOTI_POOL_CACHE_LOADED)
        }
        
        public init(coredata:CDPool){
                
                self.Address = coredata.address
                self.Name = coredata.name
                self.Url = coredata.url
                self.Email = coredata.email
            
                self.lastDayUsed = coredata.lastday
                self.lastMonUsed = coredata.lastmonth
                self.totalUsed = coredata.totaluse
                self.totalRechage = coredata.totalcharge
            
                self.coreData = coredata
        }
        
        public init(json:JSON){
                
                self.Address = json["MainAddr"].string
                self.Name = json["Name"].string
                self.Email = json["Email"].string
                self.Url = json["Url"].string
            
                self.lastDayUsed = json["pool_stat"]["last_day_used_m_bytes"].double
                self.lastMonUsed = json["pool_stat"]["last_month_used_g_bytes"].double
                self.totalUsed = json["pool_stat"]["total_used_g_bytes"].double
                self.totalRechage = json["pool_stat"]["total_charged_user_cnt"].int64
        }
    
    
        
        public static func syncPoolFromETH(){
                
//                CachedPool.removeAll()
                guard let data = IosLibPoolInMarket() else {
                        return
                }
                
                let json = JSON(data)
                let dbContext = DataShareManager.privateQueueContext()
                
                let w = NSPredicate(format: "mps == %@", HopConstants.DefaultPaymenstService)
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: HopConstants.DBNAME_POOL)
                request.predicate = w
                if let result = try? dbContext.fetch(request){
                        
                    for (_, subJson):(String, JSON) in json {
                        let obj = Pool(json: subJson)
                        let cData = CDPool(context: dbContext)
                        
                        for oldData in result {
                            let oldJsonData = JSON(oldData)
                            let oldObj = Pool(json: oldJsonData)
                            if oldJsonData["MainAddr"].string == subJson["MainAddr"].string {
                                dbContext.delete(oldData as! NSManagedObject)
                                CachedPool.removeValue(forKey: oldObj.Address.lowercased())
                            }
                        }
                        
                        cData.populate(obj)
                        obj.coreData = cData
                        
                        CachedPool[obj.Address.lowercased()] = obj
                            
                    }
                    
                }
                
//                for (_, subJson):(String, JSON) in json {
//
//                        let obj = Pool(json: subJson)
//                        let cData = CDPool(context: dbContext)
//                        cData.populate(obj)
//                        obj.coreData = cData
//
//                        CachedPool[obj.Address.lowercased()] = obj
//                }
                DataShareManager.saveContext(dbContext)
                PostNoti(HopConstants.NOTI_POOL_CACHE_LOADED)
        }
        
        public static func ArrayData() ->[Pool]{
            var vals = Array(CachedPool.values)
            
            vals.sort( by: { (vl1: Pool, vl2: Pool) -> Bool in
                return (vl1.totalUsed ?? 0.0) > (vl2.totalUsed ?? 0.0) ? true : false
            })
            
                return vals
        }
}

extension CDPool {
        
        func populate(_ obj: Pool){
                self.address = obj.Address
                self.name = obj.Name
                self.email = obj.Email
                self.url = obj.Url
                
                self.lastday = obj.lastDayUsed ?? 0.0
                self.lastmonth = obj.lastMonUsed ?? 0.0
                self.totaluse = obj.totalUsed ?? 0.0
                self.totalcharge = obj.totalRechage ?? 0
                self.mps = HopConstants.DefaultPaymenstService
        }
}
