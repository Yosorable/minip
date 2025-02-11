//
//  CreateProject.swift
//  minip
//
//  Created by LZY on 2025/2/9.
//

import UIKit

func ShowCreateNewProjectAlert(_ parentVC: UIViewController, onCreatedSuccess: @escaping ()->Void) {
    let alert = UIAlertController(title: "Create Project", message: nil, preferredStyle: .alert)
    alert.addTextField(configurationHandler: { tf in
        tf.placeholder = "name"
    })
    alert.addTextField(configurationHandler: { tf in
        tf.placeholder = "display name"
    })
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
    let confirmAction = UIAlertAction(title: "Create", style: .default) { _ in
        let nameTF = alert.textFields?[0]
        let displayNameTF = alert.textFields?[1]
        let name = nameTF?.text ?? ""
        let displayName = displayNameTF?.text
        if name == "" || name.contains("/") || name.contains(".") {
            ShowSimpleError(err: ErrorMsg(errorDescription: "Invalid name"))
            return
        }
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let appFolder = documentsURL.appendingPolyfill(path: name)
        let (exist, _) = fileOrFolderExists(path: appFolder.path)
        if exist {
            ShowSimpleError(err: ErrorMsg(errorDescription: "Invalid name"))
            return
        }
        
        do {
            try fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            ShowSimpleError(err: ErrorMsg(errorDescription: "Cannot create folder, error: \(error.localizedDescription)"))
            return
        }

        let htmlContent = """
        <!DOCTYPE html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
          <meta name="format-detection" content="telephone=no,email=no,address=no" >
          <style>
            html { color-scheme: light dark; }
            body { font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Oxygen, Ubuntu, Cantarell, Fira Sans, Droid Sans, Helvetica Neue, sans-serif; }
          </style>
        </head>
        <body>
          <h1>Hello, world!</h1>
          <p>This is demo file.</p>
          <p>Go to "Files -> \(name)/index.html" to edit it.</p>
          <button disabled id="btn">click me</button>
          <div id="msg"></div>
          <script type="module">
            import * as minip from "https://cdn.jsdelivr.net/gh/yosorable/minip-bridge@main/dist/index.mjs"
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
            ShowSimpleError(err: ErrorMsg(errorDescription: "Cannot create file, error: \(error.localizedDescription)"))
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
        } catch {
            ShowSimpleError(err: ErrorMsg(errorDescription: "Cannot create file, error: \(error.localizedDescription)"))
        }
        
        ShowSimpleSuccess(msg: "Project created successfully.")
        onCreatedSuccess()
    }
    
    alert.addAction(cancelAction)
    alert.addAction(confirmAction)
    parentVC.present(alert, animated: true)
}
