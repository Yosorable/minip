import Foundation

/// The metadata endpoint is served by vite-plugin-minip, separately from built app packages.
struct DevelopmentProject: Decodable {
    let version: Int
    let app: AppInfo

    static func serverURL(from address: String) throws -> URL {
        guard var components = URLComponents(string: address),
              ["http", "https"].contains(components.scheme?.lowercased() ?? ""),
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil,
              components.query == nil, components.fragment == nil else {
            throw ErrorMsg(errorDescription: i18n("dev.invalid_address"))
        }
        if !components.percentEncodedPath.hasSuffix("/") {
            components.percentEncodedPath += "/"
        }
        guard let url = components.url else {
            throw ErrorMsg(errorDescription: i18n("dev.invalid_address"))
        }
        return url
    }

    static func load(from serverURL: URL) async throws -> InstalledProject {
        let manifestURL = serverURL.appendingPathComponent("__minip__/app.json")
        let request = URLRequest(url: manifestURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw ErrorMsg(errorDescription: i18n("dev.invalid_manifest"))
        }
        let manifest: DevelopmentProject
        do {
            manifest = try JSONDecoder().decode(DevelopmentProject.self, from: data)
        } catch {
            throw ErrorMsg(errorDescription: i18n("dev.invalid_manifest"))
        }
        let app = manifest.app
        // appId also names the persistent native data directory.
        guard manifest.version == 1,
              !app.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !app.appId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              app.appId != ".", app.appId != "..",
              app.appId.rangeOfCharacter(from: .controlCharacters) == nil,
              !app.appId.contains("/"), !app.appId.contains("\\"),
              !app.homepage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ErrorMsg(errorDescription: i18n("dev.invalid_manifest"))
        }
        try Task.checkCancellation()
        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent("minip-dev-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        return InstalledProject(appInfo: app, rootURL: rootURL, developmentServerURL: serverURL)
    }
}
