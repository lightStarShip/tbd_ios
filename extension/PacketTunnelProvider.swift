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
        
        var tunIF:Tun2SimpleTunnelProtocol?
        
        var golobal = false
        override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
                NSLog("--------->Tunnel start ......")
                
                guard let ops = options else {
                        completionHandler(NSError.init(domain: "PTP", code: -1, userInfo: nil))
                        NSLog("--------->Options is empty ......")
                        return
                }
                do {
                        try ApiService.pInst.setup(param: ops)
                        let settings = try initSetting()
                        self.golobal = (ops["GLOBAL_MODE"] as? Bool == true)
                        var err:NSError? = nil
                        
                        if let e = err{
                                completionHandler(e)
                                NSLog("--------->startTunnel failed\n[\(e.localizedDescription)]")
                                return
                        }
                        self.setTunnelNetworkSettings(settings, completionHandler: {
                                error in
                                guard error == nil else{
                                        completionHandler(error)
                                        NSLog("--------->setTunnelNetworkSettings err:\(error!.localizedDescription)")
                                        return
                                }
                                completionHandler(nil)
                                self.tunIF = Tun2SimpleNewTunnel(self, &err)
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

extension PacketTunnelProvider:Tun2SimpleTunnelDevProtocol{
        func close() throws {
//                self.exit()
        }
        
        func write(_ p0: Data?, n: UnsafeMutablePointer<Int>?) throws {
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
                                do {
                                        try self.tunIF?.write(p.data, ret0_: &no)
//                                        NSLog("------>>>data written:[\(no)]")
                                } catch let err{
                                        NSLog("-------->Tun2SimpleInputDevData err[\(err.localizedDescription)]......")
                                        return
                                }
                        }
                        self.readPackets()
                }
        }
}
