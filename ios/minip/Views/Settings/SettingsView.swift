//
//  SettingsView.swift
//  minip
//
//  Created by ByteDance on 2023/7/14.
//

import AVKit
import Alamofire
import Defaults
import Kingfisher
import ProgressHUD
import SafariServices
import SwiftUI
import WebKit

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

private struct LicensesView: View {
    private static let libraries: [(String, String)] = [
        ("Alamofire", "https://github.com/Alamofire/Alamofire/blob/master/LICENSE"),
        ("BlurUIKit", "https://github.com/TimOliver/BlurUIKit/blob/main/LICENSE"),
        ("CLMDB", "https://github.com/agisboye/CLMDB"),
        ("Defaults", "https://github.com/sindresorhus/Defaults/blob/main/license"),
        ("FlyingFox", "https://github.com/swhitty/FlyingFox/blob/main/LICENSE"),
        ("JetBrains Mono", "https://github.com/JetBrains/JetBrainsMono/blob/master/OFL.txt"),
        ("KeyboardToolbar", "https://github.com/simonbs/KeyboardToolbar/blob/main/LICENSE"),
        ("Kingfisher", "https://github.com/onevcat/Kingfisher/blob/master/LICENSE"),
        ("PanModal", "https://github.com/Yosorable/PanModal/blob/master/LICENSE"),
        ("ProgressHUD", "https://github.com/Yosorable/ProgressHUD/blob/master/LICENSE"),
        ("Runestone", "https://github.com/simonbs/Runestone/blob/main/LICENSE"),
        ("SwiftLMDB", "https://github.com/agisboye/SwiftLMDB/blob/master/LICENSE"),
        ("tree-sitter", "https://github.com/tree-sitter/tree-sitter/blob/master/LICENSE"),
        ("TreeSitterLanguages", "https://github.com/simonbs/TreeSitterLanguages/blob/main/LICENSE"),
        ("ZIPFoundation", "https://github.com/weichsel/ZIPFoundation/blob/development/LICENSE"),
    ]

    @State private var safariURL: URL?

    var body: some View {
        List {
            ForEach(Self.libraries, id: \.0) { name, urlString in
                Button {
                    safariURL = URL(string: urlString)
                } label: {
                    HStack {
                        Text(name)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
            }
        }
        .navigationTitle("Licenses")
        .sheet(
            item: Binding(
                get: { safariURL.map { IdentifiableURL(url: $0) } },
                set: { safariURL = $0?.url }
            )
        ) { item in
            SafariView(url: item.url)
                .ignoresSafeArea()
        }
    }
}

private struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

private struct SettingsIcon: View {
    let systemName: String
    let color: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(color)
            )
    }
}

struct SettingsView: View {
    @Default(.wkwebviewInspectable) var wkwebviewInspectable
    @Default(.useCapsuleButton) var useCapsuleButton
    @Default(.colorScheme) var colorScheme
    @Default(.useSanboxRoot) var useSandboxRoot

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if #unavailable(iOS 26.0) {
                        Toggle(
                            isOn: $useCapsuleButton,
                            label: {
                                Label {
                                    Text(i18n("s.use_capsule_button"))
                                } icon: {
                                    SettingsIcon(systemName: "capsule.fill", color: .blue)
                                }
                            })
                    }

                    Picker(selection: $colorScheme) {
                        Text("Follow System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    } label: {
                        Label {
                            Text("Appearance")
                        } icon: {
                            SettingsIcon(systemName: "circle.lefthalf.filled", color: .purple)
                        }
                    }
                    .onChange(
                        of: colorScheme,
                        perform: { val in
                            let del = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.delegate as? SceneDelegate
                            del?.window?.overrideUserInterfaceStyle = if val == 1 { .light } else if val == 2 { .dark } else { .unspecified }
                        })

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label {
                            HStack {
                                Text("Language")
                                Spacer()
                                Text(Locale.current.localizedString(forIdentifier: Locale.current.identifier)?.capitalized ?? "")
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                        } icon: {
                            SettingsIcon(systemName: "globe", color: .green)
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("Preferences")
                }

                Section {
                    Button {
                        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
                        let dateFrom = Date(timeIntervalSince1970: 0)
                        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: dateFrom) {
                            ProgressHUD.succeed(i18n("success"))
                        }
                    } label: {
                        Label {
                            Text(i18n("s.clear_wkwebview_cache"))
                        } icon: {
                            SettingsIcon(systemName: "safari.fill", color: .blue)
                        }
                    }

                    Button {
                        KingfisherManager.shared.cache.clearDiskCache(completion: {
                            KingfisherManager.shared.cache.clearMemoryCache()
                            ProgressHUD.succeed(i18n("success"))
                        })
                    } label: {
                        Label {
                            Text(i18n("s.clear_kfimage_cache"))
                        } icon: {
                            SettingsIcon(systemName: "photo.fill", color: .orange)
                        }
                    }
                } header: {
                    Text("Cache")
                }

                Section {
                    Toggle(
                        isOn: $wkwebviewInspectable,
                        label: {
                            Label {
                                Text("Allow Inspecting WKWebView")
                            } icon: {
                                SettingsIcon(systemName: "ladybug.fill", color: .red)
                            }
                        })

                    Toggle(
                        isOn: $useSandboxRoot,
                        label: {
                            Label {
                                Text("Use Sandbox Root for File Browser")
                            } icon: {
                                SettingsIcon(systemName: "folder.fill", color: .blue)
                            }
                        }
                    ).onChange(of: useSandboxRoot) { newVal in
                        Global.shared.fileBrowserRootURL = newVal ? Global.shared.sandboxRootURL : Global.shared.documentsRootURL
                        guard let scene = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else { return }
                        scene.updateFileBrowserRoot()
                    }

                    Button {
                        MiniAppManager.shared.clearAllPermissions()
                        showSimpleSuccess(msg: "Cleared successfully.")
                    } label: {
                        Label {
                            Text("Remove All Permissions")
                        } icon: {
                            SettingsIcon(systemName: "lock.shield.fill", color: .gray)
                        }
                    }
                } header: {
                    Text("Advanced")
                }

                Section {
                    Label {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text((Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "Unknown")
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        SettingsIcon(systemName: "info.circle.fill", color: .blue)
                    }
                    Label {
                        HStack {
                            Text("Build")
                            Spacer()
                            Text((Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "Unknown")
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        SettingsIcon(systemName: "hammer.fill", color: .gray)
                    }
                    NavigationLink {
                        LicensesView()
                    } label: {
                        Label {
                            Text("Licenses")
                        } icon: {
                            SettingsIcon(systemName: "doc.text.fill", color: .gray)
                        }
                    }

                } header: {
                    Text("About")
                } footer: {
                    Text(try! AttributedString(markdown: i18n("s.documentation_source_code")))
                }
            }
            .navigationTitle(Text(i18n("Settings")))
        }
    }
}
