//
//  AppDetailViewController.swift
//  minip
//
//  Created by LZY on 2024/3/5.
//

import Foundation
import Kingfisher
import PanModal
import SwiftUI
import UIKit

class AppDetailViewController: UIViewController {
    var appInfo: AppInfo
    var reloadPageFunc: (() -> Void)?
    weak var parentVC: UIViewController?
    init(appInfo: AppInfo, reloadPageFunc: (() -> Void)? = nil, parentVC: UIViewController) {
        self.appInfo = appInfo
        self.reloadPageFunc = reloadPageFunc
        self.parentVC = parentVC
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        if let colorScheme = MiniAppManager.shared.openedApp?.colorScheme {
            if colorScheme == "dark" {
                overrideUserInterfaceStyle = .dark
            } else if colorScheme == "light" {
                overrideUserInterfaceStyle = .light
            }
        }

        if let tintColor = MiniAppManager.shared.openedApp?.tintColor {
            view.tintColor = UIColor(hexOrCSSName: tintColor)
        }

        panModalSetNeedsLayoutUpdate()

        let subview = UIHostingController(
            rootView: AppDetailView(appInfo: appInfo, parentVC: parentVC, detailVC: self)
        ).view
        guard let subview = subview else {
            return
        }

        view.addSubview(subview)

        subview.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            subview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            subview.topAnchor.constraint(equalTo: view.topAnchor),
            subview.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if self.appInfo.orientation == "landscape" {
            return .landscape
        } else if self.appInfo.orientation == "portrait" {
            return .portrait
        }
        return .all
    }
}

extension AppDetailViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }

    var shortFormHeight: PanModalHeight {
        return .contentHeight(300)
    }

    var longFormHeight: PanModalHeight {
        return .maxHeightWithTopInset(40)
    }
}
