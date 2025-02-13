//
//  SettingsView.swift
//  minip
//
//  Created by ByteDance on 2023/7/14.
//

import SwiftUI
import WebKit
import Kingfisher
import AVKit
import Alamofire
import Defaults
import SafariServices
import ProgressHUD

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
            Section {
                Button {
                    let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
                    let dateFrom = Date(timeIntervalSince1970: 0)
                    WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: dateFrom) {
                        ProgressHUD.succeed("success")
                    }
                    
                } label: {
                    Text("Clear WKWebView cache")
                }
                
                Button {
                    KingfisherManager.shared.cache.clearDiskCache(completion: {
                        KingfisherManager.shared.cache.clearMemoryCache()
                        ProgressHUD.succeed("success")
                    })
                } label: {
                    Text("Clear KFImage cache")
                }
            } header: {
                Text("Cache")
            }
            
            Section {
                Toggle(isOn: $wkwebviewInspectable, label: {
                    Text("Allow inspect WKWebView")
                })
                
                Toggle(isOn: $useCapsuleButton, label: {
                    Text("Use capsule button")
                })
            } header: {
                Text("Preference")
            }
            
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text((Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "Unknown")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text((Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "Unknown")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("About")
            } footer: {
                Text("Documentation and source code: [GitHub - yosorable/minip](https://github.com/yosorable/minip)")
            }
        }
        .navigationTitle(Text("Settings"))
    }
}
