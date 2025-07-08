//
//  FileServerView.swift
//  minip
//
//  Created by LZY on 2025/3/28.
//

import FlyingFox
import SwiftUI

struct FileServerView: View {
    @State var serverRunning = false
    @State var fileServer: HTTPServer? = nil
    @State var ipAddress = ""

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text(serverRunning ? ipAddress : "File server is not running")
                } header: {
                    Text("Network")
                } footer: {
                    VStack(alignment: .leading) {
                        Text("1. Start the file server.")
                        Text("2. On the same network, use another device’s web browser to open the displayed URL.")
                        Text("3. Transfer files.")
                        Text("The file server will automatically shut down if you leave this page, the app goes to the background, or your device's screen turns off.")
                            .padding(.vertical)
                    }
                }
                Button {
                    let ipList = getIPAddresses()
                    if let ipv4 = ipList.ipv4 {
                        ipAddress = "http://\(ipv4):8080"
                    }
                    if ipAddress.isEmpty {
                        ipAddress = "Unknown"
                    }
                    
                    if serverRunning {
                        Task {
                            await fileServer?.stop()
                            serverRunning = false
                        }
                    } else {
                        Task {
                            await initFileServer()
                            do {
                                serverRunning = true
                                try await fileServer?.run()
                            } catch {
                                serverRunning = false
                                logger.error(
                                    "[file-server] error: \(error.localizedDescription)"
                                )
                            }
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text(serverRunning ? "Stop" : "Start")
                        Spacer()
                    }
                }
            }
            .navigationBarTitle(Text("File Server"), displayMode: .inline)
        }
        .onDisappear {
            guard let serv = fileServer else { return }
            Task {
                if await serv.isListening {
                    await serv.stop()
                }
            }
        }
    }

    func initFileServer() async {
        guard fileServer == nil else { return }
        let serv = HTTPServer(
            address: try! .inet(ip4: "0.0.0.0", port: 8080),
            logger: LoggerForFlyingFox(prefix: "file-server")
        )
        fileServer = serv

        // frontend
        await serv.appendRoute("GET /", to: .file(named: "index.html"))
        await serv.appendRoute("GET /index.css", to: .file(named: "index.css"))
        await serv.appendRoute("GET /index.js", to: .file(named: "index.js"))

        // download file
        let dirHandler = DirectoryHTTPHandler(
            root: FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]
        )
        await serv.appendRoute("GET /file/*") { req in
            var _req: HTTPRequest = req
            _req.path = String(_req.path.dropFirst(5))
            do {
                return try await dirHandler.handleRequest(_req)
            } catch {
                return HTTPResponse(statusCode: .notFound)
            }
        }

        // list files and folders
        // {"path": "/"}
        await serv.appendRoute("POST /files") { req in
            if let data = try? await req.bodyData,
               let jsonObj = try? JSONSerialization.jsonObject(with: data)
                as? [String: String],
               let path = jsonObj["path"]
            {
                let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                
                do {
                    let files = try listFilesAndFolders(in: documentURL.appendingPolyfill(path: path))
                    var res = [[String:Any]]()
                    for file in files.folders + files.files {
                        res.append([
                            "name": file.fileName,
                            "type": file.isFolder ? "folder" : "file",
                            "path": file.url.path.dropFirst(documentURL.path.count),
                            "size": file.size ?? "-",
                            "modified": (file.lastModified != nil) ? formatDateToLocalString(file.lastModified!) : "unknown"
                        ])
                    }
                    let resBody = try JSONSerialization.data(withJSONObject: res)
                    return HTTPResponse(statusCode: .ok, headers: [.contentType: "application/json"], body: resBody)
                } catch {
                    return HTTPResponse(statusCode: .internalServerError)
                }
            }
            return HTTPResponse(statusCode: .badRequest)
        }

        // delete file or folder
        // {"path": "/", "file": "hello.txt"}
        await serv.appendRoute("POST /delete") { req in
            if let data = try? await req.bodyData,
               let jsonObj = try? JSONSerialization.jsonObject(with: data)
                as? [String: String],
               let path = jsonObj["path"], let file = jsonObj["file"] {
                let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

                do {
                    let toDel = documentURL.appendingPolyfill(path: path).appendingPolyfill(component: file)
                    try FileManager.default.removeItem(at: toDel)
                    return HTTPResponse(statusCode: .ok)
                } catch {
                    return HTTPResponse(statusCode: .internalServerError)
                }
            }
            return HTTPResponse(statusCode: .badRequest)
        }

        // creare file or folder
        // {"path": "/", "file": "hello.txt", "type": "folder"}
        await serv.appendRoute("POST /create") { req in
            if let data = try? await req.bodyData,
               let jsonObj = try? JSONSerialization.jsonObject(with: data)
                as? [String: String],
               let path = jsonObj["path"],
               let file = jsonObj["file"],
               let tp = jsonObj["type"] {
                let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let isFolder = tp == "folder"
                let url = documentURL.appendingPolyfill(path: path).appendingPolyfill(component: file)

                if FileManager.default.fileExists(atPath: url.path) {
                    return HTTPResponse(statusCode: .internalServerError)
                }

                do {
                    if isFolder {
                        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                    } else {
                        try Data().write(to: url)
                    }
                    return HTTPResponse(statusCode: .ok)
                } catch {
                    return HTTPResponse(statusCode: .internalServerError)
                }
            }
            return HTTPResponse(statusCode: .badRequest)
        }

        // rename file or folder
        // {"path": "/", "file": "hello.txt", "rename": "world.txt"}
        await serv.appendRoute("POST /rename") { req in
            if let data = try? await req.bodyData,
               let jsonObj = try? JSONSerialization.jsonObject(with: data)
                as? [String: String],
               let path = jsonObj["path"],
               let file = jsonObj["file"],
               let rename = jsonObj["rename"] {
                let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                do {
                    let folder = documentURL.appendingPolyfill(path: path)
                    let ori = folder.appendingPolyfill(path: file)
                    let dst = folder.appendingPolyfill(path: rename)
                    try FileManager.default.moveItem(at: ori, to: dst)
                    return HTTPResponse(statusCode: .ok)
                } catch {
                    return HTTPResponse(statusCode: .internalServerError)
                }
            }
            return HTTPResponse(statusCode: .badRequest)
        }

        // upload file
        // /upload?dir=/.tmp&filename=demo.txt
        // application/octet-stream
        await serv.appendRoute("POST /upload") { req in
            guard let targetDir = req.query["dir"]?.removingPercentEncoding,
                  let filename = req.query["filename"]?.removingPercentEncoding else {
                return HTTPResponse(statusCode: .badRequest)
            }
            
            let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentURL.appendingPolyfill(path: targetDir).appendingPolyfill(component: filename)
            if !FileManager.default.createFile(atPath: fileURL.path, contents: nil) {
                return HTTPResponse(statusCode: .internalServerError)
            }
            
            do {
                let handle = try FileHandle(forWritingTo: fileURL)
                for try await chunk in req.bodySequence {
                    try handle.write(contentsOf: chunk)
                }
                return HTTPResponse(statusCode: .ok)
            } catch {
                return HTTPResponse(statusCode: .internalServerError)
            }
        }
    }
}
