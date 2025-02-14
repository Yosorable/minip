//
//  FilePickerView.swift
//  minip
//
//  Created by ByteDance on 2023/7/14.
//

import SwiftUI

import MobileCoreServices
import ProgressHUD
import SwiftUI
import UniformTypeIdentifiers
import ZipArchive

struct FileImporterView: UIViewControllerRepresentable {
    var onSuccess: (() -> Void)?
    @Environment(\.presentationMode) var presentationMode

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.zip], asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No update needed
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FileImporterView

        init(_ parent: FileImporterView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let path = urls.first?.path else {
                ProgressHUD.failed("Path error")
                return
            }

            ProgressHUD.animate("Loading", interaction: false)
            let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

            InstallMiniApp(pkgFile: urls.first!, onSuccess: {
                ProgressHUD.succeed("Success")
                self.parent.onSuccess?()
            }, onFailed: { err in
                ProgressHUD.failed(err)
            })
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
