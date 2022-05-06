//
//  EthUtil.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/25.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import web3swift
import BigInt

public final class EthUtil :NSObject{
        var HopToken:ERC20?
        var PaymentService:PacketMarket?
        var web3:web3?
        public static var sharedInstance = EthUtil()
        let queue = DispatchQueue.init(label: "ETH_BACK_GROUND", qos: .default)
        private override init() {
                super.init()
        }
        
        public func initEth(testNet:Bool? = true) throws{
                
                if testNet == nil || testNet! == true{
                        self.web3 = Web3.InfuraRopstenWeb3(accessToken: HopConstants.DefaultInfruaToken)
                }else{
                        self.web3 = Web3.InfuraMainnetWeb3(accessToken: HopConstants.DefaultInfruaToken)
                }
                guard let token = EthereumAddress(HopConstants.DefaultTokenAddr), let payService = EthereumAddress(HopConstants.DefaultPaymenstService) else{
                        throw HopError.eth("Invalid ethereum config".locStr)
                }
                
                self.HopToken = ERC20.init(web3: self.web3!, address:token)
                self.PaymentService = try PacketMarket.init(web3: self.web3!, address: payService)
        }
        
        
        public func Balance(userAddr:EthereumAddress) -> (BigUInt, BigUInt){
                guard let server = self.PaymentService else{
                        return (0, 0)
                }
                
                return server.Balance(userAddr: userAddr)
        }
}

extension EthereumAddress{
        
        public static let ZeroAddress = "0x0000000000000000000000000000000000000000"
        
        public func isValid2() -> Bool{
                return self.isValid && self.address != EthereumAddress.ZeroAddress
        }
}
