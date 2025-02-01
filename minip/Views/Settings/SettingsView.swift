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
    
    //    @State var wkwebviewInspectable = Defaults[.wkwebviewInspectable]
    @Default(.wkwebviewInspectable) var wkwebviewInspectable
    
    var content: some View {
        List {
            NavigationLink {
                CodeView()
            } label: {
                Text("Playgrounds")
            }
            
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
            
            Button {
                MiniV2Egine.shared.launch()
            } label: {
                Text("miniV2")
            }
            
            Button {
                MiniV2Egine.shared.launch(true)
            } label: {
                Text("miniv2 with webview runtime")
            }
            
            
            NavigationLink {
                TestView()
            } label: {
                Text("TestView")
            }
            
            Toggle(isOn: $wkwebviewInspectable, label: {
                Text("Allow inspect wkwebview")
            })
            
            Button {
//                let vc = HeroNextViewController()
//                vc.hero.isEnabled = true
//                vc.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
//                //                                vc.hero.modalAnimationType = .selectBy(presenting: .cover(direction: .up), dismissing: .uncover(direction: .down))
//                GetTopViewController()?.present(vc, animated: true)
                let vc = UINavigationController(rootViewController: SwipeModalViewController())
                vc.modalPresentationStyle = .overCurrentContext
                
                GetTopViewController()?.present(vc, animated: true)
            } label: {
                Text("Custom swipe back")
            }
            
            Button {
                let svc = SFSafariViewController(url: URL(string: "https://www.baidu.com")!)
                GetTopViewController()?.present(svc, animated: true)
            } label: {
                Text("Safari View")
            }
            
            Button {
                let tabvc = UITabBarController()

                tabvc.viewControllers = [
                    UINavigationController(rootViewController: HomeViewController())
                ]

                tabvc.modalPresentationStyle = .fullScreen
                GetTopViewController()?.present(tabvc, animated: true)
            } label: {
                Text("UIKit app")
            }
        }
        .navigationTitle(Text("Settings"))
    }
}

struct CodeView: View {
    @State var selectedLanguage = 0
    var body: some View {
        ZStack {
            JSCoreTestView()
        }
    }
}
