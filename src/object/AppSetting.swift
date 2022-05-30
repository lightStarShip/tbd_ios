//
//  AppSetting.swift
//  Pirate
//
//  Created by wesley on 2020/9/21.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import CoreData
import Starship

class AppSetting:NSObject{
        
        public static let workQueue = DispatchQueue.init(label: "APP Work Queue", qos: .utility)
        public static var isGlobalModel:Bool = false
        public static var isStreamModel:Bool = true
        public static let AdUpdateInterval = TimeInterval(24*3600)
        
        static var coreData:CDAppSetting?
        private static var AInst = AppSetting()
        
        public static func initSystem(){
                
                AppSetting.initSetting()
                
                AppSetting.workQueue.async {
                        Miner.LoadCache()
                }
        }
        
        
        public static func initSetting(){
                
                IosLibInitSystem(AppSetting.AInst)
                
                let context = DataShareManager.privateQueueContext()
                
                var setting = NSManagedObject.findOneEntity(HopConstants.DBNAME_APPSETTING,
                                                            context: context) as? CDAppSetting
                if setting == nil{
                        setting = CDAppSetting(context: context)
                        setting!.minerAddrInUsed = nil
                        setting!.stream = true
                        
                        AppSetting.coreData = setting
                        
                        DataShareManager.saveContext(context)
                        return
                }
                
                AppSetting.coreData = setting
                AppSetting.isStreamModel = setting?.stream ?? false
        }
        
        
        public static func changeStreamMode(_ isStream:Bool){
                
                coreData?.stream = isStream
                AppSetting.isStreamModel = isStream
                
                let context = DataShareManager.privateQueueContext()
                DataShareManager.saveContext(context)
        }
        
        public static func updateAdData(data:Data){
                
                AppSetting.coreData?.adListData = data
                AppSetting.coreData?.adUpdateTime = Date()
                
                let context = DataShareManager.privateQueueContext()
                DataShareManager.saveContext(context)
        }
        
        public static func getAdData()->Data?{
                guard let data = AppSetting.coreData?.adListData else{
                        return nil
                }
                
                guard let up_time = AppSetting.coreData?.adUpdateTime else{
                        return nil
                }
                
                let interval = Date().timeIntervalSince(up_time)
                if interval > AdUpdateInterval{
                        return nil
                }
                
                return data
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
        
        static func save(password: String, service: String, account: String) ->Bool {
                
                let pData = password.data(using: .utf8)
                let query: [String: AnyObject] = [
                        // kSecAttrService,  kSecAttrAccount, and kSecClass
                        // uniquely identify the item to save in Keychain
                        kSecAttrService as String: service as AnyObject,
                        kSecAttrAccount as String: account as AnyObject,
                        kSecClass as String: kSecClassGenericPassword,
                        
                        // kSecValueData is the item value to save
                        kSecValueData as String: pData as AnyObject
                ]
                
                // SecItemAdd attempts to add the item identified by
                // the query to keychain
                let status = SecItemAdd(
                        query as CFDictionary,
                        nil
                )
                
                
                // Any status other than errSecSuccess indicates the
                // save operation failed.
                guard status == errSecSuccess else {
                        print("------>>> oss save failed :=>", status)
                        return false
                }
                return true
        }
        
        static func readPassword(service: String, account: String) -> String? {
                let query: [String: AnyObject] = [
                        // kSecAttrService,  kSecAttrAccount, and kSecClass
                        // uniquely identify the item to read in Keychain
                        kSecAttrService as String: service as AnyObject,
                        kSecAttrAccount as String: account as AnyObject,
                        kSecClass as String: kSecClassGenericPassword,
                        
                        // kSecMatchLimitOne indicates keychain should read
                        // only the most recent item matching this query
                        kSecMatchLimit as String: kSecMatchLimitOne,
                        
                        // kSecReturnData is set to kCFBooleanTrue in order
                        // to retrieve the data for the item
                        kSecReturnData as String: kCFBooleanTrue
                ]
                
                // SecItemCopyMatching will attempt to copy the item
                // identified by query to the reference itemCopy
                var itemCopy: AnyObject?
                let status = SecItemCopyMatching(
                        query as CFDictionary,
                        &itemCopy
                )
                
                // errSecItemNotFound is a special status indicating the
                // read item does not exist. Throw itemNotFound so the
                // client can determine whether or not to handle
                // this case
                guard status != errSecItemNotFound else {
                        print("------>>> oss read failed :=>", status)
                        return nil
                }
                
                guard status == errSecSuccess else {
                        print("------>>> oss read failed :=>", status)
                       return nil
                }
                
                // This implementation of KeychainInterface requires all
                // items to be saved and read as Data. Otherwise,
                // invalidItemFormat is thrown
                guard let password = itemCopy as? Data else {
                        print("------>>> oss read failed :=>", itemCopy as Any)
                        return nil
                }
                return String(data: password, encoding: .utf8)
        }
}
