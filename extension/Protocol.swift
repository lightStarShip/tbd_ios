//
//  Protocol.swift
//  extension
//
//  Created by hyperorchid on 2020/3/3.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import Curve25519
import CoreData
import SwiftSocket
import web3swift
import SwiftyJSON

@objc public protocol ProtocolDelegate: NSObjectProtocol{
        func VPNShouldDone()
}

public class Protocol:NSObject{ 
        public static var pInst = Protocol()
        public var userAddress:String!
        public var userSubAddress:String!
        public var poolAddress:String!
        public var minerAddress:String!
        public var minerIP:String!
        public var minerPort:Int32!
        private var priKey:HopKey!
        private var aesKey:Data!
        private var lastMsg:Data!
        var vpnDelegate:ProtocolDelegate!
        var isDebug:Bool = true
        
        
        var rcpSocket:UDPClient!
        var rcpTimer:Timer?
        var rcpKAData:Data!
        
        var txSocket:UDPClient?
        let txLock = NSLock()
        var counter:Int = (HopConstants.RechargePieceSize / 2)
        let SendQueue = DispatchQueue.init(label: "Transaction Wire Sending Queue", qos: .utility)
        let ReceiveQueue = DispatchQueue.init(label: "Transaction Wire Receiving Queue", qos: .utility)
        
        
        public override init() {
                super.init()
        }
        
        public func setup(param:[String : NSObject], delegate:ProtocolDelegate) throws{
                
                let main_pri    = param["MAIN_PRI"] as! Data
                let sub_pri     = param["SUB_PRI"] as! Data
                let poolAddrStr = param["POOL_ADDR"] as! String
                let minerID     = param["MINER_ADDR"] as! String
                let userAddr    = param["USER_ADDR"] as! String
                
                self.isDebug            = param["IS_TEST"] as? Bool ?? true
                self.priKey             = HopKey(main: main_pri, sub: sub_pri)
                self.userAddress        = userAddr
                self.poolAddress        = poolAddrStr
                self.minerAddress       = minerID
                self.userSubAddress     = (param["USER_SUB_ADDR"] as! String)
                self.minerIP            = (param["MINER_IP"] as! String)
                self.minerPort            = (param["MINER_PORT"] as! Int32)
                
                self.aesKey             = try self.priKey.genAesKey(forMiner:minerID, subPriKey: sub_pri)
                
                guard MembershipEX.Membership(user: userAddr, pool: poolAddrStr, miner: minerID) else {
                        throw HopError.txWire("Init membership failed[\(userAddr)---->\(poolAddrStr)]")
                }
                
                self.txSocket = UDPClient(address: self.minerIP, port: self.minerPort)
                self.reading()
                if Int(MembershipEX.minerCredit.inCharge) > HopConstants.RechargePieceSize{
                        NSLog("--------->Need to recharge because of last failure:\(MembershipEX.minerCredit.inCharge)")
                        self.recharge(amount: 0)
                }
        }
}

//MARK: - TX functions
extension Protocol{
        
        public func AesKey()->[UInt8]{
                return self.aesKey.bytes
        }
        public func signKey()->Data{
                return self.priKey.mainPriKey!
        }
        
        private func reading(){
                
                let credit = MembershipEX.minerCredit!
                let member = MembershipEX.membership!
                
                self.ReceiveQueue.async {while true{
                        do {
                        guard let (response, _, _) = self.txSocket?.recv(1024), let resData = response else{
                                throw HopError.rcpWire("Read micro tx failed`")
                        }
                        
                        let rcp = ReceiptData(json: JSON(Data(resData)))
                        guard let tx = rcp.tx else{
                                throw HopError.rcpWire("No valid transaction data")
                        }
                        NSLog("--------->create rcp\n\(rcp.toString())")
                        
                        NSLog("--------->********>User account before update\n\(member.toString())\(credit.toString())")
                        defer {
                                NSLog("--------->++++++++>User account after update\n\(member.toString())\(credit.toString())")
                                MembershipEX.syncData()
                        }
                        
                        guard tx.verifyTx(credit: credit, member: member) == true else{
                                throw HopError.rcpWire("Signature verify failed for receipt")
                        }
                        
                        credit.update(tx: tx)
                        member.update(tx: tx)
                        self.lastMsg = nil
                                
                        }catch let err{
                                NSLog("--------->Transaction Wire read err:=>\(err.localizedDescription)")
                                self.txSocket = UDPClient(address: self.minerIP, port: self.minerPort)
                        }
                }
                }
        }
        
        private func recharge(amount:Int64){
                
                let credit = MembershipEX.minerCredit!
                let member = MembershipEX.membership!
                
                self.SendQueue.async { do {
                        
                        credit.inCharge += amount
                        MembershipEX.syncData()
                        NSLog("--------->Transaction Wire need to recharge:[\(credit.inCharge)]===>")
                        
                        if self.lastMsg == nil{
                                let tx_data = TransactionData.initForRechargge(member: member,
                                                              credit: credit,
                                                              amount: Int64(credit.inCharge))
                                
                                guard let d = tx_data.createTxData(sigKey: self.priKey.mainPriKey!) else{
                                        throw HopError.txWire("Create transaction data failed")
                                }
                                self.lastMsg = d
                        }else{
                                NSLog("--------->Need resend last tx data......")
                        }
                        
                        let ret = self.txSocket?.send(data: self.lastMsg)
                        guard ret?.isSuccess == true else{
                                throw HopError.txWire("Transaction Wire send failed==\(ret?.error?.localizedDescription ?? "<-empty error->")==>")
                        }
                        NSLog("--------->Send tx success......")
                        
                        }catch let err{
                                NSLog("--------->Transaction Wire write err:=>\(err.localizedDescription)")
                                self.txSocket = UDPClient(address: self.minerIP, port: self.minerPort)
                        }
                }
        }
        
        public func CounterWork(size:Int){
                
                if txLock.try(){
                        defer {txLock.unlock()}
                        self.counter += size
                        if self.counter < HopConstants.RechargePieceSize{
                                return
                        }
                        self.recharge(amount: Int64(self.counter))
                        self.counter = 0
                }
        }
}
