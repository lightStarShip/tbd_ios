//
//  HopSodium.swift
//  Pirate
//
//  Created by hyperorchid on 2020/3/6.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Foundation
import Sodium
import Curve25519

open class HopSodium {
        public static let initialized: Bool = {
                _ = sodium_init()
                return true
        }()
        
        public static let PrivateKeySize = 64
        public static let PublicKeySize = 32
        
        public static func genSeedKeyPair(seed:Data)throws -> (Data, Data){
                var pub_data = Data(repeating: 0, count: PublicKeySize)
                var pri_data = Data(repeating: 0, count: PrivateKeySize)
                
                guard let pub_bytes = pub_data.toMutCArray(), let pri_bytes = pri_data.toMutCArray() else{
                        throw HopError.wallet("Parse data to bytes array failed".locStr)
                }
                guard let seed_bytes = seed.toCArray() else{
                        throw HopError.wallet("Parse data to bytes array failed".locStr)
                }
                
                crypto_sign_ed25519_seed_keypair(pub_bytes, pri_bytes, seed_bytes)
                
                return (pub_data, pri_data)
        }
        
        public static func genKeyPair()throws -> (Data, Data){
                var pub_data = Data(repeating: 0, count: PublicKeySize)
                var pri_data = Data(repeating: 0, count: PrivateKeySize)
               
                guard let pub_bytes = pub_data.toMutCArray(), let pri_bytes = pri_data.toMutCArray() else{
                        throw HopError.wallet("Parse data to bytes array failed".locStr)
                }
                crypto_sign_ed25519_keypair(pub_bytes, pri_bytes)
                return (pub_data, pri_data)
        }
        
        public static func seed(size:Int) -> Data{
                var seed_data = Data(repeating: 0, count: size)
                seed_data.withUnsafeMutableBytes { (outputPtr) in
                        randombytes_buf(outputPtr.bindMemory(to: UInt8.self).baseAddress!, size)
                }
                return seed_data
        }
        
        public static func PK25519ED2Curve(edPub:Data)throws -> Data{
                var curvPub = Data(repeating: 0, count: CurveKeySize)
                guard let ed_bytes = edPub.toCArray(), let curv_bytes = curvPub.toMutCArray() else {
                        throw HopError.wallet("Parse data to bytes array failed".locStr)
                }
                
                _ = crypto_sign_ed25519_pk_to_curve25519(curv_bytes, ed_bytes)
                return curvPub
        }
        
        public static func SK25519ED2Curve(edPri:Data)throws -> Data{
                var curvPri = Data(repeating: 0, count: CurveKeySize)
                guard let ed_bytes = edPri.toCArray(), let curv_bytes = curvPri.toMutCArray() else {
                        throw HopError.wallet("Parse data to bytes array failed".locStr)
                }
                
                _ = crypto_sign_ed25519_sk_to_curve25519(curv_bytes, ed_bytes)
                return curvPri
        }
        
        public static func Sign(msg:Data, priKey:Data) throws -> Data{
                var sig = Data(repeating: 0, count: Int(crypto_sign_BYTES))
                guard let sig_bytes = sig.toMutCArray(),
                        let msg_bytes = msg.toCArray(),
                        let pri_bytes = priKey.toCArray() else{
                        throw HopError.wallet("Parse data to bytes array failed".locStr)
                }
                
                crypto_sign_detached(sig_bytes, nil, msg_bytes, UInt64(msg.count), pri_bytes)
                
                return sig
        }
        
        public static func Verify(msg:Data, pubKey:Data, sig:Data) throws -> Bool{
                
                guard let sig_bytes = sig.toCArray(),
                        let msg_bytes = msg.toCArray(),
                        let pub_bytes  = pubKey.toCArray() else{
                                throw HopError.wallet("Parse data to bytes array failed".locStr)
                }
                
                if (crypto_sign_verify_detached(sig_bytes, msg_bytes, UInt64(msg.count), pub_bytes) != 0) {
                   return false
                }
                return true
        }
}
