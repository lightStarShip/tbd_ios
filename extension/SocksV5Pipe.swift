//
//  Socks5Pipe.swift
//  vpn
//
//  Created by wesley on 2022/6/4.
//  Copyright © 2022 hyperorchid. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public protocol SocksV5PipeDelegate {
        func pipeBreakUp()
        func localSocketReady(target:String)
        func remoteSockeyReady()
        func gotAppData(data:Data)
        func gotServerData(data:Data)
}

open class SocksV5Pipe:NSObject{
        
        private static let lWriteQueue = DispatchQueue.init(label: "Local Writing Queue")
        private static let rWriteQueue = DispatchQueue.init(label: "Remote Writing Queue")
        
        public static let inited = 0x0
        public static let localReady = 0x01
        public static let remoteReady = 0x10
        public static let ready = 0x11
        
        private var localSock:SocksV5LocalSocket?
        private var remoteSock:SocksV5RemoteSocket?
        private(set) var pid:Int
        private var status = inited
        
        private var targetHost:String?
        
        public init(pid s : Int){
                self.pid = s
                super.init()
        }
        
        func setLocalSocket(socket s:SocksV5LocalSocket){
                self.localSock = s
                self.localSock?.startWork()
        }
        
        private func stopWork(reason:String?=nil){
                self.localSock?.stopWork()
                self.remoteSock?.stopWork()
                self.remoteSock = nil
                self.localSock = nil
                SocksV5Server.RemoveCachedPipe(pid: self.pid)
                PacketLog(debug:need_debug_packet, reason ?? "--------->[SID=\(self.pid)] pipe[\(self.targetHost!)] stop work without reason")
        }
}

extension SocksV5Pipe:SocksV5PipeDelegate{
        
        public func localSocketReady(target: String) {
                self.targetHost = target
                self.status = self.status | SocksV5Pipe.localReady
                
                let remote = SocksV5RemoteSocket(sid: self.pid,
                                                 target: target,
                                                 delegate:self)
                self.remoteSock = remote
                self.remoteSock?.startWork()
                
                PacketLog(debug:need_debug_packet, "--------->[SID=\(self.pid)] pipe host found [\(target)] ")
        }
        
        public func remoteSockeyReady() {
                self.status = self.status | SocksV5Pipe.remoteReady
                guard self.status == SocksV5Pipe.ready else{
                        self.stopWork(reason: "--------->[SID=\(self.pid)] pipe[\(self.targetHost!)] status[\(self.status)] invalid")
                        return
                }
                
                PacketLog(debug:need_debug_packet, "--------->[SID=\(self.pid)] pipe[\(self.targetHost!)] is ready!")
                self.localSock?.startReadAppData()
                self.remoteSock?.startReadSrvData()
        }
        
        public func gotAppData(data: Data) {
                SocksV5Pipe.rWriteQueue.sync {
                        self.remoteSock?.writeToServer(data: data)
                }
        }
        
        public func gotServerData(data: Data){
                SocksV5Pipe.lWriteQueue.sync {
                        self.localSock?.writeToApp(data: data)
                }
        }
        
        
        public func pipeBreakUp() {
                self.stopWork(reason: "--------->[SID=\(self.pid)] pipe[\(self.targetHost!)]  break up from delegate")
        }
}
