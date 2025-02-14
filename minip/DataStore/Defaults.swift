//
//  Defaults.swift
//  minip
//
//  Created by ByteDance on 2023/7/14.
//

import Defaults

extension Defaults.Keys {
    static let lastDownloadedURL = Key<String>("lastDownloadedURL", default: "")
    
    // appId list, HomeViewController app sorted list, new app (not in this list) always in the front
    static let appSortList = Key<[String]>("appSortList", default: [String]())
    
    // app info cache
    static let appInfoList = Key<[AppInfo]>("appInfoList", default: [AppInfo]())
    
    // wkwebview inspect
    static let wkwebviewInspectable = Key<Bool>("wkwebviewInspectable", default: false)
    
    // capsule button
    static let useCapsuleButton = Key<Bool>("useCapsuleButton", default: true)
    
    // first start app
    static let firstStart = Key<Bool>("firstStart", default: true)
}
