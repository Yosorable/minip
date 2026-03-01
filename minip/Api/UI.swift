//
//  Untitled.swift
//  minip
//
//  Created by LZY on 2025/2/9.
//

import AVFoundation
import AVKit
import Kingfisher
import ProgressHUD
import UIKit

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
            let fColor = UIColor(hexOrCSSName: foregroundColor),
            let bColor = UIColor(hexOrCSSName: backgroundColor)
        else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = bColor
        appearance.titleTextAttributes = [.foregroundColor: fColor]
        appearance.shadowColor = .clear
        if let tabVC = vc.tabBarController {
            tabVC.viewControllers?.forEach { ele in
                if let navc = ele as? UINavigationController {
                    navc.navigationBar.standardAppearance = appearance
                    navc.navigationBar.scrollEdgeAppearance = appearance
                } else {
                    ele.navigationController?.navigationBar.standardAppearance = appearance
                    ele.navigationController?.navigationBar.scrollEdgeAppearance = appearance
                }
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

    func disablePullDownRefresh(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
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
        guard param.webView?.holderObject as? MiniPageViewController != nil else {
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
            if let delay = dl {
                ProgressHUD.banner(title, subTitle, delay: delay)
            } else {
                ProgressHUD.banner(title, subTitle)
            }
        } else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }

    func hideHUD(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard param.webView?.holderObject as? MiniPageViewController != nil else {
            return
        }

        ProgressHUD.dismiss()
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }

    struct AlertInput: Codable {
        var key: String  // callback parameter
        var type: String?  // text (default), password, number
        var title: String?
        var defaultValue: String?
    }

    struct AlertAction: Codable {
        var title: String?
        var style: String?
        var key: String  // callback parameter
    }

    struct AlertConfig: Codable {
        var title: String?
        var message: String?
        var preferredStyle: String?
        var inputs: [AlertInput]?
        var actions: [AlertAction]
    }

    func showAlert(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        let decoder = JSONDecoder()
        guard let data = param.data,
            let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
            let config = try? decoder.decode(AlertConfig.self, from: jsonData)
        else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let alert = UIAlertController(title: config.title, message: config.message, preferredStyle: config.preferredStyle == "actionSheet" ? .actionSheet : .alert)
        if config.preferredStyle != "actionSheet", let inputs = config.inputs {
            for ipt in inputs {
                alert.addTextField(configurationHandler: { tf in
                    tf.placeholder = ipt.title ?? ""
                    if ipt.type == "password" {
                        tf.isSecureTextEntry = true
                    } else if ipt.type == "number" {
                        tf.keyboardType = .numberPad
                    }

                    if let dft = ipt.defaultValue {
                        tf.text = dft
                    }
                })
            }
        }
        for act in config.actions {
            var style = UIAlertAction.Style.default
            if act.style == "cancel" {
                style = .cancel
            } else if act.style == "destructive" {
                style = .destructive
            }
            alert.addAction(
                UIAlertAction(title: act.title, style: style) { _ in
                    struct AlertWithInputsRes: Codable {
                        var action: String
                        var inputs: [String: String]
                    }
                    var res = AlertWithInputsRes(action: act.key, inputs: [:])

                    if let cfg = config.inputs, let tfs = alert.textFields {
                        for (idx, tf) in tfs.enumerated() {
                            res.inputs[cfg[idx].key] = tf.text
                        }
                    }

                    replyHandler(InteropUtils.succeedWithData(data: res).toJsonString(), nil)
                })
        }
        alert.view.tintColor = vc.view.tintColor

        if let ppc = alert.popoverPresentationController {
            ppc.sourceView = vc.view
            ppc.sourceRect = vc.view.bounds
        }
        vc.present(alert, animated: true, completion: nil)
    }

    func previewImage(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        guard let data = param.data as? [String: Any],
            let urlStr = data["url"] as? String,
            let url = URL(string: urlStr.deletingPrefix("minipimg").deletingPrefix("minip"))
        else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }

        var sourceRect: CGRect?
        if let rectDict = data["rect"] as? [String: Double],
            let x = rectDict["x"], let y = rectDict["y"],
            let width = rectDict["width"], let height = rectDict["height"],
            let webView = param.webView
        {
            // getBoundingClientRect() returns CSS pixels relative to the visual viewport.
            // Convert to UIKit points: multiply by zoomScale, then offset by content inset.
            let zoom = webView.scrollView.zoomScale
            let inset = webView.scrollView.adjustedContentInset
            let webViewRect = CGRect(x: x * zoom + inset.left, y: y * zoom + inset.top, width: width * zoom, height: height * zoom)
            sourceRect = webView.convert(webViewRect, to: nil)
        }

        let presentPreview = { (thumbnailImage: UIImage?) in
            minip.previewImage(
                url: url, vc: vc, sourceRect: sourceRect, thumbnailImage: thumbnailImage,
                onDismiss: {
                    param.webView?.evaluateJavaScript("if(window.__minipPreviewElement){window.__minipPreviewElement.style.visibility='';window.__minipPreviewElement=null}")
                },
                onPresentSnapshotReady: {
                    param.webView?.evaluateJavaScript("if(window.__minipPreviewElement) window.__minipPreviewElement.style.visibility='hidden'")
                },
                fetchSourceRect: { completion in
                    guard let webView = param.webView else {
                        completion(nil)
                        return
                    }
                    let js =
                        "(function(){ var el = window.__minipPreviewElement; if (!el) return null; var r = el.getBoundingClientRect(); return JSON.stringify({x:r.x,y:r.y,width:r.width,height:r.height}); })()"
                    webView.evaluateJavaScript(js) { result, _ in
                        guard let jsonStr = result as? String,
                            let data = jsonStr.data(using: .utf8),
                            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Double],
                            let x = dict["x"], let y = dict["y"],
                            let w = dict["width"], let h = dict["height"]
                        else {
                            completion(nil)
                            return
                        }
                        let zoom = webView.scrollView.zoomScale
                        let inset = webView.scrollView.adjustedContentInset
                        let webViewRect = CGRect(x: x * zoom + inset.left, y: y * zoom + inset.top, width: w * zoom, height: h * zoom)
                        completion(webView.convert(webViewRect, to: nil))
                    }
                })
        }

        if sourceRect != nil {
            ImageCache.default.retrieveImage(forKey: url.absoluteString) { result in
                let image = try? result.get().image
                DispatchQueue.main.async { presentPreview(image) }
            }
        } else {
            presentPreview(nil)
        }
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }

    func previewVideo(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        guard let urlStr = (param.data as? [String: String])?["url"],
            let url = URL(string: urlStr)
        else {
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

    // MARK: Picker

    func showPicker(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        let data = param.data as? [String: Any]
        guard
            let typeStr = data?["type"] as? String,
            let pickerType = PickerType(rawValue: typeStr),
            let pickerData = data?["data"],
            let jsonPickerData = try? JSONSerialization.data(withJSONObject: pickerData, options: [])
        else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let decoder = JSONDecoder()
        let pvc = PickerViewController()
        pvc.pickerType = pickerType
        if pickerType == .singleColumn {
            guard let pickerData = try? decoder.decode(SingleColumnPickerView.Data.self, from: jsonPickerData) else {
                replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
                return
            }
            pvc.singlePickerData = pickerData
            pvc.onConfirmed = { [weak pvc] in
                replyHandler(InteropUtils.succeedWithData(data: pvc?.singlePickerResult).toJsonString(), nil)
            }
        } else if pickerType == .multipleColumns {
            guard let pickerData = try? decoder.decode(MultiColumnsPickerView.Data.self, from: jsonPickerData) else {
                replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
                return
            }
            pvc.multiPickerData = pickerData
            pvc.onConfirmed = { [weak pvc] in
                replyHandler(InteropUtils.succeedWithData(data: pvc?.multiPickerResult).toJsonString(), nil)
            }
        } else if pickerType == .date || pickerType == .time {
            guard let pickerData = try? decoder.decode(DatePickerView.Data.self, from: jsonPickerData) else {
                replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
                return
            }
            pvc.datePickerData = pickerData
            pvc.onConfirmed = { [weak pvc] in
                replyHandler(InteropUtils.succeedWithData(data: pvc?.datePickerResult).toJsonString(), nil)
            }
        } else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        pvc.onCanceled = {
            replyHandler(InteropUtils.succeed(msg: "Canceled").toJsonString(), nil)
        }

        pvc.view.tintColor = vc.view.tintColor
        vc.present(pvc, animated: true)
    }
}
