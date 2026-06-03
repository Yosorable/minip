//
//  MinipRequest.swift
//  minip
//
//  Created by LZY on 2024/5/1.
//

import WebKit

class MinipRequest: NSObject, WKURLSchemeHandler {
    private let lock = NSLock()
    private var schemeHandlers: [ObjectIdentifier: URLSessionDataTask] = [:]
    static let shared = MinipRequest()

    private func taskID(_ task: WKURLSchemeTask) -> ObjectIdentifier {
        ObjectIdentifier(task as AnyObject)
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
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

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self, self.removeTask(for: urlSchemeTask) != nil else { return }

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

            guard let resURL = response.url,
                let newResponse = HTTPURLResponse(
                    url: resURL,
                    statusCode: response.statusCode,
                    httpVersion: nil,
                    headerFields: modifiedHeaders
                )
            else {
                urlSchemeTask.didFailWithError(NSError(domain: "MinipRequestHandlerError", code: 500, userInfo: nil))
                return
            }

            urlSchemeTask.didReceive(newResponse)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        }

        lock.lock()
        schemeHandlers[taskID(urlSchemeTask)] = task
        lock.unlock()

        task.resume()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        removeTask(for: urlSchemeTask)?.cancel()
    }

    @discardableResult
    private func removeTask(for urlSchemeTask: WKURLSchemeTask) -> URLSessionDataTask? {
        lock.lock()
        let task = schemeHandlers.removeValue(forKey: taskID(urlSchemeTask))
        lock.unlock()
        return task
    }
}

class MinipURLSchemePing: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let request = urlSchemeTask.request

        var res = "pong".data(using: .utf8)!
        if let data = request.httpBody {
            res.append(" ".data(using: .utf8)!)
            res.append(data)
        }

        let url = request.url!
        let headers = [
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST",
        ]
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: headers)!
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(res)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}
