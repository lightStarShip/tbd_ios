//
//  ApplyToken.swift
//  Pirate
//
//  Created by hyperorchid on 2020/3/17.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import web3swift
import BigInt

public class ApplyToken:NSObject{
        
        var web3:web3?
        var address:EthereumAddress?
        var contract:web3.web3contract?
        
        public static let AbiVersion = 2
        public override init() {
                super.init()
        }
        
        public func initRequest() throws{
                web3 = Web3.InfuraRopstenWeb3(accessToken: HopConstants.DefaultInfruaToken)
                address = EthereumAddress(HopConstants.DefaultApplyFreeAddr)!
                guard let filePath = Bundle.main.url(forResource: "ApplyToken", withExtension: "abi") else{
                        throw HopError.eth("Invalid abi file for ApplyToken".locStr)
                }
                let abi_str = try String.init(contentsOf: filePath)
               
                guard let c = web3!.contract(abi_str, at: address, abiVersion: ApplyToken.AbiVersion) else {
                        throw HopError.eth("Create contract[ApplyToken] from abi failed".locStr)
                }
                self.contract = c
        }
        
        public func ApplyeETH(user:EthereumAddress)throws -> web3swift.TransactionSendingResult{
                return try _applyAction(action: "applyEth", user: user)
        }
        
        public func ApplyeToken(user:EthereumAddress)throws -> web3swift.TransactionSendingResult{
                return try _applyAction(action: "applyFreeToken", user: user)
        }
        private func _applyAction(action:String,
                                 user:EthereumAddress)throws -> web3swift.TransactionSendingResult{
                
                let contract = self.contract
                var basicOptions = TransactionOptions()
                basicOptions.from = EthereumAddress("0x9e117f79a1a7cba2545d31c8321efabab9841bed")!
                basicOptions.to = self.address
                basicOptions.callOnBlock = .latest
                
                let wallet_cipher = """
                {"address":"9e117f79a1a7cba2545d31c8321efabab9841bed","crypto":{"cipher":"aes-128-ctr","ciphertext":"11915c4e6154ab42bece43db5a7500eaabdbab4f042f8f9e9edde0ee47e46ecc","cipherparams":{"iv":"f86a84a81b1e0cd7a04b263fe5a51417"},"kdf":"scrypt","kdfparams":{"dklen":32,"n":262144,"p":1,"r":8,"salt":"5fd22b29d9e920fc3fd84c0199f069ea72efcec14b9d56e113b123fc2e7eb06d"},"mac":"5935f33b84a2b52b9ab28a68169d03cdcc2704f72fbb2cf9cdf92db00e0ef7d0"},"id":"972145bc-5962-4d2a-8fe8-c46fe84e4906","version":3}
                """
                
                let key_store = EthereumKeystoreV3.init(wallet_cipher)
                guard let pri_key = try key_store?.UNSAFE_getPrivateKeyData(password: "123",
                                                    account: EthereumAddress("0x9e117f79a1a7cba2545d31c8321efabab9841bed")!) else{
                                                        throw HopError.wallet("Open local test account to apply free token failed".locStr)
                }
                
                let tx = contract!.write(action,
                                        parameters: [user] as [AnyObject],
                                        transactionOptions: basicOptions)!
                return try tx.send(priKey: pri_key)
        }
}
