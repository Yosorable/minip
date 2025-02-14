//
//  TabViewFIx.swift
//  minip
//
//  Created by LZY on 2025/1/31.
//

import UIKit

// MARK: - disable ios18 tabview switch animation

class MainTabBarController: UITabBarController {
    override var selectedIndex: Int {
        set {
            if #available(iOS 18.0, *) {
                UIView.performWithoutAnimation {
                    super.selectedIndex = newValue
                }
            } else {
                super.selectedIndex = newValue
            }
        }
        get {
            super.selectedIndex
        }
    }
    
    override var selectedViewController: UIViewController? {
        set {
            if #available(iOS 18.0, *) {
                UIView.performWithoutAnimation {
                    super.selectedViewController = newValue
                }
            } else {
                super.selectedViewController = newValue
            }
        }
        get {
            super.selectedViewController
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
}
