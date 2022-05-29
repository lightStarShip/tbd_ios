//
//  VpnManager.swift
//  theBigDipper
//
//  Created by wesley on 2022/5/28.
//

import NetworkExtension

/// Make NEVPNStatus convertible to a string
extension NEVPNStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .invalid: return "Invalid"
        case .connected: return "Connected"
        case .connecting: return "Connecting"
        case .disconnecting: return "Disconnecting"
        case .reasserting: return "Reconnecting"
        @unknown default: return "Unknown"
        }
    }
}

class VpnManager {
        
        public static var shared: NETunnelProviderManager?// = NEVPNManager.shared()
        
        func initManager(){
                
                NETunnelProviderManager.loadAllFromPreferences { managers, err in
                        if let e = err {
                                print("----->>>load preference failed:", e.localizedDescription)
                                return
                        }
                        
                        if let mgn = managers?.first as? NETunnelProviderManager{
                                VpnManager.shared = mgn
                                return
                        }
                        
                        
                        self.initByNewInstance()
                        
                }
        }
        
        private func initByNewInstance(){
                
                let newManager = NETunnelProviderManager()
                newManager.localizedDescription = Consts.AppName
                newManager.isEnabled = true
                
                let tunProtocol = NETunnelProviderProtocol()
                tunProtocol.serverAddress = Consts.ServerAddress
                tunProtocol.providerBundleIdentifier = Consts.AppID
                tunProtocol.disconnectOnSleep = false
                
                newManager.protocolConfiguration = tunProtocol
                
                newManager.saveToPreferences { err in
                        if let e = err{
                                print("----->>>save preference failed:", e.localizedDescription)
                                return
                        }
                        
                        newManager.loadFromPreferences { error in
                                VpnManager.shared = newManager
                        }
                }
                
        }
        
}
