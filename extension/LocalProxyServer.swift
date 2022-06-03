//
//  GCDProxyServer.swift
//  vpn
//
//  Created by wesley on 2022/6/3.
//  Copyright © 2022 hyperorchid. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
open class LocalProxyServer: NSObject {
        fileprivate var listenSocket: GCDAsyncSocket!
        let proxyQueue = DispatchQueue.init(label: "Big Dipper Proxy Queue")
        public let port: UInt16
        public let address: String
        
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
        }
        
        open func stop() {
                listenSocket.disconnect()
                listenSocket = nil
        }
}

extension LocalProxyServer:GCDAsyncSocketDelegate{
        
        open func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
                
        }
}
