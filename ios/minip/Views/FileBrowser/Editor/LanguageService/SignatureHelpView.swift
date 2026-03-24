//
//  SignatureHelpView.swift
//  minip
//

import UIKit

class SignatureHelpView: UIView {
    private let label = UILabel()
    private let navLabel = UILabel()
    private let upButton = UIButton(type: .system)
    private let downButton = UIButton(type: .system)
    private let navContainer = UIView()

    private var currentHelp: LSPSignatureHelp?
    private var displayedSignatureIndex: Int = 0
    private var lastAnchorRect: CGRect = .zero

    var isVisible: Bool { !isHidden }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        backgroundColor = UIColor(white: 0.15, alpha: 0.95)
        layer.cornerRadius = 6
        layer.masksToBounds = true

        // Navigation: ▲ 1/3 ▼
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        upButton.setImage(UIImage(systemName: "chevron.up", withConfiguration: symbolConfig), for: .normal)
        upButton.tintColor = .lightGray
        upButton.addTarget(self, action: #selector(prevSignature), for: .touchUpInside)

        downButton.setImage(UIImage(systemName: "chevron.down", withConfiguration: symbolConfig), for: .normal)
        downButton.tintColor = .lightGray
        downButton.addTarget(self, action: #selector(nextSignature), for: .touchUpInside)

        navLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        navLabel.textColor = .lightGray
        navLabel.textAlignment = .center

        navContainer.addSubview(upButton)
        navContainer.addSubview(navLabel)
        navContainer.addSubview(downButton)
        addSubview(navContainer)

        label.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        label.textColor = .white
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        addSubview(label)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(help: LSPSignatureHelp, at anchorRect: CGRect, in parentView: UIView) {
        guard !help.signatures.isEmpty else { hide(); return }

        currentHelp = help
        displayedSignatureIndex = min(help.activeSignature, help.signatures.count - 1)

        updateContent(help: help)

        if superview != parentView {
            removeFromSuperview()
            parentView.addSubview(self)
        }

        translatesAutoresizingMaskIntoConstraints = true
        lastAnchorRect = anchorRect
        layoutContent(anchorRect: anchorRect, parentView: parentView)
        isHidden = false
    }

    func hide() {
        guard !isHidden else { return }
        isHidden = true
        currentHelp = nil
        removeFromSuperview()
    }

    // MARK: - Navigation

    @objc private func prevSignature() {
        guard let help = currentHelp, help.signatures.count > 1 else { return }
        displayedSignatureIndex = (displayedSignatureIndex - 1 + help.signatures.count) % help.signatures.count
        updateContent(help: help)
        if let sv = superview {
            layoutContent(anchorRect: lastAnchorRect, parentView: sv)
        }
    }

    @objc private func nextSignature() {
        guard let help = currentHelp, help.signatures.count > 1 else { return }
        displayedSignatureIndex = (displayedSignatureIndex + 1) % help.signatures.count
        updateContent(help: help)
        if let sv = superview {
            layoutContent(anchorRect: lastAnchorRect, parentView: sv)
        }
    }

    // MARK: - Private

    private func updateContent(help: LSPSignatureHelp) {
        let sigCount = help.signatures.count
        let sigIndex = min(displayedSignatureIndex, sigCount - 1)
        let sig = help.signatures[sigIndex]

        let hasMultiple = sigCount > 1
        navContainer.isHidden = !hasMultiple
        if hasMultiple {
            navLabel.text = "\(sigIndex + 1)/\(sigCount)"
        }

        label.attributedText = buildAttributedLabel(signature: sig, activeParameter: help.activeParameter)
    }

    private func layoutContent(anchorRect: CGRect, parentView: UIView) {
        let maxWidth: CGFloat = 300
        let contentWidth = maxWidth - 16
        let padding: CGFloat = 8

        var contentY: CGFloat = 4
        if !navContainer.isHidden {
            let btnSize: CGFloat = 20
            let navSpacing: CGFloat = 4
            var navX: CGFloat = 0

            upButton.frame = CGRect(x: navX, y: 0, width: btnSize, height: btnSize)
            navX += btnSize + navSpacing

            let navLabelSize = navLabel.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: btnSize))
            navLabel.frame = CGRect(x: navX, y: (btnSize - navLabelSize.height) / 2, width: navLabelSize.width, height: navLabelSize.height)
            navX += navLabelSize.width + navSpacing

            downButton.frame = CGRect(x: navX, y: 0, width: btnSize, height: btnSize)
            navX += btnSize

            navContainer.frame = CGRect(x: padding, y: contentY, width: navX, height: btnSize)
            contentY += btnSize + 2
        }

        let labelSize = label.sizeThatFits(CGSize(width: contentWidth, height: .greatestFiniteMagnitude))
        label.frame = CGRect(x: padding, y: contentY, width: min(labelSize.width, contentWidth), height: labelSize.height)
        contentY += labelSize.height + 6

        let tooltipWidth = min(labelSize.width + padding * 2, maxWidth)
        let tooltipHeight = contentY

        var x = anchorRect.midX - tooltipWidth / 2
        x = max(8, min(x, parentView.bounds.width - tooltipWidth - 8))

        let spacing: CGFloat = 4
        var y = anchorRect.minY - tooltipHeight - spacing
        if y < parentView.safeAreaInsets.top {
            y = anchorRect.maxY + spacing
        }

        frame = CGRect(x: x, y: y, width: tooltipWidth, height: tooltipHeight)
    }

    private func buildAttributedLabel(signature: LSPSignatureInformation, activeParameter: Int) -> NSAttributedString {
        let fullLabel = signature.label
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 13, weight: .regular),
            .foregroundColor: UIColor.white,
        ]
        let boldAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 13, weight: .bold),
            .foregroundColor: UIColor.systemYellow,
        ]

        let result = NSMutableAttributedString(string: fullLabel, attributes: normalAttrs)

        if activeParameter >= 0 && activeParameter < signature.parameters.count {
            let paramLabel = signature.parameters[activeParameter].label
            if let range = fullLabel.range(of: paramLabel) {
                let nsRange = NSRange(range, in: fullLabel)
                result.setAttributes(boldAttrs, range: nsRange)
            }
        }

        return result
    }
}
