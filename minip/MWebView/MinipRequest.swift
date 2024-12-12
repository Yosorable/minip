//
//  MinipRequest.swift
//  minip
//
//  Created by LZY on 2024/5/1.
//

import WebKit

struct MinipRequestBody: Codable {
    var headers: [String : String]?
    var method: String?
    var body: String?
    var url: String
}

class MinipRequest: NSObject, WKURLSchemeHandler {
    var schemeHandlers: [Int:WKURLSchemeTask] = [:]

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        schemeHandlers[urlSchemeTask.hash] = urlSchemeTask
        // 获取原始请求
        let request = urlSchemeTask.request

        // 创建一个新的请求
        
        let decoder = JSONDecoder()
        guard let httpBody = request.httpBody, let bd = try? decoder.decode(MinipRequestBody.self, from: httpBody), let url = URL(string: bd.url) else {
            urlSchemeTask.didFailWithError(NSError(domain: "MinipRequestHandlerError", code: 2, userInfo: nil))
            return
        }

        var newRequest = URLRequest(url: url)
        newRequest.httpMethod = bd.method
        newRequest.httpBody = bd.body?.data(using: .utf8)
        newRequest.allHTTPHeaderFields = bd.headers
        
        // 发送新请求
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
            
            // 返回数据给 WebView
            if (self.schemeHandlers[urlSchemeTask.hash] != nil) {
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didReceive(data)
                urlSchemeTask.didFinish()
                self.schemeHandlers.removeValue(forKey: urlSchemeTask.hash)
            }
        }
        task.resume()
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // 处理停止请求的逻辑
        schemeHandlers.removeValue(forKey: urlSchemeTask.hash)
    }
}


class MinipURLSchemePing: NSObject, WKURLSchemeHandler {
    var schemeHandlers: [Int:WKURLSchemeTask] = [:]

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        schemeHandlers[urlSchemeTask.hash] = urlSchemeTask
        // 获取原始请求
        let request = urlSchemeTask.request

        // 创建一个新的请求
        
        var res = "pong".data(using: .utf8)!
        if let data = request.httpBody {
            res.append(" ".data(using: .utf8)!)
            res.append(data)
        }
        
        if (self.schemeHandlers[urlSchemeTask.hash] != nil) {
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
            self.schemeHandlers.removeValue(forKey: urlSchemeTask.hash)
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // 处理停止请求的逻辑
        schemeHandlers.removeValue(forKey: urlSchemeTask.hash)
    }
}
