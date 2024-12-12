//
//  Defaults.swift
//  minip
//
//  Created by ByteDance on 2023/7/14.
//

import Defaults

extension Defaults.Keys {
    static let lastDownloadedURL = Key<String>("lastDownloadedURL", default: "")
    
    // appId，首页app的顺序, 新的app（不在此列表中的）总是在最前
    static let appSortList = Key<[String]>("appSortList", default: [String]())
    
    // app info 缓存
    static let appInfoList = Key<[AppInfo]>("appInfoList", default: [AppInfo]())
    
    // wkwebview inspect
    static let wkwebviewInspectable = Key<Bool>("wkwebviewInspectable", default: false)
}
