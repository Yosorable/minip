//
//  DownloadProjectView.swift
//  minip
//
//  Created by ByteDance on 2023/7/14.
//

import ProgressHUD
import SwiftUI

class DownloadProjectViewController: UIHostingController<DownloadProjectView> {
    init() {
        super.init(rootView: DownloadProjectView())
    }

    @available(*, unavailable)
    @MainActor @preconcurrency dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        rootView.closeFunc = { [weak self] in
            self?.dismiss(animated: true)
        }
    }
}

struct DownloadProjectView: View {
    var onSuccess: (() -> Void)?
    var closeFunc: (() -> Void)?

    @State var downURL: String = Preferences.lastDownloadedURL
    @State var downFilename: String = ""

    @State var showAlert = false
    @State var alertMsg = ""

    @State var downloading: Bool = false
    @State var uncompressing: Bool = false

    @State var downloadTask: URLSessionDownloadTask? = nil

    var body: some View {
        List {
            Section {
                HStack {
                    Text("URL")
                    TextField(text: $downURL) {
                        Text("Enter a URL")
                    }
                    .disabled(downloading)
                }
            } footer: {
                HStack {
                    Text("Only ZIP files are supported.")
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Text("Filename")

                TextField(text: $downFilename) {
                    Text("File name (optional)")
                }
                .disabled(downloading)
            } footer: {
                Text("Use this file name if the server does not provide one. Leave it empty to use default.zip.")
            }

            Section {} footer: {
                Text("Downloaded files are saved in the .tmp folder in Documents. Delete them manually when no longer needed.")
            }
            if downloading || uncompressing {
                Section {
                    Button(role: .destructive, action: {
                        downloadTask?.cancel()
                        downloadTask = nil
                        downloading = false
                    }, label: {
                        HStack {
                            Spacer()
                            Text("Cancel")
                            Spacer()
                        }
                    })
                    .disabled(uncompressing)
                } header: {
                    HStack {
                        Spacer()
                        if downloading {
                            Text("Downloading")
                        } else if uncompressing {
                            Text("Decompressing")
                        }
                        Text(verbatim: "…")
                        Spacer()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Text("Load from web"))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    closeFunc?()
                } label: {
                    Text("Cancel")
                }
                .disabled(downloading || uncompressing)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    downloadFile()
                } label: {
                    Text("Download")
                        .disabled(downloading || downURL.isEmpty || uncompressing)
                }
            }
        }
        .onChange(of: showAlert, perform: { newValue in
            if newValue {
                let alert = UIAlertController(title: String(localized: "Error"), message: alertMsg, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: String(localized: "OK"), style: UIAlertAction.Style.default, handler: nil))
                getTopViewController()?.present(alert, animated: true, completion: nil)
            }
        })
    }

    func downloadFile() {
        guard let downurl = URL(string: downURL) else {
            alertMsg = String(localized: "Invalid URL")
            showAlert = true
            return
        }
        downloading = true
        let fallbackFilename = downFilename.isEmpty ? "default.zip" : downFilename
        downloadTask = downloadFileToTmpFolder(downurl, fallbackFilename: fallbackFilename) { result in
            downloadTask = nil
            downloading = false
            switch result {
            case .success(let temporaryURL):
                uncompressing = true
                ProgressHUD.success(String(localized: "Download complete. Decompressing…"))
                unCompress(file: temporaryURL)
                Preferences.lastDownloadedURL = downURL
            case .failure(let error):
                guard (error as? URLError)?.code != .cancelled else { return }
                alertMsg = error.localizedDescription
                showAlert = true
            }
        }
    }

    func unCompress(file: URL) {
        Task {
            await InstallMiniApp(pkgFile: file, onSuccess: {
                ProgressHUD.succeed(String(localized: "Success"))
                closeFunc?()
                onSuccess?()
            }, onFailed: { err in
                alertMsg = err
                showAlert = true
            })
            uncompressing = false
        }
    }
}
