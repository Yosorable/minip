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

        addChild(hostingController)
        view.addSubview(hostingController.view)

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
