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
    @Default(.colorScheme) var colorScheme
    @Default(.useSanboxRoot) var useSandboxRoot

    var content: some View {
        List {
            Section {
                Toggle(isOn: $useCapsuleButton, label: {
                    Text(i18n("s.use_capsule_button"))
                })

                Picker("Appearance", selection: $colorScheme) {
                    Text("Follow System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .onChange(of: colorScheme, perform: { val in
                    let del = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.delegate as? SceneDelegate
                    del?.window?.overrideUserInterfaceStyle = if val == 1 { .light } else if val == 2 { .dark } else { .unspecified }
                })
            } header: {
                Text("Preference")
            }

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

                Toggle(isOn: $useSandboxRoot, label: {
                    Text("Use Sandbox Root for File Browser")
                }).onChange(of: useSandboxRoot) { newVal in
                    Global.shared.fileBrowserRootURL = newVal ? Global.shared.sandboxRootURL : Global.shared.documentsRootURL
                    guard let scene = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else { return }
                    scene.updateFileBrowserRoot()
                }

                Button {
                    MiniAppManager.shared.clearAllPermissions()
                    ShowSimpleSuccess(msg: "Cleared successfully.")
                } label: {
                    Text("Remove All Permissions")
                }
            } header: {
                Text("Advance")
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
