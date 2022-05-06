//
//  PacketTunnelProvider.swift
//  extension
//
//  Created by hyperorchid on 2020/2/15.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import NetworkExtension
import NEKit
import SwiftyJSON

extension Data {
    var hexString: String {
        return self.reduce("", { $0 + String(format: "%02x", $1) })
    }
}

class PacketTunnelProvider: NEPacketTunnelProvider {
        let httpQueue = DispatchQueue.global(qos: .userInteractive)
        var proxyServer: ProxyServer!
        let proxyServerPort :UInt16 = 41080
        let proxyServerAddress = "127.0.0.1";
        var enablePacketProcessing = false
        var interface: TUNInterface!
        
        override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
                NSLog("--------->Tunnel start ......")
                
                if proxyServer != nil {
                        proxyServer.stop()
                        proxyServer = nil
                }
                
                guard let ops = options else {
                        completionHandler(NSError.init(domain: "PTP", code: -1, userInfo: nil))
                        NSLog("--------->Options is empty ......")
                        return
                }

                do {
                        try Protocol.pInst.setup(param: ops, delegate: self)
                        
                        try Utils.initDomains()
                        
                        self.enablePacketProcessing = ops["STREAM_MODE"] as? Bool ?? false
                        
                        let settings = try initSetting(minerID: ops["MINER_ADDR"] as! String)
                        
                        HOPDomainsRule.ISGlobalMode = (ops["GLOBAL_MODE"] as? Bool == true)
                        
                        self.setTunnelNetworkSettings(settings, completionHandler: {
                                error in
                                guard error == nil else{
                                        completionHandler(error)
                                        NSLog("--------->setTunnelNetworkSettings err:\(error!.localizedDescription)")
                                        return
                                }
                                
                                
                                self.proxyServer = GCDHTTPProxyServer.init(address: IPAddress(fromString: self.proxyServerAddress), port: Port(port: self.proxyServerPort))
                                
                                do {try self.proxyServer.start()}catch let err{
                                        completionHandler(err)
                                        NSLog("--------->Proxy start err:\(err.localizedDescription)")
                                        return
                                }
                                
                                NSLog("--------->Proxy server started......")
                                completionHandler(nil)
                                
                                NSLog("--------->Packet process 111 status[\(self.enablePacketProcessing)]......")
                                if (self.enablePacketProcessing){
                                        self.interface = TUNInterface(packetFlow: self.packetFlow)
                                        
                                        let fakeIPPool = try! IPPool(range: IPRange(startIP: IPAddress(fromString: "198.18.1.1")!, endIP: IPAddress(fromString: "198.18.255.255")!))
                                        
                                        
                                        let dnsServer = DNSServer(address: IPAddress(fromString: "198.18.0.1")!, port: NEKit.Port(port: 53), fakeIPPool: fakeIPPool)
                                        let resolver = UDPDNSResolver(address: IPAddress(fromString: "8.8.8.8")!, port: NEKit.Port(port: 53))
                                        dnsServer.registerResolver(resolver)
                                        self.interface.register(stack: dnsServer)
                                        
                                        DNSServer.currentServer = dnsServer
                                        
                                        let udpStack = UDPDirectStack()
                                        self.interface.register(stack: udpStack)
                                        
                                        let tcpStack = TCPStack.stack
                                        tcpStack.proxyServer = self.proxyServer
                                        self.interface.register(stack:tcpStack)
                                        self.interface.start()
                                }
                        })
                        
                }catch let err{
                       completionHandler(err)
                       NSLog("--------->startTunnel failed\n[\(err.localizedDescription)]")
               }
        }
        
        func initSetting(minerID:String)throws -> NEPacketTunnelNetworkSettings {
                
                let networkSettings = NEPacketTunnelNetworkSettings.init(tunnelRemoteAddress: proxyServerAddress)
                let ipv4Settings = NEIPv4Settings.init(addresses: ["10.0.0.8"], subnetMasks: ["255.255.255.0"])
                NSLog("--------->Packet process 2222 status[\(self.enablePacketProcessing)]......")
                if enablePacketProcessing {
                    ipv4Settings.includedRoutes = [NEIPv4Route.default()]
                    ipv4Settings.excludedRoutes = [
                        NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
                        NEIPv4Route(destinationAddress: "100.64.0.0", subnetMask: "255.192.0.0"),
                        NEIPv4Route(destinationAddress: "127.0.0.0", subnetMask: "255.0.0.0"),
                        NEIPv4Route(destinationAddress: "169.254.0.0", subnetMask: "255.255.0.0"),
                        NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0"),
                        NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
                        NEIPv4Route(destinationAddress: "17.0.0.0", subnetMask: "255.0.0.0"),
                        NEIPv4Route(destinationAddress: HopConstants.DefaultDnsIP, subnetMask: "255.255.255.255"),
                    ]
                }
                
                networkSettings.ipv4Settings = ipv4Settings;
                networkSettings.mtu = NSNumber.init(value: 1500)

                let proxySettings = NEProxySettings.init()
                proxySettings.httpEnabled = true;
                proxySettings.httpServer = NEProxyServer.init(address: proxyServerAddress, port: Int(proxyServerPort))
                proxySettings.httpsEnabled = true;
                proxySettings.httpsServer = NEProxyServer.init(address: proxyServerAddress, port: Int(proxyServerPort))
                proxySettings.excludeSimpleHostnames = true;
                proxySettings.matchDomains = [""]
                proxySettings.exceptionList = Utils.Exclusives
//                NSLog("--------->exclude->\(proxySettings.exceptionList!)")
                if enablePacketProcessing {
                        let DNSSettings = NEDNSSettings(servers: ["198.18.0.1"])
                        DNSSettings.matchDomains = [""]
                        DNSSettings.matchDomainsNoSearch = false
                        networkSettings.dnsSettings = DNSSettings
                }
                

                networkSettings.proxySettings = proxySettings;
                RawSocketFactory.TunnelProvider = self
                
                guard let hopAdapterFactory = HOPAdapterFactory(miner:minerID) else{
                        throw HopError.minerErr("--------->Initial miner data failed")
                }
                
                let hopRule = HOPDomainsRule(adapterFactory: hopAdapterFactory, urls: Utils.Domains)
                
                var ipStrings:[String] = []
                ipStrings.append(contentsOf: Utils.IPRange["line"] as! [String])
                ipStrings.append(contentsOf: Utils.IPRange["tel"] as! [String])
                ipStrings.append(contentsOf: Utils.IPRange["whatsapp"] as! [String])
                ipStrings.append(contentsOf: Utils.IPRange["snap"] as! [String])
                ipStrings.append(contentsOf: Utils.IPRange["netfix"] as! [String])
                let ipRange = try HOPIPRangeRule(adapterFactory: hopAdapterFactory, ranges: ipStrings)
//                NSLog("--------->\(ipStrings)")
                RuleManager.currentManager = RuleManager(fromRules: [hopRule, ipRange], appendDirect: true)
                return networkSettings
        }

        override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
                NSLog("--------->Tunnel stopping......")
                completionHandler()
                self.exit()
        }

        override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
                NSLog("--------->Handle App Message......")
                
                let param = JSON(messageData)
                
                let is_global = param["Global"].bool
                if is_global != nil{
                        HOPDomainsRule.ISGlobalMode = is_global!
                        NSLog("--------->Global model changed...\(HOPDomainsRule.ISGlobalMode)...")
                }
            
                let gt_status = param["GetModel"].bool
                if gt_status != nil{
                        guard let data = try? JSON(["Global": HOPDomainsRule.ISGlobalMode]).rawData() else{
                                return
                        }
                        NSLog("--------->App is querying golbal model [\(HOPDomainsRule.ISGlobalMode)]")
                    
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


extension PacketTunnelProvider: ProtocolDelegate{
        
        private func exit(){
                NSLog("--------->Packet process 3333 status[\(self.enablePacketProcessing)]......")
                if enablePacketProcessing {
                    interface.stop()
                    interface = nil
                    DNSServer.currentServer = nil

                }
                RawSocketFactory.TunnelProvider = nil
                proxyServer.stop()
                proxyServer = nil
                Darwin.exit(EXIT_SUCCESS)
        }
        
        func VPNShouldDone() {
                self.exit()
        }
}
