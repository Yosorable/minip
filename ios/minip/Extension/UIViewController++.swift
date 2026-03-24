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
        return self.traitCollection.userInterfaceStyle == .dark
    }
}
