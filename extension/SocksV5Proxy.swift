//
//  GCDProxyServer.swift
//  vpn
//
//  Created by wesley on 2022/6/3.
//  Copyright © 2022 hyperorchid. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

open class SocksV5Proxy: NSObject {
        fileprivate var listenSocket: GCDAsyncSocket!
        let proxyQueue = DispatchQueue.init(label: "Big Dipper Proxy Queue")
        public let port: UInt16
        public let address: String
        private var proxyCache:[Int:SocksV5Socket] = [:]
        
        public init(address: String, port: UInt16) {
                self.port = port
                self.address = address
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

extension SocksV5Proxy:GCDAsyncSocketDelegate{
        
        open func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
                let socks5_obj =  SocksV5Socket(socket: newSocket, delegate: self)
                proxyCache[socks5_obj.sid] = socks5_obj
                proxyQueue.async {
                        socks5_obj.startWork()
                }
        }
}
extension SocksV5Proxy:SocksV5SocketDelegate{
        
        public func createPipe(tHost: String, tPort: Int, sid: Int) -> Error?{
                var err:Error?
                
                return err
        }
        
        public func receivedAppData(data: Data, sid: Int) {
                
        }
        
        public func connectClosed(sid: Int) {
                proxyCache.removeValue(forKey: sid)
        }
}
