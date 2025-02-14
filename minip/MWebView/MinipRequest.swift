//
//  MinipRequest.swift
//  minip
//
//  Created by LZY on 2024/5/1.
//

import WebKit

struct MinipRequestBody: Codable {
    var headers: [String: String]?
    var method: String?
    var body: String?
    var url: String
}

class MinipRequest: NSObject, WKURLSchemeHandler {
    var schemeHandlers: [Int: WKURLSchemeTask] = [:]

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        schemeHandlers[urlSchemeTask.hash] = urlSchemeTask

        let request = urlSchemeTask.request

        let decoder = JSONDecoder()
        guard let httpBody = request.httpBody, let bd = try? decoder.decode(MinipRequestBody.self, from: httpBody), let url = URL(string: bd.url) else {
            urlSchemeTask.didFailWithError(NSError(domain: "MinipRequestHandlerError", code: 2, userInfo: nil))
            return
        }

        var newRequest = URLRequest(url: url)
        newRequest.httpMethod = bd.method
        newRequest.httpBody = bd.body?.data(using: .utf8)
        newRequest.allHTTPHeaderFields = bd.headers

        let session = URLSession.shared
        let task = session.dataTask(with: newRequest) { data, response, error in
            if let error = error {
                urlSchemeTask.didFailWithError(error)
                return
            }

            guard let response = response, let data = data else {
                urlSchemeTask.didFailWithError(NSError(domain: "MinipRequestHandlerError", code: 3, userInfo: nil))
                return
            }

            if self.schemeHandlers[urlSchemeTask.hash] != nil {
                urlSchemeTask.didReceive(response)
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
