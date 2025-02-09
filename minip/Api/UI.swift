//
//  Untitled.swift
//  minip
//
//  Created by LZY on 2025/2/9.
//

import UIKit
import PKHUD
import AVFoundation
import AVKit

extension MinipApi {
    func setNavigationBarTitle(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        guard let title = (param.data as? [String: String])?["title"] else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        vc.title = title
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }
    
    func setNavigationBarColor(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        let data = param.data as? [String: Any]
        guard
            let foregroundColor = (data?["foregroundColor"] as? String),
            let backgroundColor = (data?["backgroundColor"] as? String),
            let fColor = UIColor(hex: foregroundColor),
            let bColor = UIColor(hex: backgroundColor)
        else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let animated = (data?["animated"] as? Bool) ?? true
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = bColor
        appearance.titleTextAttributes = [.foregroundColor: fColor]
        if animated {
            UIView.animate(withDuration: 0.3) {
                vc.navigationController?.navigationBar.standardAppearance = appearance
                vc.navigationController?.navigationBar.scrollEdgeAppearance = appearance
            }
        } else {
            vc.navigationController?.navigationBar.standardAppearance = appearance
            vc.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }
    
    func enablePullDownRefresh(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        vc.addRefreshControl()
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }
    
    func disablePullDownRefresh(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void){
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        if let rf = vc.refreshControl {
            rf.endRefreshing()
            vc.refreshControl = nil
            rf.removeFromSuperview()
        }
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }
    
    func startPullDownRefresh(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        if let rf = vc.refreshControl {
            rf.beginRefreshing()
        }
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }
    
    func stopPullDownRefresh(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        vc.refreshControl?.endRefreshing()
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }
    
    func showHUD(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let _ = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        let parameters = param.data as? [String: Any]
        guard var type = parameters?["type"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let title = parameters?["title"] as? String
        let subTitle = parameters?["subTitle"] as? String
        let delay = parameters?["delay"] as? Double
        
        var contentType: HUDContentType?
        
        type = type.lowercased()
        if type == "success" {
            contentType = .labeledSuccess(title: title, subtitle: subTitle)
        } else if type == "error" {
            contentType = .labeledError(title: title, subtitle: subTitle)
        } else if type == "progress" {
            contentType = .labeledProgress(title: title, subtitle: subTitle)
        } else if type == "label" {
            if title == nil && subTitle == nil {
                return
            } else if subTitle == nil {
                contentType = .label(title)
            } else if title == nil {
                contentType = .label(subTitle)
            } else {
                contentType = .label("\(title ?? "")\n\(subTitle ?? "")")
            }
        }
        
        guard let ct = contentType else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        if let d = delay {
            HUD.flash(ct, delay: d / 1000) { res in
                replyHandler(InteropUtils.succeed().toJsonString(), nil)
            }
        } else {
            HUD.flash(ct, delay: 0.5) { res in
                replyHandler(InteropUtils.succeed().toJsonString(), nil)
            }
        }
    }
    
    func hideHUD(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let _ = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        HUD.hide { _ in
            replyHandler(InteropUtils.succeed().toJsonString(), nil)
        }
    }
    
    struct AlertAction: Codable {
        var title: String?
        var style: String?
        var key: String // 回调参数
    }

    struct AlertConfig: Codable {
        var title: String?
        var message: String?
        var preferredStyle: String?
        var actions: [AlertAction]
    }
    
    func showAlert(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        let decoder = JSONDecoder()
        guard let data = param.data,
              let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
              let config = try? decoder.decode(AlertConfig.self, from: jsonData) else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let alert = UIAlertController(title: config.title, message: config.message, preferredStyle: config.preferredStyle == "actionSheet" ? .actionSheet : .alert)
        config.actions.forEach { act in
            var style = UIAlertAction.Style.default
            if act.style == "cancel" {
                style = .cancel
            } else if act.style == "destructive" {
                style = .destructive
            }
            alert.addAction(UIAlertAction(title: act.title, style: style) { _ in
                let res = InteropUtils.succeedWithData(data: act.key).toJsonString()
                replyHandler(res, nil)
            })
        }
        alert.view.tintColor = vc.view.tintColor
        
        if let ppc = alert.popoverPresentationController {
            ppc.sourceView = vc.view
            ppc.sourceRect = CGRectMake(vc.view.bounds.size.width / 2.0, vc.view.bounds.size.height / 2.0, 1.0, 1.0)
        }
        vc.present(alert, animated: true, completion: nil)
    }
    
    func previewImage(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        guard let urlStr = (param.data as? [String: String])?["url"],
              let url = URL(string: urlStr) else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        PreviewImage(url: url)
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }
    
    func previewVideo(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        guard let urlStr = (param.data as? [String: String])?["url"],
              let url = URL(string: urlStr) else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let player = AVPlayer(url: url)
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        vc.present(playerVC, animated: true) {
            playerVC.player?.play()
        }
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }
}
