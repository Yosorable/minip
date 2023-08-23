//
//  minipApp.swift
//  minip
//
//  Created by LZY on 2022/7/24.
//

import SwiftUI

@main
struct minipApp: App {
    init() {
    }
    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Projects", systemImage: "shippingbox")
                    }
                FileBrowserView()
                    .tabItem {
                        Label("Files", systemImage: "folder")
                    }
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }

            }
        }
    }
}
