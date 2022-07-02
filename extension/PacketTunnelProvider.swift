//
//  PacketTunnelProvider.swift
//  extension
//
//  Created by hyperorchid on 2020/2/15.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import NetworkExtension
import SwiftyJSON
import Tun2Simple

class PacketTunnelProvider: NEPacketTunnelProvider {
        let httpQueue = DispatchQueue.global(qos: .userInteractive)
        let proxyServerPort :UInt16 = 31080
        let proxyServerAddress = "127.0.0.1";
        
        enum LogLevel:Int8{
                case debug = 0
                case info = 1
                case warn = 2
                case error = 3
        }
        
        var golobal = false
        override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
                NSLog("--------->Tunnel start ......")
                
                guard let ops = options else {
                        completionHandler(NSError.init(domain: "PTP", code: -1, userInfo: nil))
                        NSLog("--------->Options is empty ......")
                        return
                }
                do {
                        try WalletParam.pInst.setup(param: ops)
                        let settings = try initSetting()
                        self.golobal = (ops["GLOBAL_MODE"] as? Bool == true)
                        
                        self.setTunnelNetworkSettings(settings, completionHandler: {
                                error in
                                guard error == nil else{
                                        completionHandler(error)
                                        NSLog("--------->setTunnelNetworkSettings err:\(error!.localizedDescription)")
                                        return
                                }
                                
                                var err:NSError? = nil
                                Tun2SimpleInitEx(self, LogLevel.debug.rawValue, &err)
                                if err != nil{
                                        
                                        completionHandler(err)
                                        return
                                }
                                completionHandler(nil)
                                self.readPackets()
                        })
                        
                }catch let err{
                        completionHandler(err)
                        NSLog("--------->startTunnel failed\n[\(err.localizedDescription)]")
                }
        }
        func initSetting()throws -> NEPacketTunnelNetworkSettings {
                
                let networkSettings = NEPacketTunnelNetworkSettings.init(tunnelRemoteAddress: proxyServerAddress)
                networkSettings.mtu = NSNumber.init(value: 1500)
                
                let dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "1.1.1.1"])
                dnsSettings.matchDomains = [""]
                networkSettings.dnsSettings = dnsSettings
                
                let ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.8"], subnetMasks: ["255.255.255.0"])
                ipv4Settings.includedRoutes = [NEIPv4Route.default()]
                ipv4Settings.excludedRoutes = [
                        NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
                        NEIPv4Route(destinationAddress: "100.64.0.0", subnetMask: "255.192.0.0"),
                        NEIPv4Route(destinationAddress: "127.0.0.0", subnetMask: "255.0.0.0"),
                        NEIPv4Route(destinationAddress: "169.254.0.0", subnetMask: "255.255.0.0"),
                        NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0"),
                        NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
                        NEIPv4Route(destinationAddress: "17.0.0.0", subnetMask: "255.0.0.0"),
                ]
                networkSettings.ipv4Settings = ipv4Settings;
                return networkSettings
        }
        
        override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
                NSLog("--------->Tunnel stopping......")
                completionHandler()
        }
        
        override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
                NSLog("--------->Handle App Message......")
                
                let param = JSON(messageData)
                
                let is_global = param["Global"].bool
                if is_global != nil{
                        self.golobal = is_global!
                        NSLog("--------->Global model changed...\(self.golobal)...")
                }
                
                let gt_status = param["GetModel"].bool
                if gt_status != nil{
                        guard let data = try? JSON(["Global": self.golobal]).rawData() else{
                                return
                        }
                        NSLog("--------->App is querying golbal model [\(self.golobal)]")
                        
                        guard let handler = completionHandler else{
                                return
                        }
                        handler(data)
                }
        }
        
        override func sleep(completionHandler: @escaping () -> Void) {
                NSLog("-------->sleep......")
                completionHandler()
        }
        
        override func wake() {
                NSLog("-------->wake......")
        }
}

extension PacketTunnelProvider:Tun2SimpleExtensionIProtocol{
        
        func address() -> String {
                return WalletParam.pInst.selfAddr
        }
        
        func aesKey() -> Data? {
                return WalletParam.pInst.aesKey
        }
        
        func minerNetAddr() -> String {
                return WalletParam.pInst.minerNetAddr
        }
        
        func protect(_ fd: Int32) -> Bool {
                return true
        }
        
        func tunClosed() throws {
                self.exit()
        }
        
        
        func loadRule() -> String {
                guard let filepath = Bundle.main.path(forResource: "rule", ofType: "txt") else{
                        NSLog("------>>>failed to find path")
                        return ""
                }
                guard let contents = try? String(contentsOfFile: filepath) else{
                        NSLog("------>>>failed to read rule txt")
                        return ""
                }
                //                NSLog("------>>>rule contents:\(contents)")
                return contents
        }
        
        func write(toTun p0: Data?, n: UnsafeMutablePointer<Int>?) throws {
                guard let d = p0 else{
                        NSLog("-------->output data to tun dev is nil......")
                        //                        self.exit()
                        return
                }
                //                NSLog("------>>>prepare to write back to tun written:[\(d)]")
                
                let packet = NEPacket(data: d, protocolFamily: sa_family_t(AF_INET))
                packetFlow.writePacketObjects([packet])
        }
        
        func log(_ s: String?) {
                guard let log = s else{
                        return
                }
                NSLog("-------->\(log)")
        }
        
        private func exit(){
                NSLog("-------->exit......")
                Darwin.exit(EXIT_SUCCESS)
        }
        
        private func readPackets() {
                //                NSLog("--------->start to read packets......")
                packetFlow.readPacketObjects { packets in
                        var no:Int = 0
                        for p in packets{
                                var err:NSError? = nil
                                Tun2SimpleWritePackets(p.data, &no, &err)
                                if let e = err{
                                        NSLog("-------->Tun2SimpleInputDevData err[\(e.localizedDescription)]......")
                                        return
                                }
                        }
                        self.readPackets()
                }
        }
}
