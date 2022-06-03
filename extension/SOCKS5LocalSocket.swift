//
//  SOCKS5LocalSocket.swift
//  vpn
//
//  Created by wesley on 2022/6/3.
//  Copyright © 2022 hyperorchid. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public class SOCKS5LocalSocket:NSObject{
        
        enum SOCKS5ProxyReadStatus: CustomStringConvertible {
            case invalid,
            readingVersionIdentifierAndNumberOfMethods,
            readingMethods,
            readingConnectHeader,
            readingIPv4Address,
            readingDomainLength,
            readingDomain,
            readingIPv6Address,
            readingPort,
            forwarding,
            stopped

            var description: String {
                switch self {
                case .invalid:
                    return "invalid"
                case .readingVersionIdentifierAndNumberOfMethods:
                    return "reading version and methods"
                case .readingMethods:
                    return "reading methods"
                case .readingConnectHeader:
                    return "reading connect header"
                case .readingIPv4Address:
                    return "IPv4 address"
                case .readingDomainLength:
                    return "domain length"
                case .readingDomain:
                    return "domain"
                case .readingIPv6Address:
                    return "IPv6 address"
                case .readingPort:
                    return "reading port"
                case .forwarding:
                    return "forwarding"
                case .stopped:
                    return "stopped"
                }
            }
        }

        enum SOCKS5ProxyWriteStatus: CustomStringConvertible {
            case invalid,
            sendingResponse,
            forwarding,
            stopped

            var description: String {
                switch self {
                case .invalid:
                    return "invalid"
                case .sendingResponse:
                    return "sending response"
                case .forwarding:
                    return "forwarding"
                case .stopped:
                    return "stopped"
                }
            }
        }
        
        
        fileprivate let socket: GCDAsyncSocket
        private var readStatus: SOCKS5ProxyReadStatus = .invalid
        private var writeStatus: SOCKS5ProxyWriteStatus = .invalid

        public init(socket:GCDAsyncSocket){
                self.socket = socket
                super.init()
        }
        public func startWork(){
                readStatus = .readingVersionIdentifierAndNumberOfMethods
                socket.readData(toLength: 2, withTimeout: -1, tag: 0)
        }
}

// MARK: - Delegate methods for GCDAsyncSocket
extension SOCKS5LocalSocket:GCDAsyncSocketDelegate{
        open func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        }

        open func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
                self.socketLogic(data: data)
        }

        open func socketDidDisconnect(_ socket: GCDAsyncSocket, withError err: Error?) {
        }

        open func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
           
        }

        open func socketDidSecure(_ sock: GCDAsyncSocket) {
            
        }
}

extension SOCKS5LocalSocket{
        private func socketLogic(data:Data){
                switch readStatus {
                case .readingVersionIdentifierAndNumberOfMethods:
                        
                data.withUnsafeBytes { pointer in
                    let p = pointer.bindMemory(to: Int8.self)
                    
                    guard p.baseAddress!.pointee == 5 else {
                        // TODO: notify observer
                            self.socket.disconnect()
                        return
                    }

                    guard p.baseAddress!.successor().pointee > 0 else {
                        // TODO: notify observer
                            self.socket.disconnect()
                        return
                    }

                let len = Int(p.baseAddress!.successor().pointee)
                        self.socket.readData(toLength:UInt(len), withTimeout: -1, tag: 0 )
                        self.readStatus = .readingMethods
                }
                        break
                case .invalid: break
                        
                case .readingMethods:
                        break
                case .readingConnectHeader:
                        break
                case .readingIPv4Address:
                        break
                case .readingDomainLength:
                        break
                case .readingDomain:
                        break
                case .readingIPv6Address:
                        break
                case .readingPort:
                        break
                case .forwarding:
                        break
                case .stopped:
                        break
                }
        }
}
