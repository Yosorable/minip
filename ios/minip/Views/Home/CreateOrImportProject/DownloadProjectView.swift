//
//  DownloadProjectView.swift
//  minip
//
//  Created by ByteDance on 2023/7/14.
//

import Defaults
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

    @State var downURL: String = Defaults[.lastDownloadedURL]
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
                        Text("Please enter the url")
                    }
                    .disabled(downloading)
                }
            } footer: {
                HStack {
                    Text("Only support .zip file")
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Text("Filename")

                TextField(text: $downFilename) {
                    Text("Please enter filename (not required)")
                }
                .disabled(downloading)
            } footer: {
                Text("The downloaded file name will use the last url component item, if some error occurs, this text will be used (if it is empty, \"default.zip\" will be used).")
            }

            Section {} footer: {
                Text("Downloaded files are saved at tmp directory in documents. You need to delete them manually.")
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
                            Text("Uncompressing")
                        }
                        Text("...")
                        Spacer()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Text("home.menu.load_from_web"))
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
                let alert = UIAlertController(title: "Error", message: alertMsg, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                getTopViewController()?.present(alert, animated: true, completion: nil)
            }
        })
    }

    func downloadFile() {
        guard let downurl = URL(string: downURL) else {
            alertMsg = "Error URL"
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
                ProgressHUD.success("Download succeeded, uncompressing")
                unCompress(file: temporaryURL)
                Defaults[.lastDownloadedURL] = downURL
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
                ProgressHUD.succeed(i18n("Success"))
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
