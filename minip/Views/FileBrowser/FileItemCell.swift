//
//  FileItemCell.swift
//  minip
//
//  Created by LZY on 2025/3/16.
//

import QuickLookThumbnailing
import UIKit

class FileItemCell: UITableViewCell {
    static let identifier = "FileItemCell"
    static let iconSize: CGFloat = 35

    private var thumbnailRequest: QLThumbnailGenerator.Request?
    private var fileInfo: FileInfo?

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
            itemImageView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            itemImageView.heightAnchor.constraint(equalToConstant: Self.iconSize),

            nameLabel.leadingAnchor.constraint(equalTo: itemImageView.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            sizeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sizeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: sizeLabel.leadingAnchor, constant: -8),
        ])
        separatorInset = UIEdgeInsets(top: 0, left: 16 + Self.iconSize + 8, bottom: 0, right: 0)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        if let request = thumbnailRequest {
            QLThumbnailGenerator.shared.cancel(request)
            thumbnailRequest = nil
        }
        fileInfo = nil
    }

    func configure(with info: FileInfo, displayName: NSAttributedString? = nil) {
        let old = fileInfo
        fileInfo = info

        let urlChanged = old?.url != info.url

        if old?.isFolder != info.isFolder {
            itemImageView.image = nil
        }

        if info.isFolder {
            sizeLabel.isHidden = true

            let filesCnt = info.filesCount ?? 0
            if info.url == Global.shared.documentsTrashURL {
                itemImageView.image = UIImage(named: filesCnt == 0 ? "trash-empty" : "trash-no-empty")
            } else {
                itemImageView.image = UIImage(named: filesCnt == 0 ? "folder-empty" : "folder-no-empty")
            }
            accessoryType = .disclosureIndicator
        } else {
            sizeLabel.isHidden = false
            sizeLabel.text = info.size ?? "unknown size"
            accessoryType = .none

            let sizeChanged = old?.size != info.size

            if urlChanged || sizeChanged {
                let scale = UIScreen.main.scale
                let request = QLThumbnailGenerator.Request(fileAt: info.url, size: CGSize(width: Self.iconSize, height: Self.iconSize), scale: scale, representationTypes: .all)
                thumbnailRequest = request
                QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { [weak self] representation, _ in
                    var finaleImage: UIImage?

                    if let representation {
                        let image = representation.uiImage
                        let needsBorder = representation.type != .icon
                        finaleImage = image.withRoundedCorners(radius: 1, border: needsBorder)
                    } else {
                        finaleImage = UIImage(named: "file")
                    }

                    DispatchQueue.main.async {
                        guard let self, self.thumbnailRequest === request else { return }
                        self.itemImageView.image = finaleImage
                    }
                }
            }
        }
        if let atxt = displayName {
            nameLabel.attributedText = atxt
        } else {
            nameLabel.text = info.fileName
        }
    }
}

extension UIImage {
    fileprivate func withRoundedCorners(radius: CGFloat, border: Bool = false) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        let cornerRadius = radius * scale
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            path.addClip()
            draw(in: rect)

            if border {
                let lineWidth = 0.8
                let borderPath = UIBezierPath(roundedRect: rect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2), cornerRadius: cornerRadius)
                UIColor.lightGray.withAlphaComponent(0.3).setStroke()
                borderPath.lineWidth = lineWidth
                borderPath.stroke()
            }
        }
    }
}
