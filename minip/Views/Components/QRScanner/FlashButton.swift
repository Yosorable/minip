//
//  FlashButton.swift
//  minip
//
//  Created by LZY on 2025/2/13.
//

import UIKit

final class FlashButton: UIButton {
    var blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        settings()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        settings()
    }

    // MARK: - Properties

    override var isSelected: Bool {
        didSet {
            UIView.animate(withDuration: 0.3, animations: {
                self.blurEffectView.effect = self.isSelected ? UIBlurEffect(style: .systemMaterialLight) : UIBlurEffect(style: .systemMaterialDark)
            })
            tintColor = isSelected ? UIColor(hex: "#5756CE") : .white
        }
    }
}

// MARK: - Private

private extension FlashButton {
    func settings() {
        clipsToBounds = true

        blurEffectView.frame = bounds
        blurEffectView.isUserInteractionEnabled = false
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(blurEffectView, at: 0)

        setImage(UIImage(systemName: "flashlight.off.fill", withConfiguration: UIImage.SymbolConfiguration(textStyle: .title1)), for: .normal)
        setImage(UIImage(systemName: "flashlight.on.fill", withConfiguration: UIImage.SymbolConfiguration(textStyle: .title1)), for: .selected)
        tintColor = .white

        if let imageView = imageView {
            bringSubviewToFront(imageView)
        }

        isSelected = false
    }
}
