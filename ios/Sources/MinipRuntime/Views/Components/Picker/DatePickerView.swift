//
//  DatePickerView.swift
//  minip
//
//  Created by LZY on 2025/2/12.
//

import Foundation
import UIKit

class DatePickerView: UIDatePicker {
    struct Data: Codable {
        let start: String?
        let end: String?
        let value: String?
        let dateFormat: String // yyyy-MM-dd hh:mm:ss
    }

    let format = DateFormatter()

    init(_ data: Data, mode: UIDatePicker.Mode) {
        super.init(frame: .zero)

        self.datePickerMode = mode
        self.preferredDatePickerStyle = .wheels
        format.dateFormat = data.dateFormat
        if let start = data.start {
            minimumDate = format.date(from: start)
        }
        if let end = data.end {
            maximumDate = format.date(from: end)
        }
        if let currentValue = data.value, let currentDate = format.date(from: currentValue) {
            date = currentDate
        }
    }

    func getCurrentDate() -> Date {
        return date
    }

    func getCurrentFormatString() -> String {
        return format.string(from: date)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
