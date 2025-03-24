//
//  MinipImage.swift
//  minip
//
//  Created by LZY on 2025/3/23.
//

import Kingfisher
import WebKit

class MinipImage: NSObject, WKURLSchemeHandler {
    var schemeHandlers: [Int: WKURLSchemeTask] = [:]
    static let shared = MinipImage()

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        schemeHandlers[urlSchemeTask.hash] = urlSchemeTask
        if let url = urlSchemeTask.request.url {
            var components = URLComponents(string: url.absoluteString)
            let originScheme = components?.scheme
            components?.scheme = originScheme == "minipimg_http" ? "http" : "https"
            if let url = components?.url {
                KingfisherManager.shared.retrieveImage(with: url, options: [.callbackQueue(.dispatch(.global(qos: .userInitiated)))], progressBlock: nil) { res in
                    var data: Data? = nil
                    switch res {
                    case .success(let dt):
                        data = dt.data()
                    case .failure:
                        break
                    }

                    if self.schemeHandlers[urlSchemeTask.hash] != nil {
                        if let data = data {
                            let response = URLResponse(url: url, mimeType: nil, expectedContentLength: data.count, textEncodingName: nil)
                            urlSchemeTask.didReceive(response)
                            urlSchemeTask.didReceive(data)
                            urlSchemeTask.didFinish()
                        } else {
                            urlSchemeTask.didFailWithError(NSError(domain: "MinipImage", code: 500, userInfo: nil))
                        }
                    }
                }

                return
            }
        }
        urlSchemeTask.didFailWithError(NSError(domain: "MinipImage", code: 400, userInfo: nil))
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        schemeHandlers.removeValue(forKey: urlSchemeTask.hash)
    }
}
