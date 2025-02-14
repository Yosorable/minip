//
//  DownloadProjectView.swift
//  minip
//
//  Created by ByteDance on 2023/7/14.
//

import Alamofire
import Defaults
import ProgressHUD
import SwiftUI
import ZipArchive

struct DownloadProjectView: View {
    @Environment(\.dismissPolyfill) var dismiss

    var onSuccess: (() -> Void)?

    @State var downURL: String = Defaults[.lastDownloadedURL]
    @State var downFilename: String = ""

    @State var showAlert = false
    @State var alertMsg = ""

    @State var downloading: Bool = false
    @State var downProgress: Progress? = nil
    @State var uncompressing: Bool = false

    @State var downloadReq: DownloadRequest? = nil

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                content
            }
        } else {
            NavigationView {
                content
            }
        }
    }

    var content: some View {
        List {
            Section {
                HStack {
                    Text("URL")
                    if #available(iOS 15.0, *) {
                        TextField(text: $downURL) {
                            Text("Please enter the url")
                        }
                        .disabled(downloading)
                    } else {
                        TextField("", text: $downURL)
                            .disabled(downloading)
                    }
                }
            } footer: {
                HStack {
                    Text("Only support .zip file")
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Text("Filename")

                if #available(iOS 15.0, *) {
                    TextField(text: $downFilename) {
                        Text("Please enter filename (not required)")
                    }
                    .disabled(downloading)
                } else {
                    TextField("Please enter filename (not required)", text: $downFilename)
                        .disabled(downloading)
                }
            } footer: {
                Text("The downloaded file name will use the last url component item, if some error occurs, this text will be used (if it is empty, \"default.zip\" will be used).")
            }

            Section {} footer: {
                Text("Downloaded files are saved at tmp directory in documents. You need to delete them manually.")
            }
            if downloading || uncompressing {
                Section {
                    if #available(iOS 15.0, *) {
                        Button(role: .destructive, action: {
                            downloadReq?.cancel()
                            downloading = false
                        }, label: {
                            HStack {
                                Spacer()
                                Text("Cancel")
                                Spacer()
                            }
                        })
                        .disabled(uncompressing)
                    } else {
                        Button {
                            downloadReq?.cancel()
                            downloading = false
                        } label: {
                            HStack {
                                Spacer()
                                Text("Cancel")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
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
        .navigationTitle(Text("Load from web"))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
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
                GetTopViewController()?.present(alert, animated: true, completion: nil)
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
        let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destination: (URL, HTTPURLResponse) -> (URL, DownloadRequest.Options) = { _, res in
            let pathComponent = res.suggestedFilename ?? "default.zip"

            let finalPath = docURL.appendingPolyfill(path: "tmp").appendingPathComponent(pathComponent)
            return (finalPath, [.createIntermediateDirectories, .removePreviousFile])
        }
        downloadReq = AF.download(downurl, to: destination)
            .downloadProgress { progress in
                downProgress = progress
                logger.debug("[downloadFile] \(progress.fractionCompleted)")
            }
            .response(completionHandler: { resp in
                downloading = false
                if let err = resp.error {
                    alertMsg = err.localizedDescription
                    showAlert = true
                    return
                } else if let tmpUrl = resp.fileURL {
                    uncompressing = true
                    ProgressHUD.success("Download succeeded, uncompressing")
                    unCompress(file: tmpUrl)
                    uncompressing = false
                    Defaults[.lastDownloadedURL] = downURL
                    return
                }
                alertMsg = "Unknow error"
                showAlert = true
            })
    }

    func unCompress(file: URL) {
        InstallMiniApp(pkgFile: file, onSuccess: {
            ProgressHUD.succeed("Success")
            dismiss()
            onSuccess?()
        }, onFailed: { err in
            alertMsg = err
            showAlert = true
        })
    }
}
