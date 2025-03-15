//
//  Device.swift
//  minip
//
//  Created by LZY on 2025/2/9.
//

import UIKit

extension MinipApi {
    func vibrate(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let data = param.data as? [String: String],
              let tp = data["type"]
        else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        var generator = UIImpactFeedbackGenerator(style: .medium)
        if tp == "light" {
            generator = UIImpactFeedbackGenerator(style: .light)
        } else if tp == "medium" {
            generator = UIImpactFeedbackGenerator(style: .medium)
        } else if tp == "heavy" {
            generator = UIImpactFeedbackGenerator(style: .heavy)
        }
        generator.impactOccurred()
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }

    func getClipboardData(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        if let txt = UIPasteboard.general.string {
            replyHandler(InteropUtils.succeedWithData(data: txt).toJsonString(), nil)
            return
        }
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }

    func setClipboardData(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let data = (param.data as? [String: Any])?["data"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        UIPasteboard.general.string = data
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }

    func scanQRCode(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        let qvc = QRScannerViewController()
        qvc.modalPresentationStyle = .fullScreen
        qvc.onSucceed = { code in
            replyHandler(InteropUtils.succeedWithData(data: code).toJsonString(), nil)
        }
        qvc.onCanceled = {
            replyHandler(InteropUtils.succeed(msg: "Canceled").toJsonString(), nil)
        }
        qvc.onFailed = { err in
            replyHandler(InteropUtils.fail(msg: err.localizedDescription).toJsonString(), nil)
        }
        vc.present(qvc, animated: true)
    }

    struct DeviceInfo: Codable {
        let language: String
        let brand: String
        let model: String
        let system: String
        let screen: ScreenInfo
        let safeAreaInfo: SafeAreaInfo

        struct ScreenInfo: Codable {
            let width: Double
            let height: Double
        }

        struct SafeAreaInfo: Codable {
            let left: Double
            let right: Double
            let top: Double
            let bottom: Double
        }
    }

    func getDeviceInfoSync(param: Parameter) -> String? {
        guard let _ = param.webView?.holderObject as? MiniPageViewController,
              let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = scene.delegate as? SceneDelegate,
              let window = sceneDelegate.window
        else {
            return nil
        }
        let language = Locale.preferredLanguages.first ?? "Unknown"

        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        let model = identifier

        let system = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        let screenSize = window.screen.bounds.size
        let screen = DeviceInfo.ScreenInfo(width: Double(screenSize.width), height: Double(screenSize.height))
        var safeArea = DeviceInfo.SafeAreaInfo(left: 0, right: 0, top: 0, bottom: 0)
        let safeInsets = window.safeAreaInsets
        safeArea = DeviceInfo.SafeAreaInfo(left: Double(safeInsets.left),
                                           right: Double(safeInsets.right),
                                           top: Double(safeInsets.top),
                                           bottom: Double(safeInsets.bottom))

        return InteropUtils.succeedWithData(data: DeviceInfo(language: language, brand: "Apple", model: model, system: system, screen: screen, safeAreaInfo: safeArea)).toJsonString()
    }

    func getDeviceInfo(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let res = getDeviceInfoSync(param: param) else { return }
        replyHandler(res, nil)
    }
}
