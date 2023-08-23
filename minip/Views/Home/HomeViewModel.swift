//
//  HomeViewController.swift
//  minip
//
//  Created by ByteDance on 2023/7/3.
//

import Foundation
import Defaults

class HomeViewModel: ObservableObject {
    @Published var apps: [AppInfo] = []
    
    @Published var selectedApp: AppInfo?
    @Published var deleteApp: AppInfo?
    @Published var showDeleteAlert = false
    
    init() {
        Task {
            loadAppInfos()
        }
    }
    
    
    func loadAppInfos() {
        print("read file")
        var tmpApps: [AppInfo] = []
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let decoder = JSONDecoder()
            fileURLs.forEach { ele in
                let infoURL = ele.appendingPathComponent("info", conformingTo: .json)
                if ele.lastPathComponent != ".Trash" && fileManager.fileExists(atPath: infoURL.path(percentEncoded: false)) {
                    do {
                        let data = try Data(contentsOf: infoURL, options: .mappedIfSafe)
                        let appDetail = try? decoder.decode(AppInfo.self, from: data)
                        if let ad = appDetail {
                            tmpApps.append(ad)
                        }
                    } catch let error {
                        print("\(error.localizedDescription)")
                    }
                }
            }
            if tmpApps.count == 0 {
                try fileManager.createDirectory(at: documentsURL.appendingPathComponent("test"), withIntermediateDirectories: false)
            }
        } catch let error {
            print("\(error.localizedDescription)")
        }
        
        var appIdSortListIndexMap = [String:Int]()
        let appIdSortList = Defaults[.appSortList]
        
        for i in 0..<appIdSortList.count {
            appIdSortListIndexMap[appIdSortList[i]] = i
        }
        
        tmpApps.sort(by: { l, r in
            let idx1 = appIdSortListIndexMap[l.appId]
            let idx2 = appIdSortListIndexMap[r.appId]
            if let i1 = idx1, let i2 = idx2 {
                return i1 < i2
            } else if idx1 != nil {
                return false
            } else if idx2 != nil {
                return true
            }
            return true
        })
        
        var newSortList = [String]()
        tmpApps.forEach { ele in
            newSortList.append(ele.appId)
        }
        if newSortList != appIdSortList {
            Defaults[.appSortList] = newSortList
        }
        
        DispatchQueue.main.async { [tmpApps] in
            self.apps = tmpApps
            print("load \(self.apps.count) app\(self.apps.count <= 1 ? "" : "s")")
        }
        
    }
    
    func getAppIconURL(appId: String) -> URL? {
        for ele in apps {
            if ele.id != appId {
                continue
            }
            guard let icon = ele.icon else {
                return nil
            }
            if icon.starts(with: "http://") || icon.starts(with: "https://") {
                return URL(string: icon)
            }
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appending(path: ele.name).appending(path: icon)
        }
        return nil
    }
}

struct AppInfo: Hashable, Identifiable, Codable {
    var name: String
    var appId: String
    var author: String?
    var website: String?
    var icon: String?
    var version: String? // v{x.x.x}, like v0.0.1
    var description: String?
    var displayMode: String? // multiple-webview, signle-webview(default)
    var homepage: String
    var pages: [PageConfig]?
    var navigationBarStatus: String? // display, hidden(default)
    var colorScheme: String? // dark, light (default auto)
    
    // can be override in PageConfig
    var backgroundColor: String? // hex string
    var navigationBarColor: String?
    var tintColor: String? // hex string
    
    var id: String {
        return appId
    }
    struct PageConfig: Hashable, Codable {
        var path: String
        var title: String?
        var scrollable: Bool?
        
        // override
        var backgroundColor: String?
        var navigationBarColor: String?
    }
}
