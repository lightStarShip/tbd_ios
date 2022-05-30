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
        var objID:Int = 0

        override open func getAdapterFor(session: ConnectSession) -> AdapterSocket {
                objID += 1
                let adapter = HOPAdapter(ID:objID)
                adapter.socket = RawSocketFactory.getRawSocket()
                return adapter
        }
}
