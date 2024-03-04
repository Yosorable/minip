//
//  UIViewController++.swift
//  minip
//
//  Created by LZY on 2024/3/4.
//

import Foundation
import UIKit

extension UIViewController {
    var isDarkMode: Bool {
        if #available(iOS 13.0, *) {
            return self.traitCollection.userInterfaceStyle == .dark
        }
        else {
            return false
        }
    }

}
