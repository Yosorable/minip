//
//  UITableView++.swift
//  minip
//
//  Created by LZY on 2025/3/17.
//

import UIKit

extension UITableView {
    func setEmptyView(title: NSAttributedString, message: NSAttributedString) {
        let titleLabel = UILabel()
        let messageLabel = UILabel()
        titleLabel.textColor = .label
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        messageLabel.textColor = .secondaryLabel
        messageLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.attributedText = title
        messageLabel.attributedText = message
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center

        self.setEmptyView(titleLabel: titleLabel, messageLabel: messageLabel)
    }

    fileprivate func setEmptyView(titleLabel: UILabel, messageLabel: UILabel) {
        guard self.backgroundView == nil else { return }

        let emptyView = UIView(frame: CGRect(x: self.center.x, y: self.center.y, width: self.bounds.size.width, height: self.bounds.size.height))
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(titleLabel)
        emptyView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            messageLabel.leftAnchor.constraint(equalTo: emptyView.leftAnchor, constant: 50),
            messageLabel.rightAnchor.constraint(equalTo: emptyView.rightAnchor, constant: -50)
        ])

        self.backgroundView = emptyView
        self.separatorStyle = .none
    }

    func restore() {
        self.backgroundView = nil
        self.separatorStyle = .singleLine
    }
}
