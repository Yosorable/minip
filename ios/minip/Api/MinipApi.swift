import Foundation
import UIKit

@MainActor
final class MinipApi {
    static let shared = MinipApi()

    enum APIName: String {
        case ping
        case getDeviceInfo
        case getKVStorage
        case setKVStorage
        case deleteKVStorage
        case clearKVStorage
        case getMemoryStorage
        case setMemoryStorage
        case setMemoryStorageIfNotExist
        case removeMemoryStorage
        case clearMemoryStorage
        case fsAccess
        case fsMkdir
        case fsReaddir
        case fsRmdir
        case fsReadFile
        case fsWriteFile
        case fsAppendFile
        case fsCopyFile
        case fsUnlink
        case fsRename
        case fsStat
        case fsTruncate
        case fsRm
        case fsCp
        case fsOpen
        case fsClose
        case fsFstat
        case fsFtruncate
        case fsRead
        case fsWrite
        case getInstalledAppList
        case getAppInfo
        case showAppDetail
        case closeApp
        case installApp
        case updateCurrentApp
        case navigateTo
        case navigateBack
        case redirectTo
        case openWebsite
        case openSettings
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
        case vibrate
        case getClipboardData
        case setClipboardData
        case scanQRCode
        case sqliteOpenDB
        case sqliteCloseDB
        case sqlitePrepare
        case sqliteStatementAll
        case sqliteStatementRun
        case sqliteExecute
        case sqliteCreateIterator
        case sqliteIteratorNext
        case sqliteIteratorRelease

        var supportsSync: Bool {
            switch self {
            case .ping, .getDeviceInfo, .getKVStorage, .setKVStorage, .deleteKVStorage, .clearKVStorage, .getMemoryStorage, .setMemoryStorage, .setMemoryStorageIfNotExist, .removeMemoryStorage, .clearMemoryStorage, .fsAccess, .fsMkdir, .fsReaddir, .fsRmdir, .fsReadFile, .fsWriteFile, .fsAppendFile, .fsCopyFile, .fsUnlink, .fsRename, .fsStat, .fsTruncate, .fsRm, .fsCp, .fsOpen, .fsClose, .fsFstat, .fsFtruncate, .fsRead, .fsWrite:
                return true
            default: return false
            }
        }

        var permission: MiniAppPermissionTypes? {
            switch self {
            case .scanQRCode: return .camera
            case .getClipboardData, .setClipboardData: return .clipboard
            case .installApp: return .installProject
            case .getInstalledAppList: return .getInstalledProjectsList
            default: return nil
            }
        }
    }

    private func validateContext(_ param: Parameter) throws {
        let appID = try param.appID
        guard MiniAppManager.shared.openedApp?.appId == appID else {
            throw MinipError(.invalidState, "The calling application is no longer active")
        }
    }

    func callSync(apiName: APIName, param: Parameter) throws -> BridgePayload? {
        try validateContext(param)
        guard apiName.supportsSync else {
            throw MinipError(.notSupported, "This API does not support synchronous calls")
        }
        switch apiName {
        case .ping: return BridgePayload(BridgeValue.object(param.data))
        case .getDeviceInfo: return BridgePayload(try getDeviceInfo(param: param))
        case .getKVStorage: return BridgePayload(try getKVStorage(param: param))
        case .setKVStorage: try setKVStorage(param: param)
        case .deleteKVStorage: try deleteKVStorage(param: param)
        case .clearKVStorage: try clearKVStorage(param: param)
        case .getMemoryStorage: return BridgePayload(try getMemoryStorage(param: param))
        case .setMemoryStorage: try setMemoryStorage(param: param)
        case .setMemoryStorageIfNotExist: return BridgePayload(try setMemoryStorageIfNotExist(param: param))
        case .removeMemoryStorage: try removeMemoryStorage(param: param)
        case .clearMemoryStorage: clearMemoryStorage()
        case .fsAccess: try fsAccess(param: param)
        case .fsMkdir: try fsMkdir(param: param)
        case .fsReaddir: return BridgePayload(try fsReaddir(param: param))
        case .fsRmdir: try fsRmdir(param: param)
        case .fsReadFile: return BridgePayload(try fsReadFile(param: param))
        case .fsWriteFile: try fsWriteFile(param: param)
        case .fsAppendFile: try fsAppendFile(param: param)
        case .fsCopyFile: try fsCopyFile(param: param)
        case .fsUnlink: try fsUnlink(param: param)
        case .fsRename: try fsRename(param: param)
        case .fsStat: return BridgePayload(try fsStat(param: param))
        case .fsTruncate: try fsTruncate(param: param)
        case .fsRm: try fsRm(param: param)
        case .fsCp: try fsCp(param: param)
        case .fsOpen: return BridgePayload(try fsOpen(param: param))
        case .fsClose: try fsClose(param: param)
        case .fsFstat: return BridgePayload(try fsFstat(param: param))
        case .fsFtruncate: try fsFtruncate(param: param)
        case .fsRead: return BridgePayload(try fsRead(param: param))
        case .fsWrite: return BridgePayload(try fsWrite(param: param))
        default: throw MinipError(.notSupported, "This API does not support synchronous calls")
        }
        return nil
    }

    func call(apiName: APIName, param: Parameter) async throws -> BridgePayload? {
        try validateContext(param)
        if let permission = apiName.permission {
            let controller = try param.viewController
            try await MiniAppManager.shared.requirePermission(permission, app: controller.app, parent: controller)
            try validateContext(param)
        }
        if apiName.supportsSync { return try callSync(apiName: apiName, param: param) }
        switch apiName {
        case .getInstalledAppList: return BridgePayload(MiniAppManager.shared.getAppInfos())
        case .getAppInfo: return BridgePayload(try param.viewController.app)
        case .showAppDetail: try showAppDetail(param: param)
        case .closeApp: try closeApp(param: param)
        case .installApp: try await installApp(param: param)
        case .updateCurrentApp: try await updateCurrentApp(param: param)
        case .navigateTo: try navigateTo(param: param)
        case .navigateBack: try navigateBack(param: param)
        case .redirectTo: try redirectTo(param: param)
        case .openWebsite: try openWebsite(param: param)
        case .openSettings: try openSettings(param: param)
        case .setNavigationBarTitle: try setNavigationBarTitle(param: param)
        case .setNavigationBarColor: try setNavigationBarColor(param: param)
        case .enablePullDownRefresh: try enablePullDownRefresh(param: param)
        case .disablePullDownRefresh: try disablePullDownRefresh(param: param)
        case .startPullDownRefresh: try startPullDownRefresh(param: param)
        case .stopPullDownRefresh: try stopPullDownRefresh(param: param)
        case .showHUD: try showHUD(param: param)
        case .hideHUD: try hideHUD(param: param)
        case .showAlert: return BridgePayload(try await showAlert(param: param))
        case .showPicker: return BridgePayload(try await showPicker(param: param))
        case .previewImage: try await previewImage(param: param)
        case .previewVideo: try previewVideo(param: param)
        case .vibrate: try vibrate(param: param)
        case .getClipboardData: return BridgePayload(try getClipboardData(param: param))
        case .setClipboardData: try setClipboardData(param: param)
        case .scanQRCode: return BridgePayload(try await scanQRCode(param: param))
        case .sqliteOpenDB: return BridgePayload(try sqliteOpenDB(param: param))
        case .sqliteCloseDB: try sqliteCloseDB(param: param)
        case .sqlitePrepare: return BridgePayload(try sqlitePrepare(param: param))
        case .sqliteStatementAll: return BridgePayload(try sqliteStatementAll(param: param))
        case .sqliteStatementRun: return BridgePayload(try sqliteStatementRun(param: param))
        case .sqliteExecute: return BridgePayload(try sqliteExecute(param: param))
        case .sqliteCreateIterator: try sqliteCreateIterator(param: param)
        case .sqliteIteratorNext: return BridgePayload(try sqliteIteratorNext(param: param))
        case .sqliteIteratorRelease: try sqliteIteratorRelease(param: param)
        default: throw MinipError(.apiNotFound, "Unknown API")
        }
        return nil
    }
}
