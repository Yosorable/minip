//
//  PickerContainerView.swift
//  minip
//
//  Created by LZY on 2025/2/12.
//

import UIKit

class PickerContainerView: UIView {
    private let toolbar = UIView()
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let pickerView: UIView
    private let dismissFunc: ()->Void
    private let confirmFunc: ()->Void
    private let title: String?
    init(pickerView: UIView, title: String? = nil, dismiss: @escaping ()->Void, confirm: @escaping ()->Void) {
        self.pickerView = pickerView
        self.dismissFunc = dismiss
        self.confirmFunc = confirm
        self.title = title
        super.init(frame: .zero)
        
        setupBackground()
        setupToolbar()
        setupPickerView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupBackground() {
        blurEffectView.layer.cornerRadius = 16
        blurEffectView.layer.masksToBounds = true
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurEffectView)
        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func setupToolbar() {
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toolbar)
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        
        let confirmButton = UIButton(type: .system)
        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.addTarget(self, action: #selector(confirm), for: .touchUpInside)
        
        let title = UILabel()
        title.text = self.title
        title.textColor = .secondaryLabel
        
        toolbar.addSubview(cancelButton)
        toolbar.addSubview(confirmButton)
        toolbar.addSubview(title)
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 50),
            
            cancelButton.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 16),
            cancelButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            
            confirmButton.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -16),
            confirmButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            
            title.centerXAnchor.constraint(equalTo: toolbar.centerXAnchor),
            title.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor)
        ])
    }
    
    func setupPickerView() {
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pickerView)
        
        NSLayoutConstraint.activate([
            pickerView.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            pickerView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            pickerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc func dismiss() {
        dismissFunc()
    }
    
    @objc func confirm() {
        confirmFunc()
    }
}
