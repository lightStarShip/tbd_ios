//
//  HOPAdapterFactory.swift
//  extension
//
//  Created by hyperorchid on 2020/2/19.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit
import NEKit

class HOPAdapterFactory: AdapterFactory {
        let miner: String
        let serverIP: String
        let serverPort: Int
        var objID:Int = 0
        
        public init?(miner: String) {
                self.miner = miner
                guard let ip = BasUtil.Query(addr: miner) else{
                        return nil
                }
                self.serverIP = ip
                self.serverPort = Int(BasUtil.AddressToPort(addr: miner))
        }
        
        override open func getAdapterFor(session: ConnectSession) -> AdapterSocket {
                objID += 1
                let adapter = HOPAdapter(serverHost: serverIP,
                                         serverPort: serverPort,
                                         ID:objID)
                adapter.socket = RawSocketFactory.getRawSocket()
                return adapter
        }
}
