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
    var reloadPageFunc: (()->Void)?
    var closeFunc: (()->Void)?
    var parentVC: UIViewController
    init(appInfo: AppInfo, reloadPageFunc: (()->Void)? = nil, closeFunc: (()->Void)? = nil, parentVC: UIViewController) {
        self.appInfo = appInfo
        self.reloadPageFunc = reloadPageFunc
        self.closeFunc = closeFunc
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
            view.tintColor = UIColor(hex: tintColor)
        }

        panModalSetNeedsLayoutUpdate()

        var iconURL: URL?
        if let icon = appInfo.icon {
            if icon.starts(with: "http://") || icon.starts(with: "https://") {
                iconURL = URL(string: icon)
            } else {
                iconURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPolyfill(path: appInfo.name).appendingPolyfill(path: icon)
            }
        }

        let subview = UIHostingController(
            rootView:
            VStack {
                let noIconView = RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary, lineWidth: 1)
                    .frame(width: 60, height: 60)
                VStack {
                    if let iconURL = iconURL {
                        if iconURL.scheme == "file", let img = UIImage(contentsOfFile: iconURL.path) {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipped()
                                .cornerRadius(10)
                                .shadow(radius: 2)
                        } else if iconURL.scheme == "http" || iconURL.scheme == "https" {
                            KFImage(iconURL)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .clipped()
                                .cornerRadius(10)
                                .shadow(radius: 2)
                        } else {
                            noIconView
                        }
                    } else {
                        noIconView
                    }
                }
                .padding(.top)

                VStack {
                    Text(appInfo.name)
                        .lineLimit(1)
                        .padding(.top)
                    Spacer()
                    Text("v" + (appInfo.version ?? "0.0.0"))
                        .font(.system(size: 10))
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                    Text("@\(appInfo.author ?? "no_author")")
                        .font(.system(size: 10))
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                    Text(appInfo.appId)
                        .font(.system(size: 10))
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                }
                .frame(height: 60)
                if let website = appInfo.website, let url = URL(string: website) {
                    Link(website, destination: url)
                        .font(.system(size: 13))
                }
                VStack {
                    Text(appInfo.description ?? "No description"
                    )
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                }
                .padding(.top, 3)

                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        Button { [weak self] in
                            self?.dismiss(animated: true, completion: { [weak self] in
                                guard let this = self else { return }
                                let ss = MiniAppSettingsViewController(style: .insetGrouped, app: this.appInfo)
                                let vc = BackableNavigationController(rootViewController: ss)
                                vc.addPanGesture(vc: ss)
                                vc.modalPresentationStyle = .overFullScreen
                                this.parentVC.present(vc, animated: true)
                            })

                        } label: {
                            VStack {
                                Image(systemName: "gear").font(.system(size: 30))
                                    .frame(width: 55, height: 55)
                                    .background(Color("BlockButtonBackground", bundle: nil))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                Text("Settings")
                                    .font(.caption)
                            }
                        }

                        Button { [weak self] in
                            self?.dismiss(animated: true, completion: { self?.reloadPageFunc?() })
                        } label: {
                            VStack {
                                Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 30))
                                    .frame(width: 55, height: 55)
                                    .background(Color("BlockButtonBackground", bundle: nil))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                Text("Reload")
                                    .font(.caption)
                            }
                        }

                        if let cls = self.closeFunc {
                            Button { [weak self] in
                                self?.dismiss(animated: true, completion: cls)
                                cls()
                            } label: {
                                VStack {
                                    Image(systemName: "xmark").font(.system(size: 30))
                                        .frame(width: 55, height: 55)
                                        .background(Color("BlockButtonBackground", bundle: nil))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    Text("Close")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 8)
                Spacer()
            }
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
