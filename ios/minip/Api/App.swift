import Foundation

extension MinipApi {
    func showAppDetail(param: Parameter) throws {
        try param.viewController.showAppDetail()
    }

    func closeApp(param: Parameter) throws {
        try param.viewController.close()
    }

    func installApp(param: Parameter) async throws {
        try await installPackage(from: param.string("url"), expectedAppID: nil)
    }

    func updateCurrentApp(param: Parameter) async throws {
        try await installPackage(from: param.string("url"), expectedAppID: param.appID)
    }

    private func installPackage(from source: String, expectedAppID: String?) async throws {
        guard let url = URL(string: source), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
            throw MinipError.invalidArgument("url")
        }
        let file: URL = try await withCheckedThrowingContinuation { continuation in
            let completion = BridgeContinuation(continuation)
            downloadFileToTmpFolder(url) { result in completion.finish(result) }
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let completion = BridgeContinuation(continuation)
            Task { @MainActor in
                await InstallMiniApp(pkgFile: file, onSuccess: {
                    completion.finish(.success(()))
                }, onFailed: { message in
                    completion.finish(.failure(MinipError(.ioError, message)))
                }, validateAppInfoFunc: { info in
                    expectedAppID == nil || info.appId == expectedAppID
                })
            }
        }
    }
}
