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


enum SocksV5Err: Error {
        case socksLost
        case openRemoteErr
}


open class SocksV5Server: NSObject {
        
        public static var SID = 0
        fileprivate var listenSocket: GCDAsyncSocket!
        public let port: UInt16
        public let address: String
        private static var pipeCache:[Int:SocksV5Pipe] = [:]
        private let proxyQueue = DispatchQueue.init(label: "Big Dipper Proxy Service Queue")

        public static var provider:NEPacketTunnelProvider? = nil
        
        public init(address: String, port: UInt16, provider: NEPacketTunnelProvider) {
                self.port = port
                self.address = address
                super.init()
                
                SocksV5Server.provider = provider
        }
        
        open func start() throws {
                listenSocket = GCDAsyncSocket.init(delegate: self,
                                                   delegateQueue: proxyQueue,
                                                   socketQueue: proxyQueue)
                
                try listenSocket.accept(onInterface: self.address, port: self.port)
                PacketLog(debug:need_debug_packet, "--------->Proxy server started......\(self.address):\(self.port)")
        }
        
        open func stop() {
                listenSocket.disconnect()
                listenSocket = nil
        }
        public static func RemoveCachedPipe(pid:Int){
                pipeCache.removeValue(forKey: pid)
        }
}

extension SocksV5Server:GCDAsyncSocketDelegate{
        
        open func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
                
                SocksV5Server.SID += 1
                let pid = SocksV5Server.SID
                let pipe = SocksV5Pipe(pid: pid)
                SocksV5Server.pipeCache[pid] = pipe
                
                let socks5_obj =  SocksV5LocalSocket(socket: newSocket,
                                                     delegate: pipe,
                                                     sid:pid)
                pipe.setLocalSocket(socket: socks5_obj)
        }
}
