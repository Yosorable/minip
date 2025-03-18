//
//  Global.swift
//  minip
//
//  Created by LZY on 2025/3/18.
//

import Foundation

final class Global {
    static let shared = Global()

    let documentsRootURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let sandboxRootURL = URL(string: NSHomeDirectory())!

    private init() {}
}
