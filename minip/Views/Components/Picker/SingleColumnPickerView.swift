//
//  SinglePicker.swift
//  minip
//
//  Created by LZY on 2025/2/12.
//

import UIKit

class SingleColumnPickerView: UIPickerView {
    struct Data: Codable {
        let column: [String]
        let index: Int
    }
    let data: Data
    var currentIndex: Int = 0

    init(data: Data) {
        self.data = data
        super.init(frame: .zero)
        
        self.delegate = self
        self.dataSource = self
        
        self.selectRow(data.index, inComponent: 0, animated: false)
        currentIndex = data.index
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SingleColumnPickerView: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return data.column.count
    }
}

extension SingleColumnPickerView: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return data.column[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currentIndex = row
    }
}
