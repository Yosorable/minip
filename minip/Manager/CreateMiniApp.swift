//
//  CreateMiniApp.swift
//  minip
//
//  Created by LZY on 2025/2/13.
//

import Defaults
import Foundation

extension MiniAppManager {
    func createMiniApp(name: String? = nil, displayName: String? = nil) throws -> AppInfo {
        // generate random name by emoji
        let name = (name != nil && name != "") ? name! : {
            var nameRange: [String] = []
            let fileManager = FileManager.default
            let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            for ele in EmojiAppNames {
                if !fileManager.fileExists(atPath: documentDirectory.appendingPathComponent(ele).path) {
                    nameRange.append(ele)
                }
            }
            return nameRange.randomElement() ?? ""
        }()
        if name == "" || name.contains("/") || name.contains(".") {
            throw ErrorMsg(errorDescription: "Invalid name")
        }
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let appFolder = documentsURL.appendingPolyfill(path: name)
        let (exist, _) = fileOrFolderExists(path: appFolder.path)
        if exist {
            throw ErrorMsg(errorDescription: "Invalid name")
        }

        do {
            try fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            throw ErrorMsg(errorDescription: "Cannot create folder, error: \(error.localizedDescription)")
        }

        let htmlContent = """
        <!DOCTYPE html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
          <meta name="format-detection" content="telephone=no,email=no,address=no" >
          <style>
            html { color-scheme: light dark; }
            body { font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Oxygen, Ubuntu, Cantarell, Fira Sans, Droid Sans, Helvetica Neue, sans-serif; word-break: break-all; }
          </style>
        </head>
        <body>
          <h1>Hello, world!</h1>
          <p>This is demo file.</p>
          <p>Go to "Files -> \(name)/index.html" to edit it.</p>
          <button disabled id="btn">click me</button>
          <div id="msg"></div>
          <script type="module">
            import * as minip from "https://cdn.jsdelivr.net/npm/minip-bridge/dist/index.mjs"
            const msgDiv = document.querySelector("#msg")
            const btn = document.querySelector("#btn")
            function click() {
              minip.showAlert({
                title: "Alert",
                message: "This is an alert.",
                actions: [
                  { title: "Ok", key: "Ok" },
                  { title: "Cancel", key: "Cancel", style: "cancel" }
                ]
              })
              .then(res => msgDiv.innerText = `You clicked ${res.data}.`)
              .catch(err => {
                let message = err ? (err.message ?? err.msg ?? err.data ?? JSON.stringify(err)) : "Unknown error"
                msgDiv.innerText = `Some error occurs, message: ${message}`
              })
            }
            btn.disabled = false
            btn.onclick = click
          </script>
        </body>
        </html>
        """

        let htmlFileURL = appFolder.appendingPathComponent("index.html")
        do {
            try htmlContent.write(to: htmlFileURL, atomically: true, encoding: .utf8)
        } catch {
            throw ErrorMsg(errorDescription: "Cannot create file, error: \(error.localizedDescription)")
        }

        let appConfig = AppInfo(
            name: name,
            displayName: displayName == "" ? nil : displayName,
            appId: UUID().uuidString.lowercased(),
            homepage: "index.html",
            navigationBarStatus: "display"
        )
        let jsonFileURL = appFolder.appendingPathComponent("app.json")
        do {
            let jsonEncoder = JSONEncoder()
            let jsonDataEncoded = try jsonEncoder.encode(appConfig)
            try jsonDataEncoded.write(to: jsonFileURL)
            Defaults[.appInfoList].insert(appConfig, at: 0)
            Defaults[.appSortList].insert(appConfig.appId, at: 0)
        } catch {
            throw ErrorMsg(errorDescription: "Cannot create file, error: \(error.localizedDescription)")
        }
        return appConfig
    }
}
