//
//  Untitled.swift
//  minip
//
//  Created by LZY on 2025/2/9.
//

import UIKit
import AVFoundation
import AVKit
import ProgressHUD

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
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = bColor
        appearance.titleTextAttributes = [.foregroundColor: fColor]
        vc.navigationController?.navigationBar.standardAppearance = appearance
        vc.navigationController?.navigationBar.scrollEdgeAppearance = appearance
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
        let subTitle = (parameters?["subTitle"] as? String) ?? (parameters?["message"] as? String)
        let delay = parameters?["delay"] as? Double
        let interaction = (parameters?["interaction"] as? Bool) ?? true

        var msg: String?
        if title != nil {
            msg = title
        }
        if subTitle != nil {
            if msg != nil {
                msg! += "\n" + subTitle!
            } else {
                msg = subTitle
            }
        }
        var dl: TimeInterval?
        if let d = delay {
            dl = d / 1000
        }
        type = type.lowercased()
        if type == "success" {
            ProgressHUD.succeed(msg, interaction: interaction, delay: dl)
        } else if type == "error" {
            ProgressHUD.failed(msg, interaction: interaction, delay: dl)
        } else if type == "progress" {
            ProgressHUD.animate(msg, interaction: interaction)
        } else if type == "label" || type == "banner" {
            ProgressHUD.banner(title, subTitle)
        } else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }
    
    func hideHUD(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let _ = param.webView?.holderObject as? MiniPageViewController else {
            return
        }

        ProgressHUD.dismiss()
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }
    
    struct AlertAction: Codable {
        var title: String?
        var style: String?
        var key: String // callback parameter
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
