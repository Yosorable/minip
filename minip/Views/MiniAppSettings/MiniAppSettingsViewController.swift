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
        title = "MiniAppSettings"
        
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
        
        setupEdgePanGesture()
    }
    
    @objc func closePage() {
        dismiss(animated: true)
    }
    
    private func setupEdgePanGesture() {
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
        edgePan.edges = .left  // 监听左侧边缘滑动
        view.addGestureRecognizer(edgePan)
    }
    private var startX: CGFloat = 0
    @objc private func handleEdgePan(_ gesture: UIScreenEdgePanGestureRecognizer) {
            let translation = gesture.translation(in: view)
            let progress = translation.x / view.bounds.width  // 计算滑动进度

            switch gesture.state {
            case .began:
                startX = view.frame.origin.x

            case .changed:
                // 让页面跟手移动，不能向右移动过多（最多为屏幕宽度）
                let offsetX = max(translation.x, 0)
                view.transform = CGAffineTransform(translationX: offsetX, y: 0)

            case .ended, .cancelled:
                if progress > 0.5 { // 滑动超过30%时，执行返回
                    UIView.animate(withDuration: 0.2, animations: {
                        self.view.transform = CGAffineTransform(translationX: self.view.bounds.width, y: 0)
                    }) { _ in
                        self.dismiss(animated: false)  // 立即返回，不需要动画
                    }
                } else {
                    // 否则回弹到原位
                    UIView.animate(withDuration: 0.2) {
                        self.view.transform = .identity
                    }
                }

            default:
                break
            }
        }
}
