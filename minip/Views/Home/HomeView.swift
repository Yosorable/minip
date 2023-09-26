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
    @State var mode: EditMode = .inactive
    
    @State var importType: Int? = nil
    var body: some View {
        ZStack {
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
        .environment(\.editMode, $mode)
        .fullScreenCover(item: $importType) { item in
            switch item {
            case 1:
                DownloadProjectView(onSuccess: {
                    // iOS 14 onAppear刷新
                    if #available(iOS 15.0, *) {
                        viewModel.loadAppInfos()
                    }
                })
            case 2:
                ImportProjectFromFileView(onSuccess: {
                    // iOS 14 onAppear刷新
                    if #available(iOS 15.0, *) {
                        viewModel.loadAppInfos()
                    }
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
    }
    func list() -> some View {
        if #available(iOS 15.0, *) {
            return List {
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
        } else {
            return List {
                ForEach(viewModel.apps, id: \.appId) { ele in
                    AppListItemView(appInfo: ele)
                        .environmentObject(viewModel)
                }
                .onMove { from, to in
                    viewModel.apps.move(fromOffsets: from, toOffset: to)
                    Defaults[.appSortList].move(fromOffsets: from, toOffset: to)
                }
                .onDelete { item in
                    print(item)
                }
            }
            .onAppear {
                viewModel.loadAppInfos()
            }
        }
    }
    var content: some View {
        list()
            .navigationTitle(Text("Projects"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
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
}

struct AppListItemView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @Environment(\.editMode) var editMode: Binding<EditMode>?
    var appInfo: AppInfo
    
    var content: some View {
        let noIconView  = Rectangle()
            .foregroundColor(.secondary)
            .cornerRadius(10)
            .frame(width: 60, height: 60)
            .shadow(radius: 2)
        return HStack {
            if let iconURL = viewModel.getAppIconURL(appId: appInfo.appId) {
                if iconURL.scheme == "file", let img = UIImage(contentsOfFile: iconURL.path) {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(10)
                        .shadow(radius: 2)
                } else if iconURL.scheme == "http" || iconURL.scheme == "https" {
                    KFImage(iconURL)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(10)
                        .shadow(radius: 2)
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
    }
    var body: some View {
        if #available(iOS 15.0, *) {
            content
                .background {
                    Button {
                        if editMode?.wrappedValue == .active {
                            return
                        }
                        let app = appInfo

                        var vc: UINavigationController
                        
                        if let tabs = app.tabs, tabs.count > 0 {
                            let tabc = UITabBarController()

                            var pages = [UIViewController]()
                            for (idx, ele) in tabs.enumerated() {
                                let page = MiniPageViewController(app: app, page: ele.path, title: ele.title)
                                page.tabBarItem = UITabBarItem(title: ele.title, image: UIImage(systemName: ele.systemImage), tag: idx)
                                pages.append(page)
                            }
                            tabc.viewControllers = pages

                            vc = UINavigationController(rootViewController: tabc)

                            if let tc = app.tintColor {
                                vc.navigationBar.tintColor = UIColor(hex: tc)
                                tabc.tabBar.tintColor = UIColor(hex: tc)
                            }
                        } else {
                            vc = UINavigationController(rootViewController: MiniPageViewController(app: app))
                        }

                        if app.colorScheme == "dark" {
                            vc.overrideUserInterfaceStyle = .dark
                        } else if app.colorScheme == "light" {
                            vc.overrideUserInterfaceStyle = .light
                        }
                        vc.modalPresentationStyle = .fullScreen
                        MiniAppManager.shared.openedApp = app
                        GetTopViewController()?.present(vc, animated: true)
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
        } else {
            content
                .onTapGesture {
                    if editMode?.wrappedValue == .active {
                        return
                    }
                    let app = appInfo
                    
                    var vc: UINavigationController
                    
                    if let tabs = app.tabs, tabs.count > 0 {
                        let tabc = UITabBarController()

                        var pages = [UIViewController]()
                        for (idx, ele) in tabs.enumerated() {
                            let page = MiniPageViewController(app: app, page: ele.path, title: ele.title)
                            page.tabBarItem = UITabBarItem(title: ele.title, image: UIImage(systemName: ele.systemImage), tag: idx)
                            pages.append(page)
                        }
                        tabc.viewControllers = pages

                        vc = UINavigationController(rootViewController: tabc)

                        if let tc = app.tintColor {
                            vc.navigationBar.tintColor = UIColor(hex: tc)
                            tabc.tabBar.tintColor = UIColor(hex: tc)
                        }
                    } else {
                        vc = UINavigationController(rootViewController: MiniPageViewController(app: app))
                    }

                    if app.colorScheme == "dark" {
                        vc.overrideUserInterfaceStyle = .dark
                    } else if app.colorScheme == "light" {
                        vc.overrideUserInterfaceStyle = .light
                    }
                    vc.modalPresentationStyle = .fullScreen
                    MiniAppManager.shared.openedApp = app
                    GetTopViewController()?.present(vc, animated: true)
                }
            // todo: 滑动功能
        }
    }
}
