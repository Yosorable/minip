//
//  Route.swift
//  minip
//
//  Created by LZY on 2025/2/9.
//

import Foundation
import SafariServices

extension MinipApi {
    func navigateTo(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        let data = (param.data as? [String: String])
        guard let page = data?["page"] else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let title = data?["title"]

        // released page
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        let newVC = MiniPageViewController(app: vc.app, page: page, title: title)
        if vc.isRoot {
            newVC.hidesBottomBarWhenPushed = true
        }
        vc.navigationController?.pushViewController(newVC, animated: true)
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }

    func navigateBack(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        var delta = ((param.data as? [String: Any])?["delta"] as? Int) ?? 1
        if vc.navigationController?.topViewController == vc {
            while delta > 0, (vc.navigationController?.viewControllers.count ?? 1) > 1 {
                delta -= 1
                vc.navigationController?.popViewController(animated: true)
            }
        }
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }

    func redirectTo(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        let data = (param.data as? [String: String])
        guard let page = data?["page"] else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let title = data?["title"]

        // released page
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        vc.redirectTo(page: page, title: title)
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }

    func openWebsite(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        guard let urlStr = (param.data as? [String: String])?["url"], let url = URL(string: urlStr) else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let safariVC = SFSafariViewController(url: url)
        if let tc = vc.app.tintColor, let co = UIColor(hex: tc) {
            safariVC.preferredControlTintColor = co
        }
        vc.present(safariVC, animated: true)
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }

    func openSettings(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        let ss = MiniAppSettingsViewController(style: .insetGrouped, app: vc.app)
        let navVC = BackableNavigationController(rootViewController: ss)
        navVC.addPanGesture(vc: ss)
        navVC.modalPresentationStyle = .overFullScreen
        vc.present(navVC, animated: true)
    }
}
