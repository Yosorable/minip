//
//  DownloadProjectView.swift
//  minip
//
//  Created by ByteDance on 2023/7/14.
//

import SwiftUI
import PKHUD
import Alamofire
import ZipArchive
import Defaults

struct DownloadProjectView: View {
    @Environment(\.dismiss) var dismiss
    
    var onSuccess: (()->Void)?
    
    @State var downURL: String = Defaults[.lastDownloadedURL]
    @State var downFilename: String = ""
    
    @State var showAlert = false
    @State var alertMsg = ""
    
    @State var downloading: Bool = false
    @State var downProgress: Progress? = nil
    @State var uncompressing: Bool = false
    
    @State var downloadReq: DownloadRequest? = nil
    
    var body: some View {
        NavigationStack {
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
                        Text("only support zip file")
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
                    Text("Download files are stored at tmp directory in documents. You need to manually delete them.")
                }
                if downloading || uncompressing {
                    Section {
                        Button(role: .destructive, action: {
                            downloadReq?.cancel()
                            downloading = false
                        }, label: {
                            HStack{
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
            .alert(isPresented: $showAlert, error: ErrorMsg(errorDescription: alertMsg)) {}
        }
    }
    
    func downloadFile() {
        guard let downurl = URL(string: downURL) else {
            alertMsg = "Error URL"
            showAlert = true
            return
        }
        downloading = true
        let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destination: (URL, HTTPURLResponse) -> (URL, DownloadRequest.Options) = { tmpURL, res in
            let pathComponent = res.suggestedFilename ?? "default.zip"
            
            let finalPath = docURL.appending(path: "tmp").appendingPathComponent(pathComponent)
            return (finalPath, [.createIntermediateDirectories, .removePreviousFile])
        }
        downloadReq = AF.download(downurl, to: destination)
            .downloadProgress { progress in
                downProgress = progress
                print("\(progress.fractionCompleted)")
            }
            .response(completionHandler: { resp in
                downloading = false
                if let err = resp.error {
                    alertMsg = err.localizedDescription
                    showAlert = true
                    return
                } else if let tmpUrl = resp.fileURL {
                    uncompressing = true
                    HUD.flash(.labeledSuccess(title: nil, subtitle: "Downloaded success, uncompressing"), delay: 1, completion: { _ in
                        unCompress(file: tmpUrl)
                        uncompressing = false
                        Defaults[.lastDownloadedURL] = downURL
                    })
                    return
                }
                alertMsg = "Unknow error"
                showAlert = true
            })
        
    }
    
    func unCompress(file: URL) {
        let dest = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if SSZipArchive.unzipFile(atPath: file.path(), toDestination: dest.path()) {
            HUD.flash(.labeledSuccess(title: nil, subtitle: "Success"), delay: 1, completion: { _ in
                dismiss()
                onSuccess?()
            })
            return
        }
        alertMsg = "Unknow error"
        showAlert = true
    }
}

struct ErrorMsg: LocalizedError {
    var errorDescription: String?
}
