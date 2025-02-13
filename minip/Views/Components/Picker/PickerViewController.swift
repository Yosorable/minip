//
//  SinglePickerController.swift
//  minip
//
//  Created by LZY on 2025/2/12.
//

import UIKit
import Foundation

class PickerViewController: UIViewController {
    let transitioning = BottomSheetTransitioningDelegate()
    var confirmed = false
    var pickerType: PickerType?
    var singlePickerData: SingleColumnPickerView.Data?
    var multiPickerData: MultiColumnsPickerView.Data?
    var datePickerData: DatePickerView.Data?
    
    var singlePickerResult: Int?
    var multiPickerResult: [Int]?
    var datePickerResult: String?
    
    var onConfirmed: (()->Void)?
    var onCanceled: (()->Void)?

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = self.transitioning
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let pickerType = self.pickerType else { return }
        
        if pickerType == .singleColumn {
            guard let singlePickerData = singlePickerData else { return }
            let picker = SingleColumnPickerView(data: singlePickerData)
            self.view = PickerContainerView(pickerView: picker, dismiss: { [weak self] in
                self?.dismiss(animated: true)
            }, confirm: { [weak self] in
                self?.singlePickerResult = picker.currentIndex
                self?.confirmed = true
                self?.dismiss(animated: true)
            })
        } else if pickerType == .multipleColumns {
            guard let multiPickerData = multiPickerData else { return }
            let picker = MultiColumnsPickerView(data: multiPickerData)
            self.view = PickerContainerView(pickerView: picker, dismiss: { [weak self] in
                self?.dismiss(animated: true)
            }, confirm: { [weak self] in
                self?.multiPickerResult = picker.currentIndex
                self?.confirmed = true
                self?.dismiss(animated: true)
            })
        } else if pickerType == .date || pickerType == .time {
            guard let datePickerData = self.datePickerData else { return }
            var mode = UIDatePicker.Mode.date
            if pickerType == .time {
                mode = .time
            }
            
            let picker = DatePickerView(datePickerData, mode: mode)
            self.view = PickerContainerView(pickerView: picker, dismiss: { [weak self] in
                self?.dismiss(animated: true)
            }, confirm: { [weak self] in
                self?.datePickerResult = picker.getCurrentFormatString()
                self?.confirmed = true
                self?.dismiss(animated: true)
            })
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        if confirmed {
            onConfirmed?()
        } else {
            onCanceled?()
        }
    }
}
