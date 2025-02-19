//
//  MinipApi.swift
//  minip
//
//  Created by LZY on 2025/2/9.
//

import Foundation
import UIKit

class MinipApi {
    static let shared = MinipApi()

    enum APIName: String, Codable {
        case ping
        case getInstalledAppList
        case navigateTo
        case navigateBack
        case redirectTo
        case openWebsite
        case showAppDetail
        case closeApp
        case installApp

        // MARK: UI

        case setNavigationBarTitle
        case setNavigationBarColor
        case enablePullDownRefresh
        case disablePullDownRefresh
        case startPullDownRefresh
        case stopPullDownRefresh
        case showHUD
        case hideHUD
        case showAlert
        case showPicker
        case previewImage
        case previewVideo

        // MARK: Device

        case vibrate
        case getClipboardData
        case setClipboardData
        case scanQRCode

        // MARK: KVStorage async

        case getKVStorage
        case setKVStorage
        case deleteKVStorage
        case clearKVStorage

        // MARK: KYStorage sync, for prompt

        case getKVStorageSync
        case setKVStorageSync
        case deleteKVStorageSync
        case clearKVStorageSync

        func requestPermissionType() -> MiniAppPermissionTypes? {
            switch self {
            case .scanQRCode:
                return .camera
            case .getClipboardData, .setClipboardData:
                return .clipboard
            case .installApp:
                return .installProject
            case .getInstalledAppList:
                return .getInstalledProjectsList
            default:
                break
            }
            return nil
        }
    }

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
        static func succeed(msg _msg: String? = nil) -> Response<String> {
            Response<String>(code: 0, msg: _msg)
        }

        static func succeedWithData<T: Codable>(data _data: T, msg _msg: String? = nil) -> Response<T> {
            Response(code: 0, msg: _msg, data: _data)
        }

        static func fail(msg _msg: String? = nil) -> Response<String> {
            Response<String>(code: 7, msg: _msg)
        }

        static func failWithData<T: Codable>(data _data: T, msg _msg: String? = nil) -> Response<T> {
            Response(code: 7, msg: _msg, data: _data)
        }
    }
}
