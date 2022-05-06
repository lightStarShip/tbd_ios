//
//  AppSetting.swift
//  Pirate
//
//  Created by wesley on 2020/9/21.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import CoreData
import IosLib

class AppSetting:NSObject{
        
        public static let workQueue = DispatchQueue.init(label: "APP Work Queue", qos: .utility)
        public static var dnsIP:String?
        public static var isGlobalModel:Bool = false
        public static var isStreamModel:Bool = false
        public static var servicePrice:Int64 = 0
        
        static var coreData:CDAppSetting?
        private static var AInst = AppSetting()
        
        public static func initSystem(){
                
                AppSetting.initSetting()
                _ = HopSodium.initialized
//                Utils.initDomains()
                
                AppSetting.workQueue.async {
                        Wallet.WInst.queryBalance()
                }
                AppSetting.workQueue.async {
                        loadServicePrice()
                }
                AppSetting.workQueue.async {
                        Pool.reloadCachedPool()
                        MembershipUI.loadCache()
                }
                AppSetting.workQueue.async {
                        Miner.LoadCache()
                }
        }
        
        public static func loadServicePrice(){
                let price = IosLibServicePrice()
                if price == 0{
                        return
                }
                
                servicePrice = price
                AppSetting.coreData?.servicePrice = price
        }
        
        public static func initSetting(){
                
                IosLibInitSystem(HopConstants.DefaultDnsIP,
                                 HopConstants.DefaultTokenAddr,
                                 HopConstants.DefaultPaymenstService,
                                 HopConstants.DefaultInfruaToken,
                                 AppSetting.AInst)
                
                let context = DataShareManager.privateQueueContext()
                
                let w = NSPredicate(format:"mps == %@", HopConstants.DefaultPaymenstService)
                
                var setting = NSManagedObject.findOneEntity(HopConstants.DBNAME_APPSETTING,
                                                              where: w,
                                                              context: context) as? CDAppSetting
                if setting == nil{
                        setting = CDAppSetting(context: context)
                        setting!.mps = HopConstants.DefaultPaymenstService
                        setting!.dnsIP = HopConstants.DefaultDnsIP
                        setting!.servicePrice = HopConstants.DefaultServicePrice
                        setting!.minerAddrInUsed = nil
                        setting!.poolAddrInUsed = nil
                        setting!.stream = false
                        
                        AppSetting.coreData = setting
                        AppSetting.dnsIP = setting?.dnsIP
                        
                        DataShareManager.saveContext(context)
                        return 
                }
                
                AppSetting.coreData = setting
                AppSetting.dnsIP = setting?.dnsIP ??  HopConstants.DefaultDnsIP
                AppSetting.servicePrice = setting!.servicePrice
                AppSetting.isStreamModel = setting?.stream ?? false
        }
        
        public static func changeDNS(_ dns:String){
                coreData?.dnsIP = dns
                AppSetting.dnsIP = dns
                let context = DataShareManager.privateQueueContext()
                DataShareManager.saveContext(context)
                PostNoti(HopConstants.NOTI_DNS_CHANGED)
        }
        
        public static func changeStreamMode(_ isStream:Bool){
                
                coreData?.stream = isStream
                AppSetting.isStreamModel = isStream
                
                let context = DataShareManager.privateQueueContext()
                DataShareManager.saveContext(context)
                PostNoti(HopConstants.NOTI_DNS_CHANGED)
        }
}

extension AppSetting : IosLibUICallBackProtocol{
        func log(_ str: String?) {
                NSLog("======>[LibLog]\(String(describing: str))")
        }
        
        func notify(_ note: String?, data: String?) {
                PostNoti(Notification.Name(rawValue: note!), data: data)
        }
        
        func sysExit(_ err: Error?) {
        //TODO::
        }
        
        
}
