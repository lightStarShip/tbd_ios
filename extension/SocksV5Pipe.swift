//
//  Socks5Pipe.swift
//  vpn
//
//  Created by wesley on 2022/6/4.
//  Copyright © 2022 hyperorchid. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

open class SocksV5Pipe:NSObject{
        var local:SocksV5LocalSocket?
        var remote:SocksV5RemoteSocket?
        
        public init(local l :SocksV5LocalSocket){
                self.local = l
                super.init()
        }
        
        func stopWork(){
                self.local?.stopWork()
                self.remote?.stopWork()
                self.remote = nil
                self.local = nil
        }
}
