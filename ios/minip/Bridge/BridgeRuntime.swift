import Foundation
import WebKit

enum BridgeRuntime {
    private static let source: String = {
        guard let url = Bundle.main.url(forResource: "minip-runtime", withExtension: "js", subdirectory: "BridgeRuntime"),
              let source = try? String(contentsOf: url, encoding: .utf8)
        else {
            preconditionFailure("Missing bridge runtime. Rebuild it with pnpm bridge:build and include Resources/BridgeRuntime in the app.")
        }
        return source
    }()

    static func userScript() -> WKUserScript {
        WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false, in: .page)
    }
}
