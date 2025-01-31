//
//  SwipeToDismiss.swift
//  minip
//
//  Created by LZY on 2025/1/29.
//

import Foundation
import UIKit

class SwipeToDismissViewController: UIViewController {

    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var initialTouchPoint: CGPoint = CGPoint(x: 0, y: 0)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 添加滑动手势识别器
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGestureRecognizer)
    }

    @objc private func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        let touchPoint = sender.location(in: view.window)
        
        switch sender.state {
        case .began:
            initialTouchPoint = touchPoint
        case .changed:
            if touchPoint.x > initialTouchPoint.x {
                view.frame.origin.x = touchPoint.x - initialTouchPoint.x
            }
        case .ended, .cancelled:
            let velocity = sender.velocity(in: view)
            let movedDistance = touchPoint.x - initialTouchPoint.x
            
            // 如果滑动距离超过屏幕宽度的1/3或者滑动速度足够快，则退出页面
            if movedDistance > view.bounds.width / 3 || velocity.x > 1000 {
                dismiss(animated: true, completion: nil)
            } else {
                // 否则恢复原位
                UIView.animate(withDuration: 0.3) {
                    self.view.frame.origin.x = 0
                }
            }
        default:
            break
        }
    }
}
