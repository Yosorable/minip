//
//  ApiUtils.swift
//  minip
//
//  Created by LZY on 2024/12/14.
//

import Foundation

// todo: wkwebviewjavascriptbridge conflict
class ApiUtils {
    private init() {}
    
    static func makeSuccessRes(msg: String? = nil) -> ApiResponse<Int> {
        ApiResponse(msg: msg)
    }
    
    static func makeSuccessResWithData<T: Codable>(data: T?, msg: String? = nil) -> ApiResponse<T> {
        ApiResponse(msg: msg, data: data)
    }
    
    static func makeFailedRes(msg: String? = nil) -> ApiResponse<Int> {
        ApiResponse(code: 0, msg: msg)
    }
    
    static func makeFailedResWithData<T: Codable>(data: T?, msg: String? = nil) -> ApiResponse<T> {
        ApiResponse(code: 0, msg: msg, data: data)
    }
}

struct ApiResponse<T: Codable>: Codable {
    var code: Int = 7 // 7 for success, other for failed
    var msg: String? // success or error msg
    var data: T?
}
