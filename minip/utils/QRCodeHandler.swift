//
//  QRCodeHandler.swift
//  minip
//
//  Created by LZY on 2025/2/13.
//

import UIKit
import SafariServices

class QRCodeHandler {
    static let shared = QRCodeHandler()
    
    func handle(code: String, viewController: UIViewController? = nil) {
        var succeed = false
        if code.starts(with: "https://") || code.starts(with: "http://") {
            succeed = handleWebsiteURL(url: URL(string: code), parentVC: viewController)
        }
        
        // todo: handle custom urlscheme
        
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
