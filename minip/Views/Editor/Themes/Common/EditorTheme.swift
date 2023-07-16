//
//  EditorTheme.swift
//  minip
//
//  Created by ByteDance on 2023/7/10.
//

import Runestone
import UIKit

public protocol EditorTheme: Runestone.Theme {
    var backgroundColor: UIColor { get }
    var userInterfaceStyle: UIUserInterfaceStyle { get }
}
