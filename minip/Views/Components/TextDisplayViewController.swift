//
//  TextDisplayViewController.swift
//  minip
//
//  Created by LZY on 2025/2/13.
//

import UIKit

class TextDisplayViewController: UIViewController {
    lazy var textView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.maximumNumberOfLines = 0
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        
        return textView
    }()
    var text: String
    init(text: String, title: String? = nil) {
        self.text = text
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        textView.text = self.text
        view = textView
        
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(dismissNav))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "doc.on.doc"), style: .plain, target: self, action: #selector(copyToClipboard))
    }
    
    @objc func dismissNav() {
        dismiss(animated: true)
    }
    
    @objc func copyToClipboard() {
        UIPasteboard.general.string = textView.text
        ShowSimpleSuccess()
    }
}
