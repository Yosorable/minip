import AVKit
import Kingfisher
import UIKit

extension MinipApi {
    func previewImage(param: Parameter) async throws {
        let controller = try param.requirePresentation()
        let source = try param.string("url").deletingPrefix("minipimg").deletingPrefix("minip")
        guard let url = URL(string: source), url.scheme != nil else { throw MinipError.invalidArgument("url") }

        var sourceRect: CGRect?
        if let value = param.data["rect"] {
            guard case .object(let rect) = value,
                  let x = rect["x"]?.double, let y = rect["y"]?.double,
                  let width = rect["width"]?.double, let height = rect["height"]?.double else {
                throw MinipError.invalidArgument("rect")
            }
            let zoom = param.webView.scrollView.zoomScale
            let inset = param.webView.scrollView.adjustedContentInset
            sourceRect = param.webView.convert(CGRect(x: x * zoom + inset.left, y: y * zoom + inset.top, width: width * zoom, height: height * zoom), to: nil)
        }

        var thumbnail: UIImage?
        if sourceRect != nil {
            if url.isFileURL {
                thumbnail = UIImage(contentsOfFile: url.path(percentEncoded: false))
            } else {
                thumbnail = await withCheckedContinuation { continuation in
                    ImageCache.default.retrieveImage(forKey: url.absoluteString) { result in
                        continuation.resume(returning: try? result.get().image)
                    }
                }
            }
        }
        _ = try param.requirePresentation()
        minip.previewImage(
            url: url, vc: controller, sourceRect: sourceRect, thumbnailImage: thumbnail,
            onDismiss: {
                param.webView.evaluateJavaScript("if(window.__minipPreviewElement){window.__minipPreviewElement.style.visibility='';window.__minipPreviewElement=null}")
            },
            onPresentSnapshotReady: {
                param.webView.evaluateJavaScript("if(window.__minipPreviewElement) window.__minipPreviewElement.style.visibility='hidden'")
            },
            fetchSourceRect: { completion in
                let script = "(function(){var el=window.__minipPreviewElement;if(!el)return null;var r=el.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height};})()"
                param.webView.evaluateJavaScript(script) { result, _ in
                    guard let rect = result as? [String: Double],
                          let x = rect["x"], let y = rect["y"], let width = rect["width"], let height = rect["height"] else {
                        completion(nil)
                        return
                    }
                    let zoom = param.webView.scrollView.zoomScale
                    let inset = param.webView.scrollView.adjustedContentInset
                    completion(param.webView.convert(CGRect(x: x * zoom + inset.left, y: y * zoom + inset.top, width: width * zoom, height: height * zoom), to: nil))
                }
            })
    }

    func previewVideo(param: Parameter) throws {
        let controller = try param.requirePresentation()
        guard let url = URL(string: try param.string("url")), url.scheme != nil else { throw MinipError.invalidArgument("url") }
        let player = AVPlayer(url: url)
        let preview = AVPlayerViewController()
        preview.allowsPictureInPicturePlayback = false
        preview.player = player
        controller.present(preview, animated: true) { preview.player?.play() }
    }
}
