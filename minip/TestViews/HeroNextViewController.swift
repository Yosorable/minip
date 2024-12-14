//
//  HeroNextViewController.swift
//  minip
//
//  Created by LZY on 2024/12/14.
//

import Foundation
import UIKit
import Hero

class HeroNextViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .orange
        
        let screenEdgePanGR = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(leftSwipeDismiss(gestureRecognizer:)))
        screenEdgePanGR.edges = .left
        view.addGestureRecognizer(screenEdgePanGR)
    }
    
    @objc func handlePan1(gr: UIPanGestureRecognizer) {
        switch gr.state {
        case .began:
            dismiss(animated: true, completion: nil)
        case .changed:
            let progress = gr.translation(in: nil).x / view.bounds.width
            Hero.shared.update(progress)
        default:
            if (gr.translation(in: nil).x + gr.velocity(in: nil).x) / view.bounds.width > 0.5 {
                Hero.shared.finish()
            } else {
                Hero.shared.cancel()
            }
        }
    }
    
    @objc func leftSwipeDismiss(gestureRecognizer:UIPanGestureRecognizer) {

            switch gestureRecognizer.state {
            case .began:
                hero.dismissViewController()
            case .changed:
                
                let translation = gestureRecognizer.translation(in: nil)
                let progress = translation.x / 2.0 / view.bounds.width
                Hero.shared.update(progress)
                Hero.shared.apply(modifiers: [.translate(x: translation.x)], to: self.view)
                break
            default:
                let translation = gestureRecognizer.translation(in: nil)
                let progress = translation.x / 2.0 / view.bounds.width
                if progress + gestureRecognizer.velocity(in: nil).x / view.bounds.width > 0.3 {
                    Hero.shared.finish()
                } else {
                    Hero.shared.cancel()
                }
            }
            
        }
}
