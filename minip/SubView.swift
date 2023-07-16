//
//  SubView.swift
//  minip
//
//  Created by ByteDance on 2023/3/15.
//

import SwiftUI
import WKWebViewJavascriptBridge

struct SubView: View {

    var startFile = "sub_view.html"
    var id: UUID
    
//    @EnvironmentObject var pathManager: PathManager
    
//    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    init(id: UUID) {
        self.id = id
        print("in sub view, \(id)")
    }
    

    
    var body: some View {
        ZStack {
            WebView(startFile: startFile, wkwebview: pathManager.newWebview)
//                .edgesIgnoringSafeArea(.all)
            NavigationLink("SubView", value: "/sub_view.html")
        }
        .edgesIgnoringSafeArea(.all)
        .navigationTitle(Text("SubView \(String(id.uuidString.prefix(8)))"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {} label: {
                    Image(systemName: "ellipsis")
                }
                Button {} label: {
                    Image(systemName: "xmark")
                }
            }
        }
        .onDisappear {
            print("dis, \(id)")
        }
        .task {
            pathManager.push()
        }
//        .navigationBarBackButtonHidden(true)
        
    }
}

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

