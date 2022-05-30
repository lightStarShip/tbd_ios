//
//  HopConstants.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/25.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
public struct ScryptParam {
        var dkLen:Int
        var N:Int
        var R:Int
        var P:Int
        var S:Int
}

public struct HopConstants {
        static public let EthScanUrl = "https://etherscan.io/tx/"
        
        static public let SALT_LEN = 16
        static public let DBNAME_WALLET = "CDWallet"
        static public let DBNAME_APPSETTING = "CDAppSetting"
        static public let DBNAME_MINER = "CDMiner"
        static public let SERVICE_NME_FOR_OSS = "com.hop.simple"
        
        
        static let NOTI_MINER_CACHE_LOADED = Notification.init(name: Notification.Name("NOTI_MINER_CACHE_LOADED"))
        static let NOTI_MINER_SYNCED = Notification.init(name: Notification.Name("NOTI_MINER_SYNCED"))
        static let NOTI_MINER_INUSE_CHANGED = Notification.init(name: Notification.Name("NOTI_MINER_INUSE_CHANGED"))
        

}
