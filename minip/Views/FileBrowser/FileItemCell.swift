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
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let stackView = UIStackView(arrangedSubviews: [itemImageView, nameLabel, spacer, sizeLabel])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8.6),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8.6),

            itemImageView.widthAnchor.constraint(equalToConstant: 35),
            itemImageView.widthAnchor.constraint(equalToConstant: 35),
        ])
        separatorInset = UIEdgeInsets(top: 0, left: 59, bottom: 0, right: 0)
    }

    func configure(with info: FileInfo, isRoot: Bool) {
        if info.isFolder {
            sizeLabel.isHidden = true
            itemImageView.image = UIImage(
                systemName: (isRoot && info.fileName == ".Trash") ? "trash" : "folder",
                withConfiguration: UIImage.SymbolConfiguration(textStyle: .title2)
            )
            accessoryType = .disclosureIndicator
        } else {
            sizeLabel.isHidden = false
            sizeLabel.text = info.size ?? "unknown size"
            itemImageView.image = UIImage(
                systemName: FileManager.isImage(url: info.url) ? "photo" : "doc",
                withConfiguration: UIImage.SymbolConfiguration(textStyle: .title2)
            )
            accessoryType = .none
        }
        nameLabel.text = info.fileName
    }
}
