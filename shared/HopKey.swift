//
//  HopKey.swift
//  Pirate
//
//  Created by hyperorchid on 2020/10/5.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import Curve25519

public class HopKey:NSObject{
        var subPriKey: Data?
        var mainPriKey:Data?
        
        public init(main:Data, sub:Data){
                mainPriKey = main
                subPriKey = sub
        }
        
        public func genAesKey(forMiner:String, subPriKey:Data)throws ->Data{
                
                guard let miner_ed_pub = BasUtil.getPub(address: forMiner) else{
                        throw HopError.minerErr("Parse account's id to ed25519 public key failed".locStr)
                }
                
                let miner_pub = try HopSodium.PK25519ED2Curve(edPub: miner_ed_pub)
                let cur_pri = try HopSodium.SK25519ED2Curve(edPri: subPriKey)
                guard let s_key = Curve25519.SharedSecret(privateKey: cur_pri, peerPublicKey: miner_pub) else{
                        throw HopError.minerErr("Create shared aes key with node failed".locStr)
                }
                
                return s_key
        }
}
