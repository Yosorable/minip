//
//  AppCell.swift
//  minip
//
//  Created by LZY on 2025/2/1.
//

import Kingfisher
import SwiftUI
import UIKit

class AppCell: UITableViewCell {
    static let identifier = "AppCell"

    lazy var appIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true

        return imageView
    }()

    lazy var appNameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    lazy var authorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    lazy var appIdLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let infoStackView = UIStackView(arrangedSubviews: [appNameLabel, authorLabel, appIdLabel])
        infoStackView.axis = .vertical
        infoStackView.alignment = .leading
        infoStackView.setCustomSpacing(10, after: appNameLabel)

        let stackView = UIStackView(arrangedSubviews: [appIconImageView, infoStackView])
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.alignment = .center

        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            appIconImageView.widthAnchor.constraint(equalToConstant: 60),
            appIconImageView.heightAnchor.constraint(equalToConstant: 60),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])

        separatorInset = UIEdgeInsets(top: 0, left: 85, bottom: 0, right: 0)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with app: AppInfo) {
        appNameLabel.text = app.displayName ?? app.name
        authorLabel.text = "@" + (app.author ?? "no_author")
        appIdLabel.text = app.appId
        appIconImageView.image = nil
        appIconImageView.layer.borderColor = nil
        appIconImageView.layer.borderWidth = 0
        if let icon = app.icon {
            var iconURL: URL?
            if icon.starts(with: "http://") || icon.starts(with: "https://") {
                iconURL = URL(string: icon)
                appIconImageView.kf.setImage(with: iconURL)
            } else {
                if let iconURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPolyfill(path: app.name).appendingPolyfill(path: icon) {
                    appIconImageView.image = UIImage(contentsOfFile: iconURL.path)
                }
            }
        } else {
            appIconImageView.layer.borderColor = UIColor.secondaryLabel.cgColor
            appIconImageView.layer.borderWidth = 1
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if appIconImageView.layer.borderColor != nil {
                appIconImageView.layer.borderColor = UIColor.secondaryLabel.cgColor
            }
        }
    }
}
