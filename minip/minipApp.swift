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
        //        if #available(iOS 15.0, *) {
        //            let navigationBarAppearance = UINavigationBarAppearance()
        //            navigationBarAppearance.configureWithDefaultBackground()
        //            UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        //            UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        //            UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        //
        //
        //            let tabBarAppearance = UITabBarAppearance()
        //            tabBarAppearance.configureWithDefaultBackground()
        //            UITabBar.appearance().standardAppearance = tabBarAppearance
        //            UITabBar.appearance().scrollEdgeAppearance = UITabBar.appearance().standardAppearance
        //        }
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
