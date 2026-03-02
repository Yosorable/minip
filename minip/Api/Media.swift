//
//  Media.swift
//  minip
//
//  Created by LZY on 2026/3/2.
//

import AVKit
import Kingfisher
import UIKit

extension MinipApi {
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
}
