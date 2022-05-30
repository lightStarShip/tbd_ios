//
//  AdvertiseView.swift
//  TBD
//
//  Created by wesley on 2022/5/18.
//  Copyright © 2022 lightStarShip. All rights reserved.
//

import UIKit


class AdvertiseView: UIView {
        
        @IBOutlet weak var adImge: UIImageView!
        public var item:AdItem?
        
        /*
         // Only override draw() if you perform custom drawing.
         // An empty implementation adversely affects performance during animation.
         override func draw(_ rect: CGRect) {
         // Drawing code
         }
         */
       
        
        public static func initItemVew(item:AdItem) ->AdvertiseView{
                let view:AdvertiseView = Bundle.main.loadNibNamed("AdvertiseView", owner: self, options: nil)?.first as! AdvertiseView
                view.item = item
                guard let url = URL(string: item.imgUrl)  else{
                        return view
                }
                
                guard let data = try? Data.init(contentsOf: url) else{
                        return view
                }
                
                view.adImge.image = UIImage(data: data)
                view.adImge.contentMode = .scaleAspectFit
                view.adImge.isUserInteractionEnabled = true
                view.adImge.layer.cornerRadius = 16
                return view
        }
        
        public static func initAdViews()->[AdvertiseView]{
                var ads:[AdvertiseView] = []
                let AdCache = AdItem.LoadAdItems()
                for ad in AdCache{
                        ads.append(AdvertiseView.initItemVew(item: ad))
                }
                return ads
        }
}
