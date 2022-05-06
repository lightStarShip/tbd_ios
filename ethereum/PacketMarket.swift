//
//  PacketMarket.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/25.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import web3swift
import BigInt

public class PacketMarket:NSObject{
        
        var web3:web3
        var address:EthereumAddress
        var contract:web3.web3contract
        public static let AbiVersion = 2
        
        public init(web3 w:web3, address addr:EthereumAddress) throws{
                web3 = w
                address = addr
                guard let filePath = Bundle.main.url(forResource: "PacketMarket", withExtension: "abi") else{
                        throw HopError.eth("invalid abi file for PacketMarket")
                }
                let abi_str = try String.init(contentsOf: filePath)
                

                guard let c = web3.contract(abi_str, at: address, abiVersion: PacketMarket.AbiVersion) else {
                        throw HopError.eth("create contract[PacketMarket] from abi failed")
                }
                self.contract = c
        }
        
        public func Pools() -> [EthereumAddress]{
                do{
                        let pools = try viewRead(method: "Pools")
                        guard let arr = pools["0"] as? [EthereumAddress] else{
                                return []
                        }
                        return arr
                        
                }catch let err{
                        NSLog("=======>\(err.localizedDescription)")
                        return []
                }
        }
        
        public func AllMyPoolsAddress(userAddr addr:EthereumAddress) -> [EthereumAddress]{
                do{
                        let pools = try viewRead(method: "AllMyPools", addr as AnyObject)
                        guard let arr = pools["0"] as? [EthereumAddress] else{
                                return []
                        }
                        return arr
                }catch let err{
                        NSLog("=======>\(err.localizedDescription)")
                        return []
                }
        }
        
        private func viewRead(method:String, _ params:AnyObject...) throws -> [String : Any]{
                
                let contract = self.contract
                var transactionOptions = TransactionOptions()
                transactionOptions.callOnBlock = .latest
                return try contract.read(method,
                                      parameters: params,
                                      extraData: Data(),
                                      transactionOptions: TransactionOptions.defaultOptions
               )!.call(transactionOptions: transactionOptions)
        }
        
        public func Balance(userAddr:EthereumAddress) -> (BigUInt, BigUInt){
                do{
                        let ret = try viewRead(method: "TokenBalance", userAddr as AnyObject)
                        guard let tokenB = ret["0"] as? BigUInt,
                                let ethB = ret["1"] as? BigUInt else{
                                return (0, 0)
                        }
                        return (tokenB, ethB)
                }catch let err{
                        NSLog("=======>\(err.localizedDescription)")
                        return  (0, 0)
                }
        }
        
        public func  BuyPacket(user:EthereumAddress,
                               pool:EthereumAddress,
                               tokenNo:BigUInt,
                               priKey:Data)throws -> web3swift.TransactionSendingResult{
                
                let contract = self.contract
                var basicOptions = TransactionOptions()
                basicOptions.from = user
                basicOptions.to = self.address
                basicOptions.callOnBlock = .latest
                
                let tx = contract.write("BuyPacket",
                                        parameters: [user, tokenNo, pool] as [AnyObject],
                                        transactionOptions: basicOptions)!
                return try tx.send(priKey: priKey)
        }
        
        public func MinerNo(ofPool:EthereumAddress)->BigUInt{
                do{
                        let ret = try viewRead(method: "MinerNoOfPool", ofPool as AnyObject)
                        
                        guard let size = ret["0"] as? BigUInt else{
                                return 0
                        }
                        return size
                        
                }catch let err{
                        NSLog(err.localizedDescription)
                        return 0
                }
        }
        
        public func PartOfMiners(inPool:EthereumAddress, start:BigUInt, end:BigUInt)->[Data]{
                
                do{
                        let ret = try viewRead(method: "PartOfMiners",
                                                inPool as AnyObject,
                                                start as AnyObject,
                                                end as AnyObject)
                        
                        guard let arr = ret["0"] as? [Data] else{
                                return []
                        }
                        
                        return arr
                }catch let err{
                        NSLog(err.localizedDescription)
                        return []
                }
        }
}
