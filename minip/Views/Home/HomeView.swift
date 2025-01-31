//
//  HomeView.swift
//  minip
//
//  Created by ByteDance on 2023/7/3.
//

import SwiftUI
import Kingfisher
import Defaults
import FlyingFox

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
                    logger.debug("[HomeView] \(item)")
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
                        
                        Task {
                            var addr = ""
                            if app.webServerEnabled == true {
                                var server: HTTPServer
                                if MiniAppManager.shared.server == nil {
                                    server = HTTPServer(address: try! .inet(ip4: "127.0.0.1", port: 60008))
                                    MiniAppManager.shared.server = server
                                    let fileManager = FileManager.default
                                    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                                    
                                    let dirHandler = DirectoryHTTPHandler(root: documentsURL)
                                    await server.appendRoute("GET /*") { req in
                                        var _req: HTTPRequest = req
                                        guard let appName = MiniAppManager.shared.openedApp?.name else {
                                            return HTTPResponse(statusCode: .notFound)
                                        }
                                        _req.path = "/\(appName)" + req.path
                                        print(_req.path)
                                        do {
                                            return try await dirHandler.handleRequest(_req)
                                        } catch {
                                            return HTTPResponse(statusCode: .notFound)
                                        }
                                    }
                                    
                                    
//                                    let dirHandler = DirectoryHTTPHandler(root: documentsURL.appendingPolyfill(path: "live2d-test"))
//                                    await server.appendRoute("GET /*", to: dirHandler)
                                    
                                    await server.appendRoute("POST /closeApp") { _ in
                                        DispatchQueue.main.async {
                                            if let mvc = GetTopViewController() as? MiniPageViewController {
                                                mvc.close()
                                            }
                                        }
                                        return HTTPResponse(statusCode: .ok)
                                    }
                                    
                                    await server.appendRoute("POST /ping") { req in
                                        var res = "pong".data(using: .utf8)!
                                        do {
                                            let data = try await req.bodyData
                                            res.append(" ".data(using: .utf8)!)
                                            res.append(data)
                                        } catch {
                                            
                                        }
                                        return HTTPResponse(statusCode: .ok, body: res)
                                    }
                                } else {
                                    server = MiniAppManager.shared.server!
                                }
                                
                                Task {
                                    try? await server.run()
                                }
                                try? await server.waitUntilListening()
                                if let ipPort = await server.listeningAddress {
                                    switch ipPort {
                                    case .ip4(_, port: let port): addr = "http://127.0.0.1:\(port)"
                                    case .ip6(_, port: let port): addr = "http://[::1]:\(port)"
                                    case .unix(let unixAddr):
                                        addr = "http://" + unixAddr
                                    }
                                    logger.info("[getAddress] \(addr)")
                                    MiniAppManager.shared.serverAddress = addr
                                }
                            }
                            
                            var vc: UINavigationController
                            if let tabs = app.tabs, tabs.count > 0 {
                                let tabc = UITabBarController()
//                                let tabc = MainTabBarController()
                                
                                var pages = [UIViewController]()
                                for (idx, ele) in tabs.enumerated() {
                                    let page = MiniPageViewController(app: app, page: ele.path, title: ele.title, isRoot: true)
                                    page.tabBarItem = UITabBarItem(title: ele.title, image: UIImage(systemName: ele.systemImage), tag: idx)
                                    pages.append(page)
                                }
                                tabc.viewControllers = pages
                                
                                vc = PannableNavigationViewController(rootViewController: tabc)
                                
                                if let tc = app.tintColor {
                                    vc.navigationBar.tintColor = UIColor(hex: tc)
                                    tabc.tabBar.tintColor = UIColor(hex: tc)
                                }
                            } else {
                                vc = PannableNavigationViewController(rootViewController: MiniPageViewController(app: app, isRoot: true))
                            }
                            
                            if app.colorScheme == "dark" {
                                vc.overrideUserInterfaceStyle = .dark
                            } else if app.colorScheme == "light" {
                                vc.overrideUserInterfaceStyle = .light
                            }
                            vc.modalPresentationStyle = .overFullScreen
                            MiniAppManager.shared.openedApp = app
                            
                            if app.landscape == true {
                                if #available(iOS 16.0, *) {
                                    let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                                    windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
                                } else {
                                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
                                }
                                try await Task.sleep(nanoseconds: 220_000_000)
                            }
                            
                            GetTopViewController()?.present(vc, animated: true)
                        }
                        
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
                    MiniAppManager.shared.openMiniAppV2(app: appInfo)
                }
            // todo: 滑动功能
        }
    }
}
