//
//  SettingsView.swift
//  minip
//
//  Created by ByteDance on 2023/7/14.
//

import SwiftUI
import WebKit
import PKHUD
import Kingfisher
import AVKit
import Alamofire
import Defaults
import SafariServices

struct SettingsView: View {
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                content
            }
        } else {
            NavigationView {
                content
            }
        }
    }

    @Default(.wkwebviewInspectable) var wkwebviewInspectable
    
    var content: some View {
        List {
            Button {
                PreviewImage(url: URL(string: "https://img0.baidu.com/it/u=1724694977,4042951717&fm=253&fmt=auto&app=120&f=JPEG?w=1280&h=800"))
            } label: {
                Text("preview")
            }
            
            Button {
                let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
                let dateFrom = Date(timeIntervalSince1970: 0)
                WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: dateFrom) {
                    HUD.flash(.labeledSuccess(title: nil, subtitle: "clear success"), delay: 1)
                }
                
            } label: {
                Text("clear wkwebview cache")
            }
            
            Button {
                KingfisherManager.shared.cache.clearDiskCache(completion: {
                    KingfisherManager.shared.cache.clearMemoryCache()
                    HUD.flash(.labeledSuccess(title: nil, subtitle: "clear success"), delay: 1)
                })
            } label: {
                Text("clear kf image cache")
            }
            
            Toggle(isOn: $wkwebviewInspectable, label: {
                Text("Allow inspect wkwebview")
            })

        }
        .navigationTitle(Text("Settings"))
    }
}
