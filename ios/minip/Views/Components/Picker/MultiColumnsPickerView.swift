//
//  MultiPickerView.swift
//  minip
//
//  Created by LZY on 2025/2/12.
//

import UIKit

class MultiColumnsPickerView: UIPickerView {
    struct Data: Codable {
        let columns: [[String]]
        let index: [Int]
    }

    let data: Data
    var currentIndex: [Int]

    init(data: Data) {
        self.data = data
        self.currentIndex = data.index
        super.init(frame: .zero)

        self.delegate = self
        self.dataSource = self

        for i in 0 ..< data.columns.count {
            selectRow(currentIndex[i], inComponent: i, animated: false)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MultiColumnsPickerView: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return data.columns.count
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return data.columns[component].count
    }
}

extension MultiColumnsPickerView: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return data.columns[component][row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currentIndex[component] = row
    }
}
