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

        // MARK: route

        case navigateTo
        case navigateBack
        case redirectTo
        case openWebsite
        case openSettings

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
        case getDeviceInfo

        // MARK: for prompt

        case getDeviceInfoSync

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

        // MARK: SQLite

        case sqliteOpenDB
        case sqliteCloseDB
        case sqlitePrepare
        case sqliteStatementAll
        case sqliteStatementRun
        case sqliteExecute
        case sqliteCreateIterator
        case sqliteIteratorNext
        case sqliteIteratorRelease

        // MARK: Memory Storage

        case setMemoryStorage
        case setMemoryStorageIfNotExist
        case getMemoryStorage
        case removeMemoryStorage
        case clearMemoryStorage

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

    func call(apiName: APIName, param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let _ = MiniAppManager.shared.openedApp, let webView = param.webView, let vc = webView.holderObject as? UIViewController else {
            return
        }

        if let permission = apiName.requestPermissionType() {
            MiniAppManager.shared.getOrRequestPermission(permissionType: permission, onSuccess: { [weak self] in
                self?.handle(apiName: apiName, param: param, replyHandler: replyHandler)
            }, onFailed: { _ in
                replyHandler(nil, "No permission")
            }, parentVC: vc)
        } else {
            self.handle(apiName: apiName, param: param, replyHandler: replyHandler)
        }
    }

    private func handle(apiName: APIName, param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        let api = MinipApi.shared
        switch apiName {
        case .ping:
            var res = MinipApi.InteropUtils.succeed()
            if let req = (param.data as? [String: Any])?["data"] as? String {
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
            api.getInstalledAppList(replyHandler: replyHandler)
        case .navigateTo:
            api.navigateTo(param: param, replyHandler: replyHandler)
        case .navigateBack:
            api.navigateBack(param: param, replyHandler: replyHandler)
        case .redirectTo:
            api.redirectTo(param: param, replyHandler: replyHandler)
        case .openWebsite:
            api.openWebsite(param: param, replyHandler: replyHandler)
        case .openSettings:
            api.openSettings(param: param, replyHandler: replyHandler)
        case .showAppDetail:
            api.showAppDetail(param: param, replyHandler: replyHandler)
        case .closeApp:
            api.closeApp(param: param, replyHandler: replyHandler)
        case .installApp:
            api.installApp(param: param, replyHandler: replyHandler)
        case .setNavigationBarTitle:
            api.setNavigationBarTitle(param: param, replyHandler: replyHandler)
        case .setNavigationBarColor:
            api.setNavigationBarColor(param: param, replyHandler: replyHandler)
        case .enablePullDownRefresh:
            api.enablePullDownRefresh(param: param, replyHandler: replyHandler)
        case .disablePullDownRefresh:
            api.disablePullDownRefresh(param: param, replyHandler: replyHandler)
        case .startPullDownRefresh:
            api.startPullDownRefresh(param: param, replyHandler: replyHandler)
        case .stopPullDownRefresh:
            api.stopPullDownRefresh(param: param, replyHandler: replyHandler)
        case .showHUD:
            api.showHUD(param: param, replyHandler: replyHandler)
        case .hideHUD:
            api.hideHUD(param: param, replyHandler: replyHandler)
        case .showAlert:
            api.showAlert(param: param, replyHandler: replyHandler)
        case .previewImage:
            api.previewImage(param: param, replyHandler: replyHandler)
        case .previewVideo:
            api.previewVideo(param: param, replyHandler: replyHandler)
        case .vibrate:
            api.vibrate(param: param, replyHandler: replyHandler)
        case .getClipboardData:
            api.getClipboardData(param: param, replyHandler: replyHandler)
        case .setClipboardData:
            api.setClipboardData(param: param, replyHandler: replyHandler)
        case .getKVStorage,
             .getKVStorageSync:
            api.getKVStorage(param: param, replyHandler: replyHandler)
        case .setKVStorage,
             .setKVStorageSync:
            api.setKVStorage(param: param, replyHandler: replyHandler)
        case .deleteKVStorage,
             .deleteKVStorageSync:
            api.deleteKVStorage(param: param, replyHandler: replyHandler)
        case .clearKVStorage,
             .clearKVStorageSync:
            api.clearKVStorage(param: param, replyHandler: replyHandler)
        case .showPicker:
            api.showPicker(param: param, replyHandler: replyHandler)
        case .scanQRCode:
            api.scanQRCode(param: param, replyHandler: replyHandler)
        case .getDeviceInfo,
             .getDeviceInfoSync:
            api.getDeviceInfo(param: param, replyHandler: replyHandler)
        case .sqliteOpenDB:
            api.sqliteOpenDB(param: param, replyHandler: replyHandler)
        case .sqliteCloseDB:
            api.sqliteCloseDB(param: param, replyHandler: replyHandler)
        case .sqlitePrepare:
            api.sqlitePrepare(param: param, replyHandler: replyHandler)
        case .sqliteStatementAll:
            api.sqliteStatementAll(param: param, replyHandler: replyHandler)
        case .sqliteStatementRun:
            api.sqliteStatementRun(param: param, replyHandler: replyHandler)
        case .sqliteExecute:
            api.sqliteExecute(param: param, replyHandler: replyHandler)
        case .sqliteCreateIterator:
            api.sqliteCreateIterator(param: param, replyHandler: replyHandler)
        case .sqliteIteratorNext:
            api.sqliteIteratorNext(param: param, replyHandler: replyHandler)
        case .sqliteIteratorRelease:
            api.sqliteIteratorRelease(param: param, replyHandler: replyHandler)
        case .setMemoryStorage:
            api.setMemoryStorage(param: param, replyHandler: replyHandler)
        case .setMemoryStorageIfNotExist:
            api.setMemoryStorageIfNotExist(param: param, replyHandler: replyHandler)
        case .getMemoryStorage:
            api.getMemoryStorage(param: param, replyHandler: replyHandler)
        case .removeMemoryStorage:
            api.removeMemoryStorage(param: param, replyHandler: replyHandler)
        case .clearMemoryStorage:
            api.clearMemoryCache(param: param, replyHandler: replyHandler)
        default:
            replyHandler(nil, "API \(apiName.rawValue) is not implemented or not allowed")
        }
    }
}
