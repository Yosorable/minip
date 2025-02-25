//
//  SettingsView.swift
//  minip
//
//  Created by ByteDance on 2023/7/14.
//

import Alamofire
import AVKit
import Defaults
import Kingfisher
import ProgressHUD
import SafariServices
import SwiftUI
import WebKit

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
            #if DEBUG
            Section {
                Button {
                    MiniAppManager.shared.clearAllPermissions()
                    ShowSimpleSuccess(msg: "Cleared successfully.")
                } label: {
                    Text("Clear All Permissions")
                }
            } header: {
                Text("Debug")
            }
            #endif
            Section {
                Button {
                    let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
                    let dateFrom = Date(timeIntervalSince1970: 0)
                    WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: dateFrom) {
                        ProgressHUD.succeed(i18n("success"))
                    }

                } label: {
                    Text(i18n("s.clear_wkwebview_cache"))
                }

                Button {
                    KingfisherManager.shared.cache.clearDiskCache(completion: {
                        KingfisherManager.shared.cache.clearMemoryCache()
                        ProgressHUD.succeed(i18n("success"))
                    })
                } label: {
                    Text(i18n("s.clear_kfimage_cache"))
                }
            } header: {
                Text("Cache")
            }

            Section {
                Toggle(isOn: $wkwebviewInspectable, label: {
                    Text(i18n("s.allow_inspect_wkwebview"))
                })

                Toggle(isOn: $useCapsuleButton, label: {
                    Text(i18n("s.use_capsule_button"))
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
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                } label: {
                    Text("Licenses")
                }

            } header: {
                Text("About")
            } footer: {
                if #available(iOS 15, *) {
                    Text(try! AttributedString(markdown: i18n("s.documentation_source_code")))
                } else {
                    Text(i18n("s.documentation_source_code"))
                }
            }
        }
        .navigationTitle(Text(i18n("Settings")))
    }
}
