import AVFoundation
import UIKit

extension MinipApi {
    func vibrate(param: Parameter) throws {
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        switch try param.optionalString("type") ?? "medium" {
        case "light": style = .light
        case "medium": style = .medium
        case "heavy": style = .heavy
        default: throw MinipError.invalidArgument("type")
        }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func getClipboardData(param: Parameter) throws -> String? {
        UIPasteboard.general.string
    }

    func setClipboardData(param: Parameter) throws {
        UIPasteboard.general.string = try param.string("data")
    }

    func scanQRCode(param: Parameter) async throws -> String? {
        let authorized: Bool
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: authorized = true
        case .notDetermined: authorized = await AVCaptureDevice.requestAccess(for: .video)
        default: authorized = false
        }
        guard authorized else { throw MinipError(.permissionDenied, "Camera permission is required") }
        let controller = try param.requirePresentation()
        return try await withCheckedThrowingContinuation { continuation in
            let completion = BridgeContinuation(continuation)
            let scanner = QRScannerViewController()
            scanner.modalPresentationStyle = .fullScreen
            scanner.onSucceed = { completion.finish(.success($0)) }
            scanner.onCanceled = { completion.finish(.success(nil)) }
            scanner.onFailed = { completion.finish(.failure($0)) }
            controller.present(scanner, animated: true)
        }
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

    func getDeviceInfo(param: Parameter) throws -> DeviceInfo {
        guard let window = try param.webView.window ?? param.viewController.viewIfLoaded?.window else {
            throw MinipError(.invalidState, "The calling page has no window")
        }
        var systemInfo = utsname()
        uname(&systemInfo)
        let model = Mirror(reflecting: systemInfo.machine).children.reduce("") { value, element in
            guard let byte = element.value as? Int8, byte != 0 else { return value }
            return value + String(UnicodeScalar(UInt8(bitPattern: byte)))
        }
        let screen = window.screen.bounds.size
        let insets = window.safeAreaInsets
        return DeviceInfo(
            language: Locale.preferredLanguages.first ?? "Unknown",
            brand: "Apple", model: model,
            system: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
            screen: .init(width: Double(screen.width), height: Double(screen.height)),
            safeAreaInfo: .init(left: Double(insets.left), right: Double(insets.right), top: Double(insets.top), bottom: Double(insets.bottom)))
    }
}
