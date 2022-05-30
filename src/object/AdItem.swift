//
//  AdItem.swift
//  SimpleVPN
//
//  Created by wesley on 2022/5/19.
//  Copyright © 2022 hyperorchid. All rights reserved.
//

import Foundation
import SwiftyJSON
import Starship

class AdItem : NSObject {
        
        var typ:Int = 0
        var imgUrl:String = ""
        var linkUrl:String = ""
        
        
        init(json:JSON){
                super.init()
                
                self.typ = json["typ"].intValue
                self.imgUrl = json["img_url"].stringValue
                self.linkUrl = json["link_url"].stringValue
        }
        
        public static func LoadAdItems()->[AdItem]{
                guard let cache_data = AppSetting.getAdData() else{
                        return LoadAdListFromBlockChain()
                }
                
                return parseDataToArray(data: cache_data)
        }
        
        private static func LoadAdListFromBlockChain()->[AdItem]{
                guard let adData = IosLibAdvertiseList() else{
                        print("------>>>no valid ad data on chain")
                        return []
                }
                return parseDataToArray(data: adData)
        }
        
        private static func parseDataToArray(data:Data)->[AdItem]{
                
                        var AdCache:[AdItem] = []
                
                guard let json = try? JSON(data: data) else{
                        print("------>>>invalid json data for ad list from chain")
                        return AdCache
                }
                
                for (_, jsonObj):(String, JSON) in json {
                        let item = AdItem.init(json: jsonObj)
                        AdCache.append(item)
                }
                
                AppSetting.updateAdData(data: data)
                
                return AdCache
        }
}
