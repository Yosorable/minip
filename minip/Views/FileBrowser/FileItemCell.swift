//
//  FileItemCell.swift
//  minip
//
//  Created by LZY on 2025/3/16.
//

import UIKit

class FileItemCell: UITableViewCell {
    static let identifier = "FileItemCell"

    lazy var itemImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .secondaryLabel
        return imageView
    }()

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingMiddle
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    lazy var sizeLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = .secondaryLabel
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        return label
    }()

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(itemImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(sizeLabel)
        itemImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            itemImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            itemImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            itemImageView.widthAnchor.constraint(equalToConstant: 30),
            itemImageView.heightAnchor.constraint(equalToConstant: 30),

            nameLabel.leadingAnchor.constraint(equalTo: itemImageView.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            sizeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sizeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: sizeLabel.leadingAnchor, constant: -8)
        ])
        separatorInset = UIEdgeInsets(top: 0, left: 55, bottom: 0, right: 0)
    }

    func configure(with info: FileInfo, displayName: NSAttributedString? = nil) {
        if info.isFolder {
            sizeLabel.isHidden = true
            itemImageView.image = UIImage(systemName: (info.url == Global.shared.documentsTrashURL) ? "trash" : "folder")
            accessoryType = .disclosureIndicator
        } else {
            sizeLabel.isHidden = false
            sizeLabel.text = info.size ?? "unknown size"
            itemImageView.image = UIImage(systemName: FileManager.isImage(url: info.url) ? "photo" : "doc")
            accessoryType = .none
        }
        if let atxt = displayName {
            nameLabel.attributedText = atxt
        } else {
            nameLabel.text = info.fileName
        }
    }
}
