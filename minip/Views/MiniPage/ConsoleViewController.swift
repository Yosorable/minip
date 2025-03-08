//
//  ConsoleViewController.swift
//  minip
//
//  Created by LZY on 2025/3/8.
//

import UIKit

class ConsoleViewController: UIViewController {
    lazy var textView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        textView.isSelectable = true
        textView.isScrollEnabled = true
        return textView
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Console"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(appendLog), name: .logAppended, object: nil)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.alwaysBounceVertical = true
        view.backgroundColor = .systemBackground
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        textView.text = MiniAppManager.shared.webViewLogs.joined(separator: "\n")
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .done, target: self, action: #selector(close))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollToBottom()
    }

    func scrollToBottom() {
        let newVal = textView.contentSize.height - textView.bounds.height + ((UIApplication.shared.delegate as? AppDelegate)?.window?.safeAreaInsets.bottom ?? 0)
        if newVal > 0 {
            textView.contentOffset.y = newVal
        }
    }

    @objc func appendLog(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let message = userInfo["message"] as? String
        {
            var update = ""
            if textView.text != "" {
                update += "\n"
            }
            update += message
            textView.text += update
            scrollToBottom()
        }
    }
    
    @objc func close() {
        dismiss(animated: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
