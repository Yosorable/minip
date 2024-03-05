//
//  AppDetailViewController.swift
//  minip
//
//  Created by LZY on 2024/3/5.
//

import Foundation
import UIKit
import PanModal
import SwiftUI
import Kingfisher

class AppDetailViewController: UIViewController {
    var appInfo: AppInfo
    var reloadPageFunc: (()->Void)?
    init(appInfo: AppInfo, reloadPageFunc: (()->Void)? = nil) {
        self.appInfo = appInfo
        self.reloadPageFunc = reloadPageFunc
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
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
                    let noIconView  = Rectangle()
                        .foregroundColor(.secondary)
                        .cornerRadius(10)
                        .frame(width: 60, height: 60)
                        .shadow(radius: 2)
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
                        Text(appInfo.version ?? "v0.0.0")
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
                    HStack {
                        Button {
                            self.dismiss(animated: true, completion: self.reloadPageFunc)
                        } label: {
                            VStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Reload")
                            }
                        }
                    }
                    .padding(.top, 8)
                    Spacer()
                }
                .padding(.horizontal, 20)
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
