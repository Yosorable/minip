//
//  Localizable.swift
//  minip
//
//  Created by LZY on 2025/2/21.
//

import Foundation

func i18n(_ key: String) -> String {
    return Bundle.main.localizedString(forKey: key, value: nil, table: nil)
}

func i18nF(_ fmtKey: String, _ arguments: any CVarArg ...) -> String {
    String(format: NSLocalizedString(fmtKey, comment: ""), arguments)
}
