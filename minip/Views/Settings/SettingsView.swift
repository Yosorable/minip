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
            
            
            NavigationLink {
                TestView()
            } label: {
                Text("TestView")
            }
            
            Toggle(isOn: $wkwebviewInspectable, label: {
                Text("Allow inspect wkwebview")
            })
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
