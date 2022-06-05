//
//  SocksV5RemoteSocket.swift
//  vpn
//
//  Created by wesley on 2022/6/4.
//  Copyright © 2022 hyperorchid. All rights reserved.
//

import Foundation
import NetworkExtension
import CryptoSwift
import SwiftyJSON


public class SocksV5RemoteSocket:NSObject{
        
        enum AdapterStatus {
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
        
        
        private var connection: NWTCPConnection!
        private var status:AdapterStatus = .invalid
        private var delegate:SocksV5PipeDelegate
        private var sid:Int
        private var target:String?
        private var salt:Data?
        private var aesKey:AES?
        
        public init(sid :Int, target:String, delegate d: SocksV5PipeDelegate){
                status = .invalid
                self.salt = HopMessage.generateRandomBytes(size: HopConstants.SALT_LEN)!
                let key = ApiService.pInst.P2pKey()
                self.aesKey = try! AES(key: key,
                                       blockMode: CFB(iv: self.salt!.bytes),
                                       padding:.noPadding)
                self.delegate = d
                self.sid = sid
                self.target = target
                super.init()
                NSLog("--------->[SID=\(self.sid)] adapter step[1] obj created")
        }
        
        func startWork(){
                guard let provider = SocksV5Server.provider else{
                        NSLog("--------->[SID=\(self.sid)] failed start, provider is nil")
                        return
                }
                
                let miner_host = NWHostEndpoint(hostname: ApiService.pInst.minerIP!,
                                                port: "\(ApiService.pInst.minerPort!)")
                
                self.connection = provider.createTCPConnection(to: miner_host,
                                                        enableTLS: false,
                                                        tlsParameters:nil,
                                                        delegate: nil)
                
                self.connection.addObserver(self, forKeyPath: "state",
                                 options: .initial,
                                 context: nil)
                status = .connecting
                
                NSLog("--------->[SID=\(self.sid)] adapter step[2] new remote obj start to work miner[\(miner_host.description)]")
        }
        
        
        func stopWork(reason:String?=nil){
                if let r = reason {
                        NSLog(r)
                }
                guard self.status != .stopped else{
                        return
                }
                self.status = .stopped
                self.delegate.pipeBreakUp()
                self.connection.cancel()
        }
        
        func writeToServer(data:Data){
                guard let encode_data = try? self.aesKey!.encrypt(data.bytes) else{
                        self.stopWork(reason: "--------->SID=\(self.sid)]encode app data failed")
                        return
                }
                let lv_data = DataWithLen(data: Data(encode_data))
                self.connection.write(lv_data) { err in
                        if let e = err{
                                self.stopWork(reason:"--------->[SID=\(self.sid)] write encoded  data to server err:[\(e)]")
                                return
                        }
                        NSLog("--------->[SID=\(self.sid)] adapter write lv_data[\(lv_data.count)] success")
                }
        }
        
        func readSrvData(){
                readByLV(ready: self.decodeSrvData)
        }
        
        private func decodeSrvData(data:Data){
                NSLog("--------->[SID=\(self.sid)] adapter get packets[len=\(data.count)] from miner")
                guard let decoded_data = self.readEncoded(data: data) else{
                        self.stopWork(reason: "--------->SID=\(self.sid)] adapter step[7] forward invalid coded data")
                        return
                }
                self.delegate.gotServerData(data:decoded_data)
        }
}

// MARK: - connection delegate
extension SocksV5RemoteSocket{
        
        /// Handle changes to the tunnel connection state.
        open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
                guard keyPath == "state" else {
                        NSLog("--------->[SID=\(self.sid)] adapter connection unknown keyPath=\(String(describing: keyPath))")
                        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
                        return
                }
                
                switch connection!.state {
                case .connected:
                        NSLog("--------->[SID=\(self.sid)] adapter step[3] miner conntected")
                        self.setupMsg()
                        break
                        
                case .disconnected:
                        guard let err = connection!.error as? NSError else{
                                return
                        }
                        NSLog("--------->[SID=\(self.sid)] adapter state disconnected [\(err)]")
                        
                case .cancelled:
                        NSLog("--------->[SID=\(self.sid)] adapter miner cancelled")
                        connection!.removeObserver(self, forKeyPath:"state", context:&connection)
                        connection = nil
                        break
                        
                default:
                        NSLog("--------->[SID=\(self.sid)] adapter state[\(connection!.state)] changed")
                        break
                }
        }
}

// MARK: - remote data logic
extension SocksV5RemoteSocket{
        
        func setupMsg(){
                guard let setup_Data = try? HopMessage.SetupMsg(iv:self.salt!,
                                                                subAddr: ApiService.pInst.userSubAddress) else{
                        self.stopWork(reason: "--------->SID=\(self.sid)] setup data empty")
                        return
                }
                
                let lv_data = DataWithLen(data: setup_Data)
                self.connection.write(lv_data) { err in
                        if let e = err{
                                self.stopWork(reason:"--------->[SID=\(self.sid)] step[3] write setup data err[\(e)]")
                                return
                        }
                        self.status = .readingSetupACKLen
                        self.readByLV(ready: self.makeProbMsg)
                }
        }
        
        func makeProbMsg(data:Data){
                let obj = JSON(data)
                guard obj["Success"].bool == true else{
                        self.stopWork(reason: "--------->SID=\(self.sid)]miner setup protocol failed")
                        return
                }
                
                NSLog("--------->[SID=\(self.sid)] adapter step[4] prepare to prob")
                guard let prob_data = try? HopMessage.ProbMsg(target: self.target!) else{
                        self.stopWork(reason: "--------->didRead[\(self.sid)]miner setup protocol failed")
                        return
                }
                let encode_data = try! self.aesKey!.encrypt(prob_data.bytes)
                let lv_data = DataWithLen(data: Data(encode_data))
                self.connection.write(lv_data){err in
                        if let e = err{
                                self.stopWork(reason:"--------->[SID=\(self.sid)] step[4] write prob data err[\(e)]")
                                return
                        }
                        
                        self.status = .readingProbACKLen
                        self.readByLV(ready: self.prepareForwarding)
                }
        }
        
        func prepareForwarding(data:Data){
                guard let decoded_data = self.readEncoded(data:data) else{
                        self.stopWork(reason: "--------->SID=\(self.sid)] adapter miner read encoded msg failed")
                        return
                }
                let obj = JSON(decoded_data)
                guard obj["Success"].bool == true else{
                        self.stopWork(reason: "--------->SID=\(self.sid)] adapter miner prob protocol failed")
                        return
                }
                
                NSLog("--------->[SID=\(self.sid)] adapter step[final] prob success")
                self.status = .forwarding
                self.delegate.remoteSockeyReady()
        }
        
        func readByLV(ready:@escaping (Data)->Void){
                self.connection.readLength(HOPAdapter.PACK_HEAD_SIZE, completionHandler: {data, err in
                        if let e = err{
                                self.stopWork(reason: "--------->[SID=\(self.sid)] adapter read head length err[\(e)]")
                                return
                        }
                        guard let d = data else{
                                self.stopWork(reason: "--------->[SID=\(self.sid)] adapter read head length data is empty")
                                return
                        }
                        let len = d.ToInt()
                        guard len > 0 else{
                                self.stopWork(reason: "--------->[SID=\(self.sid)] adapter head length[\(len)] is invalid")
                                return
                        }
                        
                        self.connection.readLength(len) { data, err in
                                if let e = err{
                                        self.stopWork(reason: "--------->[SID=\(self.sid)] adapter read content err[\(e)]")
                                        return
                                }
                                guard let d = data else{
                                        self.stopWork(reason: "--------->[SID=\(self.sid)] adapter content data is empty")
                                        return
                                }
                                ready(d)
                        }
                })
        }
        
        func readEncoded(data:Data)-> Data? {
                guard let decode_data = try? self.aesKey?.decrypt(data.bytes) else{
                        NSLog("--------->[SID=\(self.sid)]decrypt data is failed")
                        return nil
                }
                return Data(decode_data)
        }
}
