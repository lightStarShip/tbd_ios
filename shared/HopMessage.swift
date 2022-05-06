//
//  HopMessage.swift
//  Pirate
//
//  Created by hyperorchid on 2020/3/4.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import web3swift
import BigInt

public class HopMessage:NSObject{
        
        enum RCPSynType :Int8{
                case user = 0
                case miner
                case keepAlive
        }
        
        static let RCPSynDataFormat = "{\"Typ\":%d,\"QueryAddr\":\"%@\",\"PoolAddr\":\"%@\"}"
        static let RCPSynFormat = "{\"Sig\":\"%@\",\"Typ\":%d,\"QueryAddr\":\"%@\",\"PoolAddr\":\"%@\"}"
        
        public static func rcpSynMsg(from:String, pool:String, sigKey:Data) ->Data?{
                
                let pool_addr =  pool
                var req =  String(format: RCPSynDataFormat, RCPSynType.user.rawValue, from, pool_addr)
                
                guard let req_data = req.data(using: .utf8) else{
                        return nil
                }
                
                let hash = req_data.sha3(.keccak256)
//                NSLog("--------->hash==>\(hash.toHexString())")
                let (sig, _) = SECP256K1.signForHash(hash: hash, privateKey: sigKey)
                if sig == nil{
                        return nil
                }
                NSLog("--------->sig data==>\(sig!.toHexString())")
                
                req =  String(format: RCPSynFormat,
                              sig!.base64EncodedString(),
                              RCPSynType.user.rawValue, 
                              from,
                              pool_addr)
                NSLog("--------->req==>\(req)")
                return req.data(using: .utf8)
        }
        
        
        public static func rcpKAMsg(from:String) -> Data{
                let req =  String(format: RCPSynFormat, "null", RCPSynType.keepAlive.rawValue, from, EthereumAddress.ZeroAddress)
                return req.data(using: .utf8)!
        }
        
        static let SetupDataFormat = "{\"IV\":%@,\"MainAddr\":\"%@\",\"SubAddr\":\"%@\"}"
        static let SetupSynFormat = "{\"Sig\":\"%@\",\"IV\":%@,\"MainAddr\":\"%@\",\"SubAddr\":\"%@\"}"
        public static func SetupMsg(iv:Data,
                                    mainAddr:String,
                                    subAddr:String,
                                    sigKey:Data)throws -> Data{                
//                var iv = Data.init(repeating: 0, count: 16)
//                iv[0] = 4
                guard let iv_data = try? JSONSerialization.data(withJSONObject: iv.bytes, options: []) else{
                        throw HopError.msg("iv data to json err:")
                }
                
                guard let iv_str = String(data:iv_data, encoding: .utf8) else{
                        throw HopError.msg("iv json data to string failed")
                }
                
                let pool_addr =  mainAddr.lowercased()
                let setup_str =  String(format: SetupDataFormat, iv_str, pool_addr, subAddr)
                let setup_data = setup_str.data(using: .utf8)!
                
//                NSLog("set str==>\(setup_str)")
//                NSLog("set data==>\(setup_data.toHexString())")
                
                let hash = setup_data.sha3(.keccak256)
//                NSLog("--------->hash==>\(hash.toHexString())")
                let (sig, _) = SECP256K1.signForHash(hash: hash, privateKey: sigKey)
                
//                NSLog("sig data==>\(sig!.toHexString())")
//                NSLog("sig 64==>\(sig!.base64EncodedString())")
                
                let syn = String(format: SetupSynFormat, sig!.base64EncodedString(), iv_str, pool_addr, subAddr)
//                NSLog("syn str==>\(syn)")
                
                return syn.data(using: .utf8)!
        }
        
//        static let ProbFormat = "{\"Target\":\"%@\"}"
        static let ProbFormat = "{\"Target\":\"%@\",\"MaxPacketSize\":65535}"
        public static func ProbMsg(target:String) throws -> Data{
                let req =  String(format: ProbFormat, target)
                return req.data(using: .utf8)!
        }
}
