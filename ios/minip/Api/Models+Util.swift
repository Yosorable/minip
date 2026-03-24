//
//  MiniApi+Models.swift
//  minip
//
//  Created by LZY on 2025/3/24.
//

import Foundation

extension MinipApi {
    struct Parameter {
        var webView: MWebView?
        var data: Any?
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
                return try String(data: encoder.encode(self))
            } catch {
                return "{\"code\": 7, \"msg\": \"Error occurs when encoding res data to json\"}"
            }
        }
    }

    class InteropUtils {
        static let successCode = 0
        static let failedCode = 7

        static func succeed(msg _msg: String? = nil) -> Response<String> {
            Response<String>(code: successCode, msg: _msg)
        }

        static func succeedWithData<T: Codable>(data _data: T, msg _msg: String? = nil) -> Response<T> {
            Response(code: successCode, msg: _msg, data: _data)
        }

        static func fail(msg _msg: String? = nil) -> Response<String> {
            Response<String>(code: failedCode, msg: _msg)
        }

        static func failWithData<T: Codable>(data _data: T, msg _msg: String? = nil) -> Response<T> {
            Response(code: failedCode, msg: _msg, data: _data)
        }
    }
}
