//
//  PacketTunnelProvider.swift
//  extension
//
//  Created by hyperorchid on 2020/2/15.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import NetworkExtension
import SwiftyJSON

class PacketTunnelProvider: NEPacketTunnelProvider {
        let httpQueue = DispatchQueue.global(qos: .userInteractive)
        let proxyServerPort :UInt16 = 31080
        let proxyServerAddress = "127.0.0.1";
        
//        var pendingStartCompletion: ((Error?) -> Void)?
        
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
                        
                        self.setTunnelNetworkSettings(settings, completionHandler: {
                                error in
                                guard error == nil else{
                                        completionHandler(error)
                                        NSLog("--------->setTunnelNetworkSettings err:\(error!.localizedDescription)")
                                        return
                                }
                               
                                completionHandler(nil)
                        })
                        
                }catch let err{
                        completionHandler(err)
                        NSLog("--------->startTunnel failed\n[\(err.localizedDescription)]")
                }
        }
        func initSetting()throws -> NEPacketTunnelNetworkSettings {
                
                let networkSettings = NEPacketTunnelNetworkSettings.init(tunnelRemoteAddress: proxyServerAddress)
                networkSettings.mtu = NSNumber.init(value: 1500)
//                networkSettings.tunnelOverheadBytes = 150
                
//                let proxySettings = NEProxySettings()
//                proxySettings.autoProxyConfigurationEnabled = true
//                proxySettings.proxyAutoConfigurationJavaScript = Utils.JavaScriptString
//                proxySettings.matchDomains=[""]
//                networkSettings.proxySettings = proxySettings;
                
                let dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "1.1.1.1"])
//                let dnsSettings = NEDNSOverHTTPSSettings(servers: ["8.8.8.8", "1.1.1.1"])
//                let dnsSettings = NEDNSOverHTTPSSettings(servers: ["223.5.5.5","223.6.6.6","2400:3200:baba::1","2400:3200::1"])
//                dnsSettings.serverURL = URL(string: "https://dns.google/dns-query")
                dnsSettings.matchDomains = [""]
                networkSettings.dnsSettings = dnsSettings
                
                let ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.8"], subnetMasks: ["255.255.255.0"])
                ipv4Settings.includedRoutes = [.default()]
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



//                proxySettings.httpEnabled = true;
//                proxySettings.httpServer = NEProxyServer.init(address: proxyServerAddress, port: Int(proxyServerPort))
//                proxySettings.httpsEnabled = true;
//                proxySettings.httpsServer = NEProxyServer.init(address: proxyServerAddress, port: Int(proxyServerPort))

//                        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
//                ipv4Settings.excludedRoutes = [
//                        NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
//                        NEIPv4Route(destinationAddress: "100.64.0.0", subnetMask: "255.192.0.0"),
//                        NEIPv4Route(destinationAddress: "127.0.0.0", subnetMask: "255.0.0.0"),
//                        NEIPv4Route(destinationAddress: "169.254.0.0", subnetMask: "255.255.0.0"),
//                        NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0"),
//                        NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
//                        NEIPv4Route(destinationAddress: "17.0.0.0", subnetMask: "255.0.0.0"),
//                    ]
//

//                let ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.8"], subnetMasks: ["255.255.255.0"])
//                var includedRoutes = [NEIPv4Route]()
//                includedRoutes.append(NEIPv4Route(destinationAddress: "74.125.0.0", subnetMask: "255.255.0.0"))
//                ipv4Settings.includedRoutes = includedRoutes
//
//                networkSettings.ipv4Settings = ipv4Settings;

/*
 
 64.18.0.0/20
 64.233.160.0/19
 66.102.0.0/20
 66.249.80.0/20
 72.14.192.0/18
 74.125.0.0/16
 173.194.0.0/16
 207.126.144.0/20
 209.85.128.0/17
 216.58.208.0/20
 216.239.32.0/19
 
 */
