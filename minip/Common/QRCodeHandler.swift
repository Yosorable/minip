//
//  QRCodeHandler.swift
//  minip
//
//  Created by LZY on 2025/2/13.
//

import SafariServices
import UIKit

class QRCodeHandler {
    static let shared = QRCodeHandler()

    func handle(code: String, viewController: UIViewController? = nil) {
        var succeed = false
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedCode.starts(with: "https://") || trimmedCode.starts(with: "http://") {
            succeed = handleWebsiteURL(url: URL(string: code), parentVC: viewController)
        } else if trimmedCode.starts(with: "minip://") {
            do {
                try URLSchemeHandler.shared.handle(trimmedCode)
                succeed = true
            } catch {}
        } else if trimmedCode.starts(with: "["), let data = trimmedCode.data(using: .utf8), let actions = try? JSONSerialization.jsonObject(with: data, options: []) as? [String], let vc = viewController {
            // multiple actions to select
            var valid = true
            var actData = [(String, String, String)]()
            for act in actions {
                let trimed = act.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimed.starts(with: "minip://"), let comp = NSURLComponents(string: trimed), let host = comp.host, let path = comp.path else {
                    valid = false
                    break
                }
                actData.append((host, path.deletingPrefixSuffix("/"), trimed))
            }
            if valid {
                let alert = UIAlertController(title: "Actions", message: "select one action to execute", preferredStyle: .alert)
                for item in actData {
                    let action = UIAlertAction(title: "[\(item.0)] \(item.1)", style: .default) { _ in
                        do {
                            try URLSchemeHandler.shared.handle(item.2)
                        } catch {
                            ShowSimpleError(err: error)
                        }
                    }
                    alert.addAction(action)
                }

                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alert.addAction(cancelAction)
                vc.present(alert, animated: true)
                succeed = true
            }
        }

        if !succeed {
            if let vc = viewController ?? GetTopViewController() {
                let navVC = UINavigationController(rootViewController: TextDisplayViewController(text: code, title: "QRCode Result"))
                vc.present(navVC, animated: true)
            }
        }
    }

    private func handleWebsiteURL(url: URL?, parentVC: UIViewController?) -> Bool {
        guard let url = url else { return false }
        let svc = SFSafariViewController(url: url)
        if let vc = parentVC ?? GetTopViewController() {
            vc.present(svc, animated: true)
            return true
        }
        return false
    }
}
