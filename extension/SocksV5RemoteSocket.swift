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
        public static var MAXNWTCPScanLength = (1<<13)
        public static let nwqueue = DispatchQueue(label: "remote socket worker queue")
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
        private var delegate:SocksV5ServerDelegate!
        private var sid:Int
        private var target:String?
        private var salt:Data?
        private var aesKey:AES?
        
        public init(sid :Int, target:String, delegate d: SocksV5ServerDelegate){
                
                let miner_host = NWHostEndpoint(hostname: ApiService.pInst.minerIP,
                                                port: "\(ApiService.pInst.minerPort!)")
                var conn =  d.NWScoket(remoteAddr: miner_host)
                self.connection = conn
                self.delegate = d
                self.sid = sid
                super.init()
                conn.addObserver(self, forKeyPath: "state", options: .initial, context: &conn)
                NSLog("--------->[SID=\(self.sid)] step[1] new remote obj created")
        }
        
        func startWork(){
                do{
                        status = .connecting
                        self.salt = HopMessage.generateRandomBytes(size: HopConstants.SALT_LEN)!
                        let key = ApiService.pInst.P2pKey()
                        self.aesKey = try AES(key: key,
                                              blockMode: CFB(iv: self.salt!.bytes),
                                              padding:.noPadding)
                }catch let err{
                        NSLog("--------->[SID=\(self.sid)] remote socket init err:=>\(err.localizedDescription)")
                        self.stopWork()
                }
                
                NSLog("--------->[SID=\(self.sid)] step[2] new remote obj start to work")
        }
        
        
        func stopWork(reason:String?=nil){
                if let r = reason {
                        NSLog(r)
                }
                guard self.status != .stopped else{
                        return
                }
                self.status = .stopped
                self.delegate.pipeBreakUp(sid: self.sid)
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
                                self.stopWork(reason:"--------->[SID=\(self.sid)] write encode app data failed [\(e)]")
                                return
                        }
                }
        }
}

// MARK: - connection delegate
extension SocksV5RemoteSocket{
        
        /// Handle changes to the tunnel connection state.
        open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
                guard keyPath == "state" && context?.assumingMemoryBound(to: Optional<NWTCPConnection>.self).pointee == connection else {
                        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
                        return
                }
                
                switch connection!.state {
                case .connected:
                        
                        self.setupMsg()
                        break
                        
                case .disconnected:
                        guard let err = connection!.error as? NSError else{
                                return
                        }
                        
                        self.stopWork(reason:"--------->[SID=\(self.sid)] state disconnected [\(err)]")
                        
                case .cancelled:
                        connection!.removeObserver(self, forKeyPath:"state", context:&connection)
                        connection = nil
                        break
                        
                default:
                        break
                }
        }
}

// MARK: - remote data logic
extension SocksV5RemoteSocket{
        
        func setupMsg(){
                guard let setup_Data = try? HopMessage.SetupMsg(iv:self.salt!,
                                                                subAddr: ApiService.pInst.userSubAddress) else{
                        self.stopWork()
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
                guard let prob_data = try? HopMessage.ProbMsg(target: self.target!) else{
                        self.stopWork(reason: "--------->didRead[\(self.sid)]miner setup protocol failed")
                        return
                }
                self.connection.write( prob_data){err in
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
                        self.stopWork(reason: "--------->SID=\(self.sid)]miner read encoded msg failed")
                        return
                }
                let obj = JSON(decoded_data)
                guard obj["Success"].bool == true else{
                        self.stopWork(reason: "--------->SID=\(self.sid)]miner prob protocol failed")
                        return
                }
                self.status = .forwarding
                SocksV5RemoteSocket.nwqueue.async {
                        self.readByLV(ready: self.forwardToPipe)
                }
        }
        
        func forwardToPipe(data:Data){
                guard let decoded_data = self.readEncoded(data: data) else{
                        self.stopWork(reason: "--------->SID=\(self.sid)]step[5] forward invalid coded data")
                        return
                }
                if let e = self.delegate.loadDataFromServer(data:decoded_data, sid: self.sid){
                        self.stopWork(reason: "--------->SID=\(self.sid)]step[5] forward data to app err[\(e.localizedDescription)]")
                        return
                }
                SocksV5RemoteSocket.nwqueue.async {
                        self.readByLV(ready: self.forwardToPipe)
                }
        }
        
        func readByLV(ready:@escaping (Data)->Void){
                self.connection.readLength(HOPAdapter.PACK_HEAD_SIZE, completionHandler: {data, err in
                        if let e = err{
                                self.stopWork(reason: "--------->[SID=\(self.sid)]read head length err[\(e)]")
                                return
                        }
                        guard let d = data else{
                                self.stopWork(reason: "--------->[SID=\(self.sid)]read head length data is empty")
                                return
                        }
                        let len = d.ToInt()
                        guard len > 0 else{
                                self.stopWork(reason: "--------->[SID=\(self.sid)]head length[\(len)] is invalid")
                                return
                        }
                        
                        self.connection.readLength(len) { data, err in
                                if let e = err{
                                        self.stopWork(reason: "--------->[SID=\(self.sid)]read content err[\(e)]")
                                        return
                                }
                                guard let d = data else{
                                        self.stopWork(reason: "--------->[SID=\(self.sid)]content data is empty")
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
