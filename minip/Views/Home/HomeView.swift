//
//  HomeView.swift
//  minip
//
//  Created by ByteDance on 2023/7/3.
//

import SwiftUI
import Kingfisher
import Defaults

struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()
    @StateObject var _pathManager = pathManager
    
    @State var importType: Int? = nil
    var body: some View {
        ZStack {
            NavigationStack {
                List {
                    ForEach(viewModel.apps, id: \.appId) { ele in
                        AppListItemView(appInfo: ele)
                            .environmentObject(viewModel)
                    }
                    .onMove { from, to in
                        viewModel.apps.move(fromOffsets: from, toOffset: to)
                        Defaults[.appSortList].move(fromOffsets: from, toOffset: to)
                    }
                }
                .refreshable {
                    viewModel.loadAppInfos()
                }
                .navigationTitle(Text("Projects"))
                .toolbar {
                    EditButton()
                        .foregroundColor(.primary)
                    Menu {
                        Button {
//                            importType = 0
                            ShowNotImplement()
                            
                        } label: {
                            Label("Create new project", systemImage: "folder.badge.plus")
                        }
                        Button {
                            importType = 1
                        } label: {
                            Label("Load from web", systemImage: "network")
                        }
                        Button {
                            importType = 2
                        } label: {
                            Label("Load from file", systemImage: "folder")
                        }
                    } label: {
                        Image(systemName: "plus.square")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .fullScreenCover(item: $importType) { item in
            switch item {
            case 1:
                DownloadProjectView(onSuccess: {
                    viewModel.loadAppInfos()
                })
            case 2:
                ImportProjectFromFileView(onSuccess: {
                    viewModel.loadAppInfos()
                })
            default:
                EmptyView()
            }
        }
        .alert(isPresented: $viewModel.showDeleteAlert) {
            Alert(
                title: Text("Confirm"),
                message: Text("delete [\(viewModel.deleteApp?.name ?? "")] ?"),
                primaryButton: .destructive(Text("Delete")) {
                    viewModel.apps.removeAll { $0 == viewModel.deleteApp }
                    viewModel.deleteApp = nil
                },
                secondaryButton: .cancel() {
                    viewModel.deleteApp = nil
                }
            )
        }
        .fullScreenCover(item: $viewModel.selectedApp) { item in
            let _ = {
                _pathManager.openedApp = item
            }()
            NavigationStack(path: $_pathManager.path) {
                MiniPageView(appInfo: item, closeApp: closeApp)
                    .navigationDestination(for: String.self) { target in
                        MiniPageView(appInfo: item, page: target, closeApp: closeApp)
                    }
            }.tint({
                if let hexColor = item.tintColor {
                    return Color(hex: hexColor) ?? .accentColor
                }
                return .accentColor
            }())
            .preferredColorScheme({
                if item.colorScheme == "light" {
                    return .light
                } else if item.colorScheme == "dark" {
                    return .dark
                }
                return .none
            }())
        }
    }
    
    @State var test = false
    
    func closeApp() {
        let appId = viewModel.selectedApp?.appId
        viewModel.selectedApp = nil
        _pathManager.path = []
        _pathManager.appTmpStore.removeAll()
        guard let appId = appId else {
            return
        }
        KVStoreManager.shared.removeDB(dbName: appId)
    }
    
}

struct AppListItemView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    var appInfo: AppInfo
    var body: some View {
        
        let noIconView  = Rectangle()
            .foregroundColor(.secondary)
            .cornerRadius(10)
            .frame(width: 60, height: 60)
            .shadow(radius: 5)
        HStack {
            if let iconURL = viewModel.getAppIconURL(appId: appInfo.appId) {
                if iconURL.scheme == "file", let img = UIImage(contentsOfFile: iconURL.path()) {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(10)
                        .shadow(radius: 5)
                } else if iconURL.scheme == "http" || iconURL.scheme == "https" {
                    KFImage(iconURL)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(10)
                        .background {
                            noIconView
                        }
                } else {
                    noIconView
                }
            } else {
                noIconView
            }
            
            VStack (alignment: .leading) {
                Text(appInfo.name)
                    .lineLimit(1)
                    .padding(.top)
                Spacer()
                Text("@\(appInfo.author ?? "no_author")")
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .foregroundColor(.secondary)
                Text(appInfo.appId)
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            .frame(height: 60)
            
            Spacer()
            
        }
        .background {
            Button {
                viewModel.selectedApp = appInfo
            } label: {
                EmptyView()
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button  {
                viewModel.showDeleteAlert = true
                viewModel.deleteApp = appInfo
            } label: {
                Text("Delete")
            }
            .tint(.red)
            
            Button {
                
            } label: {
                Text("Settings")
            }
            
        }
    }
}

extension Int: Identifiable {
    public var id: Int {
        self
    }
}
