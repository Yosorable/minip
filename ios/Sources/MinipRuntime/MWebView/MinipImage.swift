//
//  MinipImage.swift
//  minip
//
//  Created by LZY on 2025/3/23.
//

import Kingfisher
import WebKit

class MinipImage: NSObject, WKURLSchemeHandler {
    private let lock = NSLock()
    private var activeTasks = Set<ObjectIdentifier>()
    static let shared = MinipImage()

    private func taskID(_ task: WKURLSchemeTask) -> ObjectIdentifier {
        ObjectIdentifier(task as AnyObject)
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        lock.lock()
        activeTasks.insert(taskID(urlSchemeTask))
        lock.unlock()

        if let url = urlSchemeTask.request.url {
            var components = URLComponents(string: url.absoluteString)
            let originScheme = components?.scheme
            components?.scheme = originScheme == "minipimghttp" ? "http" : "https"
            if let realURL = components?.url {
                let cacheKey = realURL.cacheKey
                let cache = ImageCache.default

                DispatchQueue.global(qos: .userInitiated).async {
                    if let data = try? cache.diskStorage.value(forKey: cacheKey) {
                        self.respond(urlSchemeTask: urlSchemeTask, url: realURL, data: data)
                        return
                    }

                    ImageDownloader.default.downloadImage(with: realURL, options: [.callbackQueue(.dispatch(.global(qos: .userInitiated)))]) { [weak self] result in
                        switch result {
                        case .success(let value):
                            cache.store(value.image, original: value.originalData, forKey: cacheKey)
                            self?.respond(urlSchemeTask: urlSchemeTask, url: realURL, data: value.originalData)
                        case .failure(let err):
                            logger.error("[MinipImage] \(realURL) error: \(err.localizedDescription)")
                            if self?.removeTask(for: urlSchemeTask) == true {
                                urlSchemeTask.didFailWithError(err)
                            }
                        }
                    }
                }
                return
            }
        }

        logger.error("[MinipImage] \(urlSchemeTask.request.url?.absoluteString ?? "URL is nil") error: Invalid image URL in WKURLSchemeHandler")
        urlSchemeTask.didFailWithError(
            NSError(
                domain: "MinipImage", code: 400,
                userInfo: [
                    NSLocalizedDescriptionKey: "Invalid image URL in WKURLSchemeHandler",
                    NSLocalizedFailureReasonErrorKey: urlSchemeTask.request.url?.absoluteString ?? "URL is nil",
                ]
            )
        )
    }

    private func respond(urlSchemeTask: WKURLSchemeTask, url: URL, data: Data) {
        guard removeTask(for: urlSchemeTask) else { return }
        let mimeType = data.imageMIMEType ?? "application/octet-stream"
        let headers = [
            "Content-Type": mimeType,
            "Content-Length": "\(data.count)",
        ]
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: headers)!
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        removeTask(for: urlSchemeTask)
    }

    @discardableResult
    private func removeTask(for urlSchemeTask: WKURLSchemeTask) -> Bool {
        lock.lock()
        let removed = activeTasks.remove(taskID(urlSchemeTask)) != nil
        lock.unlock()
        return removed
    }
}

extension Data {
    fileprivate var imageMIMEType: String? {
        guard count > 0 else { return nil }
        let byte = self[0]
        switch byte {
        case 0xFF: return "image/jpeg"
        case 0x89: return "image/png"
        case 0x47: return "image/gif"
        case 0x52: return "image/webp"
        case 0x49, 0x4D: return "image/tiff"
        case 0x00: return "image/heic"
        default: return nil
        }
    }
}
