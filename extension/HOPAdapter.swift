//
//  HOPAdapter.swift
//  extension
//
//  Created by hyperorchid on 2020/2/19.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit
import NEKit
import CryptoSwift
import SwiftyJSON

class HOPAdapter: AdapterSocket {
        
        public static let MAX_BUFFER_SIZE = Opt.MAXNWTCPSocketReadDataSize - 1
        public static let PACK_HEAD_SIZE = 4
        
        enum HopAdapterStatus {
                case invalid,
                connecting,
                readingSetupACKLen,
                readingSetupACK,
                readingProbACKLen,
                readingProbACK,
                forwarding,
                stopped
                public var description: String {
                        switch self {
                        case .invalid:
                                return "invalid"
                        case .connecting:
                                return "connecting"
                        case .readingSetupACKLen:
                                return "readingSetupACKLen"
                        case .readingSetupACK:
                                return "readingSetupACK"
                        case .forwarding:
                                return "forwarding"
                        case .stopped:
                                return "stopped"
                        case .readingProbACKLen:
                                return "readingProbACKLen"
                        case .readingProbACK:
                                return "readingProbACK"
                        }
                }
        }
        
        enum ReadingStatus {
                case needLengthInHead, readingLength, readingContent
        }
        
        var readingStatus:ReadingStatus = .needLengthInHead
        public let serverHost: String
        public let serverPort: Int
        var internalStatus: HopAdapterStatus = .invalid
        var target:String?
        var salt:Data?
        var aesKey:AES?
        var objID:Int
        
        public init(serverHost: String,
                    serverPort: Int,
                    ID:Int) {
                self.serverHost = serverHost
                self.serverPort = serverPort
                self.objID = ID
                super.init()
                
//                NSLog("--------->[\(ID)]New addapter:[\(serverHost):\(serverPort)]")
        }
        
        override public func openSocketWith(session: ConnectSession) {
                super.openSocketWith(session: session)
                guard !isCancelled else {
                        return
                }
                
                self.target = "\(session.host):\(session.port)"
  
                internalStatus = .connecting
                do {
                        self.salt = Data.randomBytes(length: HopConstants.HOP_WALLET_IVLEN)!
                        let key = Protocol.pInst.AesKey()
                        self.aesKey = try AES(key: key,
                                              blockMode: CFB(iv: self.salt!.bytes),
                                              padding:.noPadding)
                        
                        try socket.connectTo(host: self.serverHost,
                                             port: Int(self.serverPort),
                                             enableTLS: false,
                                             tlsSettings: nil)
                } catch let err{
                        NSLog("--------->open socket err[\(err.localizedDescription)]")
                        disconnect()
                }
                
//                NSLog("--------->[\(objID)]open target:[\(self.target!)] success")
        }
        
        override public func didConnectWith(socket: RawTCPSocketProtocol) {
                let setup_Data = try? HopMessage.SetupMsg(iv:self.salt!,
                                        mainAddr: Protocol.pInst.userAddress,
                                        subAddr: Protocol.pInst.userSubAddress,
                                        sigKey: Protocol.pInst.signKey())
                
                guard let syn_data = setup_Data else{
//                        observer?.signal(.errorOccured(HopError.msg("invalid setup message to miner"), on: self))
                        disconnect()
                        return
                }
                
                internalStatus = .readingSetupACKLen
                let lv_data = DataWithLen(data: syn_data)
                write(data: lv_data)
                self.socket.readDataTo(length: HOPAdapter.PACK_HEAD_SIZE)
//                NSLog("--------->[\(objID)]didConnectWith[\(lv_data.count)] status:[\(internalStatus.description)]")
        }

        override public func didRead(data: Data, from rawSocket: RawTCPSocketProtocol) {
//                NSLog("--------->[\(objID)]didRead=len=\(data.count) status:[\(internalStatus.description)] ---")
                
                do {
                switch internalStatus {
                case .readingSetupACKLen, .readingProbACKLen :
                        guard data.count == HOPAdapter.PACK_HEAD_SIZE else {
                                 NSLog("--------->[\(objID)]didRead data.count [\(data.count)]---")
                                throw HopError.minerErr("miner setup lent protocol failed")
                        }
                        
                        let len = data.ToInt()
                        if len > HOPAdapter.MAX_BUFFER_SIZE{
                                NSLog("--------->[\(objID)]didRead too big data len[\(len)]---")
                                throw HopError.minerErr("--------->didRead[\(objID)]too big data len[\(len)]")
                        }
                        
                        if internalStatus == .readingSetupACKLen{
                                internalStatus = .readingSetupACK
                        }else{
                                internalStatus = .readingProbACK
                        }
                        self.socket.readDataTo(length: len)
//                        NSLog("--------->[\(objID)]need read data len is[\(len)] status:[\(internalStatus.description)] ---")
                        
                case .readingSetupACK:

//                        NSLog("--------->[\(objID)] readingSetupACK[\(data.count)] msg:[\(String(data:data, encoding: .utf8) ?? "-")] ---")
                        let obj = JSON(data)
                        guard obj["Success"].bool == true else{
                                NSLog("--------->didRead[\(objID)]miner setup protocol failed]")
                                throw HopError.minerErr("miner setup protocol failed")
                        }
                        
                        internalStatus = .readingProbACKLen
                        let prob_data = try HopMessage.ProbMsg(target: self.target!)
                        write(data: prob_data)
                        self.socket.readDataTo(length: HOPAdapter.PACK_HEAD_SIZE)
                        
                case .readingProbACK:
                        let decoded_data = try self.readEncoded(data:data)
//                        NSLog("--------->[\(objID)]readingProbACK msg[\(decoded_data.count)]:[\(String(data:decoded_data, encoding: .utf8) ?? "-")] ---")
                        let obj = JSON(decoded_data)
                        guard obj["Success"].bool == true else{
                                NSLog("--------->didRead[\(objID)]miner readingProbACK failed]")
                                throw HopError.minerErr("miner readingProbACK failed")
                        }
                        
                        internalStatus = .forwarding
//                        observer?.signal(.readyForForward(self))
                        delegate?.didBecomeReadyToForwardWith(socket: self)
                        
                case .forwarding:
                        if self.readingStatus == .readingLength{
                                try readLen(data: data)
                                return
                        }
                       
                        let decode_data = try self.readEncoded(data: data)
//                        observer?.signal(.readData(decode_data, on: self))
                        let size = decode_data.count
                        
                        NSLog("--------->[\(objID)]YYYYYY did read len [\(size)]---")
                        Protocol.pInst.CounterWork(size:size)
                        delegate?.didRead(data: decode_data, from: self)
                        self.readingStatus = .needLengthInHead
                default:
                    return
                }
                }catch let err{
                        disconnect()
                        NSLog("--------->[\(objID)] ZZZZZ didRead err:\(err.localizedDescription)")
                }
        }

        override public func didWrite(data: Data?, by rawSocket: RawTCPSocketProtocol) {
//                NSLog("--------->[\(objID)]didWrite status:[\(internalStatus.description)] len=\(data?.count ?? 0)---")
                
                if internalStatus == .forwarding {
//                        NSLog("--------->[\(objID)] didWrite should signal[\(data?.count ?? 0)]")
                        delegate?.didWrite(data: data, by: self)
                }
        }
        
        func hopWrite(data:Data){do{
//                NSLog("--------->[\(objID)]hopWrite before msg:[\(String(data:data, encoding: .utf8) ?? "-")] ---")
//                NSLog("--------->[\(objID)]hopWrite[\(data.count)] before msg:[\(data.toHexString())] ---")
                let encode_data = try self.aesKey!.encrypt(data.bytes)
                let lv_data = DataWithLen(data: Data(encode_data))
                self.socket.write(data: lv_data)
                
//                NSLog("--------->[\(objID)]hopWrite[\(lv_data.count)] after msg:[\(lv_data.toHexString())] ---")
                }catch{
                        disconnect()
                }
        }
        override open func readData() {
                if internalStatus == .forwarding{
                        if self.readingStatus == .needLengthInHead{
                                NSLog("--------->[\(objID)] AAAAA readData --reading data length from head......-")
                                self.socket.readDataTo(length: HOPAdapter.PACK_HEAD_SIZE)
                                self.readingStatus = .readingLength
                        }
                        return
                }
                
//                NSLog("--------->[\(objID)]readData --controller data-")
                super.readData()
        }
        override open func write(data: Data) {
                if internalStatus == .readingProbACKLen || internalStatus == .forwarding{
                        self.hopWrite(data: data)
                        return
                }
                
//                NSLog("--------->[\(objID)]direct write msg:[\(data.count)] ---")
                super.write(data: data)
        }
        
        
        func readLen(data:Data)throws{
                guard data.count == HOPAdapter.PACK_HEAD_SIZE else{
                        throw HopError.minerErr("[\(objID)]【readLen】size header should not be[\(data.count)]")
                }
                
                let len = data.ToInt()
                self.readingStatus = .readingContent
                self.socket.readDataTo(length: len)
                NSLog("--------->[\(objID)]XXXXXX need to read len [\(len)]---")
        }
        
        func readEncoded(data:Data) throws-> Data {
//                NSLog("--------->[\(objID)] read crypt data-> before:[\(data.toHexString())] ---")
                guard let decode_data = try self.aesKey?.decrypt(data.bytes) else{
                        throw HopError.minerErr("[\(objID)]【readEncoded】miner undecrypt data")
                }
//                NSLog("--------->[\(objID)]read decrypt data-> after:[\(decode_data.toHexString())] ---")
                return Data(decode_data)
        }
}
