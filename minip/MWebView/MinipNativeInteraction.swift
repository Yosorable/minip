//
//  MinipNativeInteraction.swift
//  minip
//
//  Created by LZY on 2024/12/14.
//

import Foundation
import WebKit

class MinipNativeInteraction: NSObject, WKScriptMessageHandlerWithReply {
    static let name = "MinipNativeInteraction"
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let body = message.body as? String,
              let bodyData = body.data(using: .utf8),
              let jsonObj = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
              let apiName = jsonObj["api"] as? String
        else {
            replyHandler(nil, "Error request")
            return
        }
        
        guard let api = APIName(rawValue: apiName) else {
            do {
                let encoder = JSONEncoder()
                let resData = try encoder.encode(InteropUtils.fail(msg: "API not found"))
                replyHandler(String(data: resData), nil)
            } catch {
                replyHandler(nil, error.localizedDescription)
            }
            return
        }
        
        let wid = (message.webView as? MWebView)?.id ?? -1
        logger.debug("[minip-api-v3] call api [\(api.rawValue)] from [webview:\(wid == -1 ? "unknown" : "\(wid)")] with [\(body.count < 1000 ? body : "data length: \(body.count)")]")

        
        switch api {
        case .ping:
            var res = InteropUtils.succeed()
            if let req = jsonObj["data"] as? String {
                res.data = req
            }
            do {
                let encoder = JSONEncoder()
                let resData = try encoder.encode(res)
                replyHandler(String(data: resData), nil)
            } catch {
                replyHandler(nil, error.localizedDescription)
            }
        case .getInstalledAppList:
            getInstalledAppList(replyHandler: replyHandler)
        default:
            // not implement
            replyHandler(nil, "API \(api.rawValue) not implement")
        }
        
        
    }
    
    enum APIName: String, Codable {
        case ping = "ping"
        case getInstalledAppList = "getInstalledAppList"
    }
    
    struct Request<T: Codable>: Codable {
        var apiName: APIName
        var data: T?
    }
    
    struct Response<T: Codable>: Codable {
        var code: Int
        var msg: String?
        var data: T?
        
        func toJsonString() -> String? {
            let encoder = JSONEncoder()
            do {
                return String(data: try encoder.encode(self))
            } catch {
                return "{\"code\": 0, \"msg\": \"Error occurs when encoding res data to json\"}"
            }
        }
    }
    
    class InteropUtils {
        static func succeed(msg _msg: String? = nil) -> Response<String> {
            Response<String>(code: 7, msg: _msg)
        }
        
        static func succeedWithData<T: Codable>(data _data: T, msg _msg: String? = nil) -> Response<T> {
            Response(code: 7, msg: _msg, data: _data)
        }
        
        static func fail(msg _msg: String? = nil) -> Response<String> {
            Response<String>(code: 0, msg: _msg)
        }
        
        static func failWithData<T: Codable>(data _data: T, msg _msg: String? = nil) -> Response<T> {
            Response(code: 0, msg: _msg, data: _data)
        }
    }
}
