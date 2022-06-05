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
        public static let inited = 0x0
        public static let localReady = 0x01
        public static let remoteReady = 0x10
        public static let ready = 0x11
        
        private let pipeQueue = DispatchQueue.init(label: "Big Dipper Pipe Queue")
        
        private var localSock:SocksV5LocalSocket?
        private var remoteSock:SocksV5RemoteSocket?
        private(set) var pid:Int
        private var status = inited
        
        public init(pid s : Int){
                self.pid = s
                super.init()
        }
        
        func setLocalSocket(socket s:SocksV5LocalSocket){
                self.localSock = s
                pipeQueue.async {
                        self.localSock?.startWork()
                }
        }
        
        private func stopWork(reason:String?=nil){
                self.localSock?.stopWork()
                self.remoteSock?.stopWork()
                self.remoteSock = nil
                self.localSock = nil
                SocksV5Server.RemoveCachedPipe(pid: self.pid)
                NSLog(reason ?? "--------->[SID=\(self.pid)] pipe stop work without reason")
        }
}

extension SocksV5Pipe:SocksV5PipeDelegate{
        public func remoteSockeyReady() {
                self.status = self.status | SocksV5Pipe.remoteReady
                guard self.status == SocksV5Pipe.ready else{
                        self.stopWork(reason: "--------->[SID=\(self.pid)] pipe status[\(self.status)] invalid")
                        return
                }
                
                NSLog("--------->[SID=\(self.pid)] pipe is ready!")
                pipeQueue.async {
                        self.localSock?.readAppData()
                }
                pipeQueue.async {
                        self.remoteSock?.readSrvData()
                }
        }
        
        public func pipeBreakUp() {
                self.stopWork(reason: "--------->[SID=\(self.pid)] pipe  break up for delegate")
        }
        
        public func localSocketReady(target: String) {
                self.status = self.status | SocksV5Pipe.localReady
                
                let remote = SocksV5RemoteSocket(sid: self.pid, target: target, delegate:self)
                self.remoteSock = remote
                pipeQueue.async {
                        self.remoteSock?.startWork()
                }
                
                NSLog("--------->[SID=\(self.pid)] pipe local socket is ready!")
        }
        
        public func gotAppData(data: Data) {
                self.remoteSock?.writeToServer(data: data)
                pipeQueue.async {
                        self.localSock?.readAppData()
                }
                NSLog("--------->[SID=\(self.pid)] pipe got app data[\(data.count)]")
        }
        
        public func gotServerData(data: Data){
                self.localSock?.writeToApp(data: data)
                pipeQueue.async {
                        self.remoteSock?.readSrvData()
                }
                NSLog("--------->[SID=\(self.pid)] pipe got server data[\(data.count)]")
        }
}
