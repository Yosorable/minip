//
//  MiniAppSettingsViewController.swift
//  minip
//
//  Created by LZY on 2025/2/2.
//

import UIKit
import SwiftUI

class MiniAppSettingsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        
        let hostingController = UIHostingController(rootView: ScrollView {
            VStack {
                Text("Swipe from left to go back")
                Button {
                    self.dismiss(animated: true)
                } label: {
                    Text("Close")
                }
            }
        })
                
        // 添加 SwiftUI 视图为子视图
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        // 设置约束，使 SwiftUI 视图适应 UIViewController
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        hostingController.didMove(toParent: self)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .done, target: self, action: #selector(self.closePage))
    }
    
    @objc func closePage() {
        dismiss(animated: true)
    }
}
