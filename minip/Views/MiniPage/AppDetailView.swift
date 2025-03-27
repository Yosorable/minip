//
//  AppDetailView.swift
//  minip
//
//  Created by LZY on 2025/3/20.
//

import Kingfisher
import SwiftUI

struct AppDetailView: View {
    let appInfo: AppInfo
    weak var parentVC: UIViewController?
    weak var detailVC: AppDetailViewController?
    var iconURL: URL?
    init(appInfo: AppInfo, parentVC: UIViewController?, detailVC: AppDetailViewController?) {
        self.appInfo = appInfo
        self.parentVC = parentVC
        self.detailVC = detailVC

        if let icon = appInfo.icon {
            if icon.starts(with: "http://") || icon.starts(with: "https://") {
                self.iconURL = URL(string: icon)
            } else {
                self.iconURL = Global.shared.documentsRootURL.appendingPolyfill(path: self.appInfo.name).appendingPolyfill(path: icon)
            }
        }
    }

    var body: some View {
        VStack {
            VStack {
                self.iconView()
            }
            .padding(.top)

            VStack {
                Text(self.appInfo.name)
                    .lineLimit(1)
                    .padding(.top)
                Spacer()
                Text("v" + (self.appInfo.version ?? "0.0.0"))
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .foregroundColor(.secondary)
                Text("@\(self.appInfo.author ?? "no_author")")
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .foregroundColor(.secondary)
                Text(self.appInfo.appId)
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            .frame(height: 60)

            if let website = appInfo.website, let url = URL(string: website) {
                Link(website, destination: url)
                    .font(.system(size: 10))
            }

            VStack {
                self.description()
            }
            .padding(.top, 3)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    self.gearButton()
                    self.reloadButton()
                    self.consoleButton()
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 8)
            Spacer()
        }
    }

    func iconView() -> some View {
        if let iconURL = iconURL {
            if iconURL.scheme == "file", let img = UIImage(contentsOfFile: iconURL.path) {
                return AnyView(
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(10)
                        .shadow(radius: 2)
                )
            } else if iconURL.scheme == "http" || iconURL.scheme == "https" {
                return AnyView(
                    KFImage(iconURL)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(10)
                        .shadow(radius: 2)
                )
            }
        }
        return AnyView(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary, lineWidth: 1)
                .frame(width: 60, height: 60)
        )
    }

    func description() -> some View {
        if #available(iOS 15, *), let desc = self.appInfo.description, let md = try? AttributedString(markdown: desc) {
            Text(md)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        } else {
            Text(self.appInfo.description ?? "No description")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }

    func gearButton() -> some View {
        Button {
            self.detailVC?.dismiss(animated: true, completion: {
                let this = self
                let ss = MiniAppSettingsViewController(style: .insetGrouped, app: this.appInfo)
                let vc = BackableNavigationController(rootViewController: ss)
                vc.addPanGesture(vc: ss)
                vc.modalPresentationStyle = .overFullScreen
                this.parentVC?.present(vc, animated: true)
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
    }

    func reloadButton() -> some View {
        Button {
            self.detailVC?.dismiss(animated: true, completion: { self.detailVC?.reloadPageFunc?() })
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
    }

    func consoleButton() -> some View {
        Button {
            let pvc = self.parentVC
            self.detailVC?.dismiss(animated: true, completion: {
                let vc = ConsoleViewController()
                let nvc = UINavigationController(rootViewController: vc)
                nvc.view.tintColor = pvc?.view.tintColor
                if #available(iOS 15.0, *) {
                    if let presentVC = nvc.sheetPresentationController {
                        presentVC.detents = [.medium()]
                    }
                }
                pvc?.present(nvc, animated: true)
            })
        } label: {
            VStack {
                Image(systemName: "apple.terminal").font(.system(size: 30))
                    .frame(width: 55, height: 55)
                    .background(Color("BlockButtonBackground", bundle: nil))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text("Console")
                    .font(.caption)
            }
        }
    }
}
