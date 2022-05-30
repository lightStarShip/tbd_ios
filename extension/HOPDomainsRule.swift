//
//  HOPRule.swift
//  extension
//
//  Created by hyperorchid on 2020/2/19.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit
import NEKit

class HOPDomainsRule: AllRule {
        
        public let KEY_SUFFIX = "suffix"
        public let KEY_PREFIX = "prefix"
        public let KEY_REGEX = "regex"
        public let KEY_COMPLETE = "complete"
        public let KEY_KEYWORD = "keyword"
        
        public static var ISGlobalMode = false
        
        public enum MatchCriterion {
               case regex(NSRegularExpression), prefix(String), suffix(String), keyword(String), complete(String)

               func match(_ domain: String) -> Bool {
                   switch self {
                   case .regex(let regex):
                       return regex.firstMatch(in: domain, options: [], range: NSRange(location: 0, length: domain.utf8.count)) != nil
                   case .prefix(let prefix):
                       return domain.hasPrefix(prefix)
                   case .suffix(let suffix):
                       return domain.hasSuffix(suffix)
                   case .keyword(let keyword):
                       return domain.contains(keyword)
                   case .complete(let match):
                       return domain == match
                   }
               }
           }
        
        fileprivate let adapterFactory: AdapterFactory
        
        open override var description: String {
            return "<HOPRule>"
        }
        
        open var matchCriteria: [MatchCriterion] = []
        
        public init(adapterFactory: AdapterFactory, urls:[String:NSObject]) {
                self.adapterFactory = adapterFactory
                super.init(adapterFactory: adapterFactory)
                self.matchCriteria = parse(dic:urls)
        }
        
        func parse(dic url_data:[String:NSObject]) -> [MatchCriterion] {
                
                var items:[MatchCriterion] = []
                
                if let regex_arr = url_data[KEY_REGEX] as? [String] {
                        for each in regex_arr{
//                                NSLog("--------->regex===>\(each)")
                                do{
                                        let reg = try NSRegularExpression(pattern: each)
                                        let rule = MatchCriterion.regex(reg)
                                        items.append(rule)
                                }catch let err{
                                        NSLog(err.localizedDescription)
                                }
                        }
                }
                
                if let regex_arr = url_data[KEY_PREFIX] as? [String] {
                        for each in regex_arr{
//                                NSLog("--------->prefix===>\(each)")
                                items.append(MatchCriterion.prefix(each))
                        }
                }
                
                if let regex_arr = url_data[KEY_SUFFIX] as? [String] {
                        for each in regex_arr{
//                                NSLog("--------->suffix===>\(each)")
                                items.append(MatchCriterion.suffix(each))
                        }
                }
                
                if let regex_arr = url_data[KEY_KEYWORD] as? [String] {
                        for each in regex_arr{
//                                NSLog("--------->keyword===>\(each)")
                                items.append(MatchCriterion.keyword(each))
                        }
                }
                
                if let regex_arr = url_data[KEY_COMPLETE] as? [String] {
                        for each in regex_arr{
//                                NSLog("--------->complete===>\(each)")
                                items.append(MatchCriterion.complete(each))
                        }
                }
                return items
        }
        
        override open func matchDNS(_ session: DNSSession, type: DNSSessionMatchType) -> DNSSessionMatchResult {
            if matchDomain(session.requestMessage.queries.first!.name) {
                if let _ = adapterFactory as? DirectAdapterFactory {
                    return .real
                }
                return .fake
            }
            return .pass
        }
        
        override open func match(_ session: ConnectSession) -> AdapterFactory? {
                if HOPDomainsRule.ISGlobalMode {
                        return adapterFactory
                }
                if matchDomain(session.host) {
//                        NSLog("--------->*******[Domain]Hit host:[\(session.host):\(session.port)]")
                        return adapterFactory
                }
//                NSLog("--------->[Domain]By pass host:[\(session.host):\(session.port)]")
                return nil
        }
        
        fileprivate func matchDomain(_ domain: String) -> Bool {
            for criterion in matchCriteria {
                if criterion.match(domain) {
//                        NSLog("--------->match:[\(criterion)]")
                    return true
                }
            }
            return false
        }
}

