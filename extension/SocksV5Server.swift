//
//  GCDProxyServer.swift
//  vpn
//
//  Created by wesley on 2022/6/3.
//  Copyright © 2022 hyperorchid. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import NetworkExtension


enum SocksErr: Error {
        case socksLost
        case openRemoteErr
}

public protocol SocksV5ServerDelegate {
        func pipeBreakUp(sid:Int)
        func pipeOpenRemote(tHost:String, tPort:Int, sid:Int)
        func receivedAppData(data:Data, sid:Int) -> Error?
        func NWScoket(remoteAddr:NWEndpoint)->NWTCPConnection
        func gotServerData(data:Data, sid:Int) -> Error?
}
open class SocksV5Server: NSObject {
        
        public static var SID = 0
        fileprivate var listenSocket: GCDAsyncSocket!
        let proxyQueue = DispatchQueue.init(label: "Big Dipper Proxy Queue")
        public let port: UInt16
        public let address: String
        private var proxyCache:[Int:SocksV5Pipe] = [:]
        private var provider:NEPacketTunnelProvider!
        
        public init(address: String, port: UInt16, provider: NEPacketTunnelProvider) {
                self.port = port
                self.address = address
                self.provider = provider
                super.init()
        }
        
        open func start() throws {
                listenSocket = GCDAsyncSocket.init(delegate: self,
                                                   delegateQueue: proxyQueue,
                                                   socketQueue: proxyQueue)
                
                try listenSocket.accept(onInterface: self.address, port: self.port)
                NSLog("--------->Proxy server started......\(self.address):\(self.port)")
        }
        
        open func stop() {
                listenSocket.disconnect()
                listenSocket = nil
        }
}

extension SocksV5Server:GCDAsyncSocketDelegate{
        
        open func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
                
                SocksV5Server.SID += 1
                let socks5_obj =  SocksV5LocalSocket(socket: newSocket, delegate: self, sid: SocksV5Server.SID)
                let pipe = SocksV5Pipe(local: socks5_obj)
                proxyCache[SocksV5Server.SID] = pipe
                proxyQueue.async {
                        socks5_obj.startWork()
                }
        }
}

extension SocksV5Server:SocksV5ServerDelegate{
        
        public func pipeOpenRemote(tHost: String, tPort: Int, sid: Int){proxyQueue.async {
                guard let pipe = self.proxyCache[sid] else{
                        NSLog("--------->[SID=\(sid)] not fond such pipe")
                        return
                }
                
                let target = "\(tHost):\(tPort)"
                
                NSLog("--------->[SID=\(sid)] server prepare full fill pipe tareget:[\(target)]")
                let remote = SocksV5RemoteSocket(sid: sid, target: target, delegate:self)
                remote.startWork()
                pipe.remote = remote
        }
        }
        
        public func receivedAppData(data: Data, sid: Int)  -> Error?{
                guard let pipe = proxyCache[sid] else{
                        return SocksErr.socksLost
                }
                pipe.remote?.writeToServer(data: data)
                return nil
        }
        
        public func pipeBreakUp(sid: Int) {
                guard let pipe = proxyCache[sid] else{
                        return
                }
                proxyCache.removeValue(forKey: sid)
                pipe.stopWork()
        }
        
        
        public func NWScoket(remoteAddr:NWEndpoint)->NWTCPConnection{
                return self.provider.createTCPConnection(to: remoteAddr, enableTLS: false, tlsParameters:nil, delegate: nil)
        }
        
        public func gotServerData(data:Data, sid:Int) -> Error?{
                guard let pipe = proxyCache[sid] else{
                        return SocksErr.socksLost
                }
                pipe.local?.writeToApp(data:data)
                return nil
        }
}

