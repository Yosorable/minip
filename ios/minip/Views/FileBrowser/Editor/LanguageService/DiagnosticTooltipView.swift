//
//  DiagnosticTooltipView.swift
//  minip
//

import UIKit

class DiagnosticTooltipView: UIView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        layer.cornerRadius = 6
        layer.masksToBounds = true

        label.font = .systemFont(ofSize: 13)
        label.textColor = .white
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(message: String, isError: Bool, at anchorRect: CGRect, in parentView: UIView) {
        label.text = message
        backgroundColor = isError
            ? UIColor(red: 0.6, green: 0.1, blue: 0.1, alpha: 0.95)
            : UIColor(red: 0.45, green: 0.35, blue: 0.05, alpha: 0.95)

        if superview != parentView {
            removeFromSuperview()
            parentView.addSubview(self)
        }

        translatesAutoresizingMaskIntoConstraints = true

        let maxWidth: CGFloat = 280
        let fittingSize = label.sizeThatFits(CGSize(width: maxWidth - 16, height: .greatestFiniteMagnitude))
        let tooltipWidth = min(fittingSize.width + 16, maxWidth)
        let tooltipHeight = fittingSize.height + 12

        // Center horizontally on anchor, clamp to parent bounds
        var x = anchorRect.midX - tooltipWidth / 2
        x = max(8, min(x, parentView.bounds.width - tooltipWidth - 8))

        // Prefer above the anchor rect
        let spacing: CGFloat = 4
        var y = anchorRect.minY - tooltipHeight - spacing
        if y < parentView.safeAreaInsets.top {
            // Not enough space above, show below
            y = anchorRect.maxY + spacing
        }

        frame = CGRect(x: x, y: y, width: tooltipWidth, height: tooltipHeight)
        isHidden = false
    }

    func hide() {
        guard !isHidden else { return }
        isHidden = true
        removeFromSuperview()
    }
}
