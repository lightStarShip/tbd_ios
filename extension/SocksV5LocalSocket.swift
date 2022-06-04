//
//  SOCKS5LocalSocket.swift
//  vpn
//
//  Created by wesley on 2022/6/3.
//  Copyright © 2022 hyperorchid. All rights reserved.
//

/*
 1.  Introduction
 The use of network firewalls, systems that effectively isolate an
 organizations internal network structure from an exterior network,
 such as the INTERNET is becoming increasingly popular.  These
 firewall systems typically act as application-layer gateways between
 networks, usually offering controlled TELNET, FTP, and SMTP access.
 With the emergence of more sophisticated application layer protocols
 designed to facilitate global information discovery, there exists a
 need to provide a general framework for these protocols to
 transparently and securely traverse a firewall.
 There exists, also, a need for strong authentication of such
 traversal in as fine-grained a manner as is practical. This
 requirement stems from the realization that client-server
 relationships emerge between the networks of various organizations,
 and that such relationships need to be controlled and often strongly
 authenticated.
 The protocol described here is designed to provide a framework for
 client-server applications in both the TCP and UDP domains to
 conveniently and securely use the serverList of a network firewall.
 The protocol is conceptually a "shim-layer" between the application
 layer and the transport layer, and as such does not provide network-
 layer gateway serverList, such as forwarding of ICMP messages.
 2.  Existing practice
 There currently exists a protocol, SOCKS Version 4, that provides for
 unsecured firewall traversal for TCP-based client-server
 applications, including TELNET, FTP and the popular information-
 discovery protocols such as HTTP, WAIS and GOPHER.
 This new protocol extends the SOCKS Version 4 model to include UDP,
 and extends the framework to include provisions for generalized
 strong authentication schemes, and extends the addressing scheme to
 encompass domain-name and V6 IP addresses.
 The implementation of the SOCKS protocol typically involves the
 recompilation or relinking of TCP-based client applications to use
 the appropriate encapsulation routines in the SOCKS library.
 Note:
 Unless otherwise noted, the decimal numbers appearing in packet-
 format diagrams represent the length of the corresponding field, in
 octets.  Where a given octet must take on a specific value, the
 syntax X’hh’ is used to denote the value of the single octet in that
 field. When the word ’Variable’ is used, it indicates that the
 corresponding field has a variable length defined either by an
 associated (one or two octet) length field, or by a data type field.
 
 */


import Foundation
import CocoaAsyncSocket

public class SocksV5LocalSocket:NSObject{
        public static let Socks5Ver =  Data([0x05, 0x00])
        public static let SocksVersion = 5
        
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
        
        
        private var socket: GCDAsyncSocket?
        private var readStatus: SOCKS5ProxyReadStatus = .invalid
        private var writeStatus: SOCKS5ProxyWriteStatus = .invalid
        private var delegate:SocksV5ServerDelegate!
        private(set) var sid:Int
        public var destinationHost: String!
        public var destinationPort: Int!
        
        public init(socket:GCDAsyncSocket, delegate d:SocksV5ServerDelegate, sid:Int){
                self.sid = sid
                super.init()
                self.socket = socket
                socket.delegate = self
                self.delegate = d
                NSLog("--------->[SID=\(self.sid)] new socks5 obj created")
        }
        public func startWork(){
                readStatus = .readingVersionIdentifierAndNumberOfMethods
                socket?.readData(toLength: 2, withTimeout: -1, tag: self.sid)
                NSLog("--------->[SID=\(self.sid)] socks5 step[1]  read fisrt 2 data")
        }
        
        public func stopWork(reason:String? =  nil){
                if let r = reason {
                        NSLog(r)
                }
                guard let s = self.socket else{
                        return
                }
                s.disconnect()
                self.socket = nil
                self.delegate?.pipeBreakUp(sid: self.sid)
        }
        public func writeToApp(data:Data){
                self.write(data: data)
        }
}

// MARK: - Delegate methods for GCDAsyncSocket
extension SocksV5LocalSocket:GCDAsyncSocketDelegate{
        open func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        }
        
        open func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
                guard readStatus == .forwarding else{
                        self.readTarget(data: data, withTag:tag)
                        return
                }
                if let e = self.delegate?.receivedAppData(data:data, sid: self.sid){
                        self.stopWork(reason: "--------->[SID=\(self.sid)] process app data err:[\(e.localizedDescription)]")
                        return
                }
        }
        
        open func socketDidDisconnect(_ socket: GCDAsyncSocket, withError err: Error?) {
        }
        
        open func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
                
        }
        
        open func socketDidSecure(_ sock: GCDAsyncSocket) {
                
        }
}

extension SocksV5LocalSocket{
        
        private func readTarget(data:Data, withTag tag: Int){
                switch readStatus {
                        
                        /*
                         3.  Procedure for TCP-based clients
                         When a TCP-based client wishes to establish a connection to an object
                         that is reachable only via a firewall (such determination is left up
                         to the implementation), it must open a TCP connection to the
                         appropriate SOCKS port on the SOCKS server system.  The SOCKS service
                         is conventionally located on TCP port 1080.  If the connection
                         request succeeds, the client enters a negotiation for the
                         authentication method to be used, authenticates with the chosen
                         method, then sends a relay request.  The SOCKS server evaluates the
                         request, and either establishes the appropriate connection or denies
                         it.
                         Unless otherwise noted, the decimal numbers appearing in packet-
                         format diagrams represent the length of the corresponding field, in
                         octets.  Where a given octet must take on a specific value, the
                         syntax X’hh’ is used to denote the value of the single octet in that
                         field. When the word ’Variable’ is used, it indicates that the
                         corresponding field has a variable length defined either by an
                         associated (one or two octet) length field, or by a data type field.
                         The client connects to the server, and sends a version
                         identifier/method selection message:
                         +----+----------+----------+
                         |VER | NMETHODS | METHODS  |
                         +----+----------+----------+
                         | 1  |    1     | 1 to 255 |
                         +----+----------+----------+
                         The VER field is set to X’05’ for this version of the protocol.  The
                         NMETHODS field contains the number of method identifier octets that
                         appear in the METHODS field.
                         The server selects from one of the methods given in METHODS, and
                         sends a METHOD selection message:
                         +----+--------+
                         |VER | METHOD |
                         +----+--------+
                         |  1 |    1   |
                         +----+--------+
                         If the selected METHOD is X’FF’, none of the methods listed by the
                         client are acceptable, and the client MUST close the connection.
                         The values currently defined for METHOD are:
                         o  X’00’ NO AUTHENTICATION REQUIRED
                         o  X’01’ GSSAPI
                         o  X’02’ USERNAME/PASSWORD
                         o  X’03’ to X’7F’ IANA ASSIGNED
                         o  X’80’ to X’FE’ RESERVED FOR PRIVATE METHODS
                         o  X’FF’ NO ACCEPTABLE METHODS
                         The client and server then enter a method-specific sub-negotiation.
                         Descriptions of the method-dependent sub-negotiations appear in
                         separate memos.
                         Developers of new METHOD support for this protocol should contact
                         IANA for a METHOD number.  The ASSIGNED NUMBERS document should be
                         referred to for a current list of METHOD numbers and their
                         corresponding protocols.
                         Compliant implementations MUST support GSSAPI and SHOULD support
                         USERNAME/PASSWORD authentication methods.
                         */
                        
                case .readingVersionIdentifierAndNumberOfMethods:
                        guard data.count == 2 else{
                                self.stopWork(reason: "--------->[SID=\(self.sid)] socks5 step[2] data length[\(data.count)] invalid")
                                return
                        }
                        
                        let socks_ver = data[0]
                        let socks_len = data[1]
                        guard socks_ver == SocksV5LocalSocket.SocksVersion && socks_len > 0 else{
                                self.stopWork(reason: "--------->[SID=\(self.sid)] socks5 step[2] data[\(socks_ver), \(socks_len)] param invalid")
                                return
                        }
                        self.readTo(len: UInt(socks_len))
                        self.readStatus = .readingMethods
                        NSLog("--------->[SID=\(self.sid)] socks5 step[2] start to read method")
                        break
                        
                        /*
                         
                         4. Requests
                         Once the method-dependent subnegotiation has completed, the client
                         sends the request details.  If the negotiated method includes
                         encapsulation for purposes of integrity checking and/or
                         confidentiality, these requests MUST be encapsulated in the method-
                         dependent encapsulation.
                         The SOCKS request is formed as follows:
                         +----+-----+-------+------+----------+----------+
                         |VER | CMD |  RSV  | ATYP | DST.ADDR | DST.PORT |
                         +----+-----+-------+------+----------+----------+
                         | 1  |  1  | X’00’ |  1   | Variable |    2     |
                         +----+-----+-------+------+----------+----------+
                         Where:
                         o  VER    protocol version: X’05’
                         o  CMD
                         o  CONNECT X’01’
                         o  BIND X’02’
                         o  UDP ASSOCIATE X’03’
                         o  RSV    RESERVED
                         o  ATYP   address type of following address
                         o  IP V4 address: X’01’
                         o  DOMAINNAME: X’03’
                         o  IP V6 address: X’04’
                         o  DST.ADDR       desired destination address
                         o  DST.PORT desired destination port in network octet
                         order
                         The SOCKS server will typically evaluate the request based on source
                         and destination addresses, and return one or more reply messages, as
                         appropriate for the request type.
                         
                         5.  Addressing
                         In an address field (DST.ADDR, BND.ADDR), the ATYP field specifies
                         the type of address contained within the field:
                         o  X’01’
                         the address is a version-4 IP address, with a length of 4 octets
                         o X’03’
                         the address field contains a fully-qualified domain name.  The first
                         octet of the address field contains the number of octets of name that
                         follow, there is no terminating NUL octet.
                         o  X’04’
                         the address is a version-6 IP address, with a length of 16 octets.
                         */
                case .readingMethods:
                        // TODO: check for 0x00 in read data
                        self.write(data: SocksV5LocalSocket.Socks5Ver)
                        readStatus = .readingConnectHeader
                        self.readTo(len: 4)
                        NSLog("--------->[SID=\(self.sid)] socks5 step[3] start to read header ")
                        break
                        
                case .readingConnectHeader:
                        guard data.count == 4 else{
                                self.stopWork(reason: "--------->[SID=\(self.sid)] socks5 step[4] data length[\(data.count)] invalid")
                                return
                        }
                        let ver = data[0]
                        let cmd = data[1]
                        guard ver == SocksV5LocalSocket.SocksVersion && cmd == 1 else{
                                self.stopWork(reason: "--------->[SID=\(self.sid)] socks5 step[4] [ver=\(ver),cmd=\(cmd)] invalid")
                                return
                        }
                        let typ = data[3]
                        switch typ{
                        case 1:
                                readStatus = .readingIPv4Address
                                self.readTo(len: 4)
                                break
                        case 3:
                                readStatus = .readingDomainLength
                                self.readTo(len: 1)
                                break
                        case 4:
                                readStatus = .readingIPv6Address
                                self.readTo(len: 16)
                                break
                        default:
                                self.stopWork(reason: "--------->[SID=\(self.sid)] socks5 step[4] [typ=\(typ)] invalid")
                                return
                        }
                        NSLog("--------->[SID=\(self.sid)] socks5 step[4] start to read host [typ=\(typ)]")
                        break
                case .readingIPv4Address:
                        var address = Data(count: Int(INET_ADDRSTRLEN))
                        _ = data.withUnsafeBytes { data_ptr in
                            address.withUnsafeMutableBytes { addr_ptr in
                                inet_ntop(AF_INET, data_ptr.baseAddress!, addr_ptr.bindMemory(to: Int8.self).baseAddress!, socklen_t(INET_ADDRSTRLEN))
                            }
                        }
                        
                        destinationHost = String(data: address, encoding: .utf8)

                        readStatus = .readingPort
                        self.readTo(len: 2)
                        NSLog("--------->[SID=\(self.sid)] socks5 step[5] [host=\(destinationHost!)]")
                        break
                case .readingDomainLength:
                        guard data.count == 1 else{
                                self.stopWork(reason: "--------->[SID=\(self.sid)] socks5 step[5] data length[\(data.count)] invalid")
                                return
                        }
                        readStatus = .readingDomain
                        self.readTo(len:UInt(data[0]))
                        NSLog("--------->[SID=\(self.sid)] socks5 step[5] host [len=\(data[0])]")
                        break
                case .readingDomain:
                        destinationHost = String(data: data, encoding: .utf8)
                        readStatus = .readingPort
                        self.readTo(len: 2)
                        NSLog("--------->[SID=\(self.sid)] socks5 step[6] [host=\(destinationHost!)]")
                        break
                case .readingIPv6Address:
                        var address = Data(count: Int(INET6_ADDRSTRLEN))
                        _ = data.withUnsafeBytes { data_ptr in
                            address.withUnsafeMutableBytes { addr_ptr in
                                inet_ntop(AF_INET6, data_ptr.baseAddress!, addr_ptr.bindMemory(to: Int8.self).baseAddress!, socklen_t(INET6_ADDRSTRLEN))
                            }
                        }

                        destinationHost = String(data: address, encoding: .utf8)
                        readStatus = .readingPort
                        self.readTo(len: 2)
                        NSLog("--------->[SID=\(self.sid)] socks5 step[5] [host=\(destinationHost!)]")
                        break
                        
                case .readingPort:
                        guard data.count == 2 else{
                                self.stopWork(reason: "--------->[SID=\(self.sid)] socks5 step[final] data length[\(data.count)] invalid")
                                return
                        }
                        data.withUnsafeBytes {
                                destinationPort = Int($0.load(as: UInt16.self).bigEndian)
                        }
                        NSLog("--------->[SID=\(self.sid)] socks5 step[final] [port=\(destinationPort!)]")
                        readStatus = .forwarding
                        if let err = self.delegate?.pipeOpenRemote(tHost:destinationHost, tPort:destinationPort, sid: self.sid){
                                self.stopWork(reason: "--------->[SID=\(self.sid)] socks5 step[final] failed=\(err)")
                                return
                        }
                        break
                default:
                        self.stopWork(reason: "--------->[SID=\(self.sid)] socks5 invalid status=\(readStatus.description)")
                    return
                }
        }
}

extension SocksV5LocalSocket{
        func readTo(len:UInt){
                self.socket?.readData(toLength:len, withTimeout: -1, tag: self.sid)
        }
        func write(data:Data){
                self.socket?.write(data, withTimeout: -1, tag: self.sid)
        }
}
