//
//  date.swift
//  minip
//
//  Created by ByteDance on 2025/7/5.
//

import Foundation

func formatDateToLocalString(
    _ date: Date,
    format: String = "yyyy-MM-dd HH:mm:ss"
) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = format
    dateFormatter.locale = Locale.current
    return dateFormatter.string(from: date)
}
