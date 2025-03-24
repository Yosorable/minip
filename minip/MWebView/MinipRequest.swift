//
//  MinipRequest.swift
//  minip
//
//  Created by LZY on 2024/5/1.
//

import WebKit

class MinipRequest: NSObject, WKURLSchemeHandler {
    var schemeHandlers: [Int: WKURLSchemeTask] = [:]
    static let shared = MinipRequest()

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        schemeHandlers[urlSchemeTask.hash] = urlSchemeTask

        var request = urlSchemeTask.request

        guard let minipURL = request.url, var comp = URLComponents(url: minipURL, resolvingAgainstBaseURL: false) else {
            urlSchemeTask.didFailWithError(NSError(domain: "MinipRequestHandlerError", code: 400, userInfo: nil))
            return
        }

        comp.scheme = comp.scheme == "miniphttp" ? "http" : "https"

        guard let newURL = comp.url else {
            urlSchemeTask.didFailWithError(NSError(domain: "MinipRequestHandlerError", code: 400, userInfo: nil))
            return
        }

        var handledHeaders = [String: String]()
        if let originHeaders = request.allHTTPHeaderFields {
            for (k, v) in originHeaders {
                if k.hasPrefix("minip-") {
                    handledHeaders[k.deletingPrefix("minip-")] = v
                } else {
                    handledHeaders[k] = v
                }
            }
        }
        request.allHTTPHeaderFields = handledHeaders

        request.url = newURL

        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                urlSchemeTask.didFailWithError(error)
                return
            }

            guard let response = response as? HTTPURLResponse, let data = data else {
                urlSchemeTask.didFailWithError(NSError(domain: "MinipRequestHandlerError", code: 500, userInfo: nil))
                return
            }

            var modifiedHeaders = response.allHeaderFields as? [String: String] ?? [:]
            modifiedHeaders["Access-Control-Allow-Origin"] = "*"

            guard let resURL = response.url, let newResponse = HTTPURLResponse(
                url: resURL,
                statusCode: response.statusCode,
                httpVersion: nil,
                headerFields: modifiedHeaders
            ) else {
                urlSchemeTask.didFailWithError(NSError(domain: "MinipRequestHandlerError", code: 500, userInfo: nil))
                return
            }

            if self.schemeHandlers[urlSchemeTask.hash] != nil {
                urlSchemeTask.didReceive(newResponse)
                urlSchemeTask.didReceive(data)
                urlSchemeTask.didFinish()
                self.schemeHandlers.removeValue(forKey: urlSchemeTask.hash)
            }
        }
        task.resume()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        schemeHandlers.removeValue(forKey: urlSchemeTask.hash)
    }
}

class MinipURLSchemePing: NSObject, WKURLSchemeHandler {
    var schemeHandlers: [Int: WKURLSchemeTask] = [:]

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        schemeHandlers[urlSchemeTask.hash] = urlSchemeTask

        let request = urlSchemeTask.request

        var res = "pong".data(using: .utf8)!
        if let data = request.httpBody {
            res.append(" ".data(using: .utf8)!)
            res.append(data)
        }

        if schemeHandlers[urlSchemeTask.hash] != nil {
            let url = request.url!
            let headers = [
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, POST",
//                "Content-Type": "application/json"
            ]
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: headers)!
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(res)
            urlSchemeTask.didFinish()
            schemeHandlers.removeValue(forKey: urlSchemeTask.hash)
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        schemeHandlers.removeValue(forKey: urlSchemeTask.hash)
    }
}
