//
//  Localizable.swift
//  minip
//
//  Created by LZY on 2025/2/21.
//

import Foundation

func i18n(_ key: String) -> String {
    let localizedString = Bundle.main.localizedString(forKey: key, value: nil, table: nil)

    // set fall back to english
    if localizedString == key,
       let preferredLanguage = Locale.preferredLanguages.first,
       preferredLanguage != "en", // todo: multiple languages cause not equal (like: en-CN)
       let enBundlePath = Bundle.main.path(forResource: "en", ofType: "lproj"),
       let enBundle = Bundle(path: enBundlePath)
    {
        return enBundle.localizedString(forKey: key, value: nil, table: nil)
    }

    return localizedString
}

func i18nF(_ fmtKey: String, _ arguments: any CVarArg ...) -> String {
    String(format: i18n(fmtKey), arguments)
}
