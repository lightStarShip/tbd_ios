//
//  Protocol.swift
//  extension
//
//  Created by hyperorchid on 2020/3/3.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

@objc public protocol ProtocolDelegate: NSObjectProtocol{
        func VPNShouldDone()
}

public class ApiService:NSObject{ 
        public static var pInst = ApiService()
        public var userSubAddress:String!
        public var minerAddress:String!
        public var minerIP:String!
        public var minerPort:Int!
        
        private var aesKey:Data!
        private var lastMsg:Data!
        var isDebug:Bool = true

        public override init() {
                super.init()
        }
        
        public func setup(param:[String : NSObject]) throws{
                
                let minerID     = param["MINER_ADDR"] as! String
                
                self.isDebug            = param["IS_TEST"] as? Bool ?? true
                self.minerAddress       = minerID
                self.userSubAddress     = (param["USER_SUB_ADDR"] as! String)
                self.minerIP            = (param["MINER_IP"] as! String)
                self.minerPort            = (param["MINER_PORT"] as! Int)
                self.aesKey             = param["AES_KEY"] as? Data
        }
        
        public func P2pKey()->[UInt8]{
                return self.aesKey.bytes
        }
}
let need_debug_packet:Bool = false
public func PacketLog(debug:Bool, _ format: String, _ args: CVarArg...){
        if !debug{
                return
        }
        NSLog(format, args)
}
