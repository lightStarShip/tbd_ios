//
//  Utils.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/19.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class Utils: NSObject {
        
        public static var Domains:[String:NSObject] = [:]
        public static var IPRange:[String:NSObject] = [:]
        public static var Exclusives:[String] = []
        public static var JavaScriptString = ""
        private override init() {
                super.init()
        }
        
        static func initDomains() throws{
                guard let url = Bundle.main.path(forResource: "gfw", ofType: "plist") else{
                        throw HopError.hopProtocol("no gfw file")
                }
                
                guard let dic = NSDictionary(contentsOfFile: url) as? [String:NSObject],
                      //                      let cnDic = dic["TEST"] as? [String:NSObject] else{
                      let cnDic = dic["CN"] as? [String:NSObject] else{
                        throw HopError.hopProtocol("gfw file ")
                }
                
                guard let domains = cnDic["domains"] as? [String : NSObject] else{
                        throw HopError.hopProtocol("invalid domain names")
                }
                guard let ips = cnDic["iprange"] as? [String : NSObject] else{
                        throw HopError.hopProtocol("invalid ip ranges")
                }
                
                guard let ex = cnDic["exclude"] as? [String] else{
                        throw HopError.hopProtocol("invalid exclusive domains")
                }
                
                Utils.Exclusives = ex
                Utils.Domains = domains
                Utils.IPRange = ips
                
                
        } 
        static func initJavaScript() throws{
                guard let jsUrl = Bundle.main.path(forResource: "gfw", ofType: "js") else{
                        throw HopError.hopProtocol("no gfw js")
                }
                
                let jsStr = try String.init(contentsOfFile: jsUrl)
                
                JavaScriptString = jsStr
        }
        static func getJavascriptProxyForRules (domains:Array<String>, address:String, port:String) -> String {
                
                if domains.count == 0 {
                        return "function FindProxyForURL(url, host) { return \"DIRECT\";}"
                }
                else {
                        
                        //forced URLs to go through VPN (right now just IP address to show to user)
                        let forcedVPNConditions = "dnsDomainIs(host, \"ip.confirmedvpn.com\")"
                        
                        var conditions = ""
                        for (index, domain) in domains.enumerated() {
                                if index > 0 {
                                        conditions = conditions + " || "
                                }
                                let formattedDomain = domain.replacingOccurrences(of: "*.", with: "")
                                NSLog("formattedDomain=\(formattedDomain)")
                                conditions = conditions + "dnsDomainIs(host, \"" + formattedDomain + "\")"
                        }
                        
                        return "function FindProxyForURL(url, host) { if (\(forcedVPNConditions)) { return \"DIRECT\";} else if (\(conditions)) { return \"PROXY \(address):\(port); DIRECT\"; } return \"DIRECT\";}"
                }
        }
        
        static func generateQRCode(from message: String) -> CIImage? {
                
                guard let data = message.data(using: .utf8) else{
                        return nil
                }
                
                guard let qr = CIFilter(name: "CIQRCodeGenerator",
                                        parameters: ["inputMessage":
                                                        data, "inputCorrectionLevel":"H"]) else{
                        return nil
                }
                
                let qrImage = qr.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
                return qrImage
        }
}

public func PostNoti(_ namedNoti:Notification){
        NotificationCenter.default.post(namedNoti)
}

public func PostNoti(_ namedNoti:Notification.Name, data:String?){
        NotificationCenter.default.post(name: namedNoti, object: nil, userInfo: ["data":data ?? ""])
}

extension Data{
        
        public func ToInt() -> Int{
                let b = self.bytes
                let len = Int(b[3]) | Int(b[2])<<8 | Int(b[1])<<16 | Int(b[0])<<24
                return len
        }
}

public func DataWithLen(data:Data) -> Data {
        let data_len = Int32(data.count)
        let len_data = withUnsafeBytes(of: data_len.bigEndian, Array.init)
        var lv_data = Data(len_data)
        lv_data.append(data)
        return lv_data
}

extension Formatter {
        static let date = DateFormatter()
}

extension Date {
        var stringVal : String {
                Formatter.date.calendar = Calendar(identifier: .iso8601)
                Formatter.date.timeZone = .current
                Formatter.date.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSZZZZZ"
                return Formatter.date.string(from: self)
        }
}


extension String {
        var locStr:String {
                return NSLocalizedString(self, comment: "")
        }
        
        func isValidIP() -> Bool {
                let parts = self.split(separator: ".")// .componentsSeparatedByString(".")
                let nums = parts.compactMap { Int($0) }
                return parts.count == 4 && nums.count == 4 && nums.filter { $0 >= 0 && $0 < 256}.count == 4
        }
}

extension UIColor {
        public convenience init?(hex: String) {
                let r, g, b, a: CGFloat
                
                if hex.hasPrefix("#") {
                        let start = hex.index(hex.startIndex, offsetBy: 1)
                        let hexColor = String(hex[start...])
                        
                        if hexColor.count == 8 {
                                let scanner = Scanner(string: hexColor)
                                var hexNumber: UInt64 = 0
                                
                                if scanner.scanHexInt64(&hexNumber) {
                                        r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                                        g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                                        b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                                        a = CGFloat(hexNumber & 0x000000ff) / 255
                                        
                                        self.init(red: r, green: g, blue: b, alpha: a)
                                        return
                                }
                        }
                }
                
                return nil
        }
}
