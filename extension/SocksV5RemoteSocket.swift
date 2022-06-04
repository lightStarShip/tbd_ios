//
//  SocksV5RemoteSocket.swift
//  vpn
//
//  Created by wesley on 2022/6/4.
//  Copyright © 2022 hyperorchid. All rights reserved.
//

import Foundation
import NetworkExtension


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
        
        
        private var socket: NWTCPConnection!
        private var status:AdapterStatus = .invalid
        private var delegate:SocksV5ServerDelegate!
        
        public init(conn:NWTCPConnection, delegate d: SocksV5ServerDelegate){
                self.socket = conn
                self.delegate = d
                super.init()
        }
        
        func startWork(){
        }
        
        
        func stopWork(){
                
        }
}
