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
    @Default(.useCapsuleButton) var useCapsuleButton
    
    var content: some View {
        List {
            Button {
                let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
                let dateFrom = Date(timeIntervalSince1970: 0)
                WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: dateFrom) {
                    HUD.flash(.labeledSuccess(title: nil, subtitle: "clear success"), delay: 1)
                }
                
            } label: {
                Text("Clear WebView cache")
            }
            
            Button {
                KingfisherManager.shared.cache.clearDiskCache(completion: {
                    KingfisherManager.shared.cache.clearMemoryCache()
                    HUD.flash(.labeledSuccess(title: nil, subtitle: "clear success"), delay: 1)
                })
            } label: {
                Text("Clear KFImage cache")
            }
            
            Toggle(isOn: $wkwebviewInspectable, label: {
                Text("Allow inspect wkwebview")
            })

            Toggle(isOn: $useCapsuleButton, label: {
                Text("Use capsule button")
            })

        }
        .navigationTitle(Text("Settings"))
    }
}
