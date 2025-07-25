//
//  SinglePickerController.swift
//  minip
//
//  Created by LZY on 2025/2/12.
//

import Foundation
import UIKit

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

    var onConfirmed: (() -> Void)?
    var onCanceled: (() -> Void)?

    private var initialTouchPoint: CGPoint = .zero

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = self.transitioning
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let pickerType = self.pickerType else { return }

        var container: PickerContainerView?

        if pickerType == .singleColumn {
            guard let singlePickerData = singlePickerData else { return }
            let picker = SingleColumnPickerView(data: singlePickerData)
            container = PickerContainerView(pickerView: picker, dismiss: { [weak self] in
                self?.dismiss(animated: true)
            }, confirm: { [weak self] in
                self?.singlePickerResult = picker.currentIndex
                self?.confirmed = true
                self?.dismiss(animated: true)
            })
        } else if pickerType == .multipleColumns {
            guard let multiPickerData = multiPickerData else { return }
            let picker = MultiColumnsPickerView(data: multiPickerData)
            container = PickerContainerView(pickerView: picker, dismiss: { [weak self] in
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
            container = PickerContainerView(pickerView: picker, dismiss: { [weak self] in
                self?.dismiss(animated: true)
            }, confirm: { [weak self] in
                self?.datePickerResult = picker.getCurrentFormatString()
                self?.confirmed = true
                self?.dismiss(animated: true)
            })
        }

        guard let container = container else { return }
        container.toolbar.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:))))
        self.view = container
    }

    @objc private func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self.view)
        let velocity = sender.velocity(in: self.view)

        switch sender.state {
        case .began:
            self.initialTouchPoint = self.view.frame.origin
        case .changed:
            if translation.y > 0 {
                self.view.frame.origin.y = self.initialTouchPoint.y + translation.y
            }
        case .ended, .cancelled:
            if translation.y > 100 || velocity.y > 500 {
                self.dismiss(animated: true)
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.view.frame.origin = self.initialTouchPoint
                }
            }
        default:
            break
        }
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        if self.confirmed {
            self.onConfirmed?()
        } else {
            self.onCanceled?()
        }
    }
}
