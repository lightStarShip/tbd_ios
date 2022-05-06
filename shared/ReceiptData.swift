//
//  ReceiptData.swift
//  Pirate
//
//  Created by hyperorchid on 2020/3/9.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import BigInt
import web3swift
import SwiftyJSON
import CoreData



public class TransactionData:NSObject{
        
        public static let txInputType:[ABI.Element.ParameterType] = [.address, .address,
                                                               .address, .address,
                                                               .uint(bits: 256), .uint(bits: 256), .uint(bits: 256)]
        
        public static let abiSignType:[ABI.Element.ParameterType] = [.string, .bytes(length: 32)]
        
        public static let abiPrefix = "\u{19}Ethereum Signed Message:\n32"
        
        var usedTraffic:Int64?
        var time:Int64?
        var minerID:String?
        var minerAmount:Int64?
        var minerCredit:Int64?
        var contractAddr : String?
        var tokenAddr : String?
        var user:String?
        var pool:String?
        var txSig:String?
        var hashV:String?
        
        public override init(){
                super.init()
        }
        
        static public func initByReceipt(json:JSON) -> TransactionData{
                
                let data = TransactionData()
                
                data.txSig = json["signature"].string
                data.hashV = json["hash"].string
                data.time = json["time"].int64
                data.minerID = json["minerID"].string
                data.user = json["user"].string
                data.pool = json["pool"].string
                data.minerAmount = json["miner_amount"].int64
                data.minerCredit = json["miner_credit"].int64
                data.contractAddr = json["author"]["contract"].string
                data.tokenAddr = json["author"]["token"].string
                data.usedTraffic = json["used_traffic"].int64
                
                return data
        }
        
        public func toString()->String{
                return "Transaction=>{\ntxsig=\(txSig ?? "<->")\nhashV=\(hashV ?? "<->")\ntime=\(time!)\nminerID=\(minerID!)\nfrom=\(user!) \nto=\(pool!)\nminerAmount=\(minerAmount!)\nminerCredit=\(minerCredit!)\nself.usedTraffic=\(self.usedTraffic!)}\n"
        }
        
        static public func initForRechargge(member:CDMemberShip, credit:CDMinerCredit, amount:Int64) -> TransactionData{
                
                let data = TransactionData()
                
                data.usedTraffic = member.usedTraffic + amount
                data.time = Int64(Date().timeIntervalSince1970 * 1000)
                data.minerID = credit.minerID
                data.minerAmount = amount
                data.minerCredit = credit.credit + amount
                data.user = EthereumAddress.toChecksumAddress(member.userAddr!)
                data.pool = EthereumAddress.toChecksumAddress(member.poolAddr!)
                
                return data
        }
        
        func createABIHash() -> Data?{
                
                let parameters:[AnyObject] = [HopConstants.DefaultPaymenstService as AnyObject,
                                              HopConstants.DefaultTokenAddr as AnyObject,
                                        self.user! as AnyObject,
                                        self.pool! as AnyObject,
                                        self.minerCredit as AnyObject,
                                        self.minerAmount as AnyObject,
                                        self.usedTraffic as AnyObject]
                
                let tx_encode = ABIEncoder.encode(types:TransactionData.txInputType, values: parameters)
//                NSLog("--------->tx_encode===>\(tx_encode?.toHexString())")
                let tx_hash = tx_encode!.sha3(.keccak256)
                let pre_parameters:[AnyObject] = [TransactionData.abiPrefix as AnyObject, tx_hash as AnyObject]
                
                let pre_encode = ABIEncoder.encode(types:TransactionData.abiSignType, values: pre_parameters)
                return  pre_encode?.sha3(.keccak256)
        }
        /*
         {"typ":0,"tx":{"signature":"wcOjDhMc2nthSa3jTHzO/nsxqsv9d3ESo8cYTFvlmg8177fNqJk6ION/hCMXb5Qp+wqlfiM6m8PD1qjStnE/7AA=","hash":"8HGDVD9Q8fz2iqs8/pBWv6EjECbrjeNgeyDeNIuDe7Q=","used_traffic":1000,"time":1608808536718,"minerID":"HOGpBCzYGgzuSsJGuMDMpVsp24gPVScuiziZswwWLJ8fN1","user":"0xc3df37433b0aaa18e120dbff932cc3e64db79336","pool":"0xc3df37433b0aaa18e120dbff932cc3e64db79336","miner_amount":4,"miner_credit":12,"author":{"contract":"0xc3df37433b0aaa18e120dbff932cc3e64db79336","token":"0xc3df37433b0aaa18e120dbff932cc3e64db79336"}}}
         */
        
        public static let TxFormat = "{\"typ\":0,\"tx\":{\"signature\":\"%@\",\"hash\":\"%@\",\"used_traffic\":%d,\"time\":\"%@\",\"minerID\":\"%@\",\"user\":\"%@\",\"pool\":\"%@\",\"miner_amount\":%d,\"miner_credit\":%d,\"author\":{\"contract\":\"%@\",\"token\":\"%@\"}}}"
        
        func createTxData(sigKey:Data) -> Data?{
                guard let hash_data = self.createABIHash() else {
                        return nil
                }
                
                let (signVal, _) = SECP256K1.signForHash(hash: hash_data, privateKey: sigKey)
                guard let d = signVal else{
                        return nil
                }
                self.txSig = d.base64EncodedString()
                self.hashV = hash_data.base64EncodedString()
                
                let tx_str = "{\"typ\":0,\"tx\":{\"signature\":\"\(self.txSig!)\",\"hash\":\"\(self.hashV!)\",\"used_traffic\":\(self.usedTraffic!),\"time\":\(self.time!),\"minerID\":\"\(self.minerID!)\",\"user\":\"\(self.user!)\",\"pool\":\"\(self.pool!)\",\"miner_amount\":\(self.minerAmount!),\"miner_credit\":\(self.minerCredit!),\"author\":{\"contract\":\"\(HopConstants.DefaultPaymenstService)\",\"token\":\"\(HopConstants.DefaultTokenAddr)\"}}}"

                NSLog("--------->Create transaction:\(tx_str)")
                return tx_str.data(using: .utf8)
        }
        
        //TODO::need verify signature
        public func verifyTx(credit:CDMinerCredit, member:CDMemberShip) -> Bool{
                guard self.tokenAddr?.lowercased() == HopConstants.DefaultTokenAddr.lowercased(),
                      self.contractAddr?.lowercased() == HopConstants.DefaultPaymenstService.lowercased() else {
                        NSLog("--------->verifyTx mps or token wrong")
                        return false
                }
                
                guard credit.userAddr?.lowercased() == self.user?.lowercased(),
                      credit.minerID?.lowercased() == self.minerID?.lowercased() else {
                        NSLog("--------->Pool and user are not for me!")
                        return false
                }
                
                if credit.credit > self.minerCredit!{
                        NSLog("--------->credit invalid [\(credit.credit) ===> [\(self.minerCredit!)]")
                        return false
                }
                if member.usedTraffic >= self.usedTraffic!{
                        NSLog("--------->old receipt [\(member.usedTraffic)] ===> [\(self.usedTraffic!)]")
                        return false
                }
                
                
//                guard let hash_data = self.createABIHash() else {
//                        NSLog("--------->verifyTx createABIHash failed")
//                        return false
//                }
//
//                guard let signature = Data.init(base64Encoded: self.txSig!) else{
//                        NSLog("--------->verifyTx signature base64Encoded failed")
//                        return false
//                }
//
//                guard let recovered = Web3.Utils.hashECRecover(hash: hash_data, signature: signature) else {
//                        NSLog("--------->verifyTx recovered failed")
//                        return false
//                }
//                guard let userAddr = EthereumAddress(self.user!) else{
//                        NSLog("--------->verifyTx userAddr invalid")
//                        return false
//                }
//                NSLog("--------->recoverd=\(recovered) userAddr=\(userAddr)")
//                return recovered == userAddr
                
                return true
        }
}

public class ReceiptData:NSObject{
        var success:Bool = false
        var sig:String?
        var tx:TransactionData?
        
        public override init() {
                super.init()
        }
        
        public init(json:JSON){
                let code = json["code"].int
                if code != 0{
                        success = false
                        return
                }
                
                let minderTX = json["data"]
                self.sig = minderTX["MinerSig"].string
                self.tx = TransactionData.initByReceipt(json: minderTX)
        }
        
        public func toString()->String{
                return "\n ReceiptData=>{\n sig=\(self.sig ?? "<->") \n\(self.tx!.toString())\n}"
        }
}
