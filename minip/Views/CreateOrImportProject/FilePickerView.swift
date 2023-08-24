//
//  FilePickerView.swift
//  minip
//
//  Created by ByteDance on 2023/7/14.
//

import SwiftUI

import SwiftUI
import MobileCoreServices
import UniformTypeIdentifiers
import PKHUD
import ZipArchive

struct FileImporterView: UIViewControllerRepresentable {
    var onSuccess: (()->Void)?
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
                HUD.flash(.labeledError(title: "", subtitle: "Path error"), delay: 1)
                return
            }
            HUD.flash(.labeledProgress(title: nil, subtitle: "Loading"), delay: .infinity)
            let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            DispatchQueue.global().async {
                if SSZipArchive.unzipFile(atPath: path, toDestination: docURL.path) {
                    DispatchQueue.main.async { [self] in
                        HUD.flash(.labeledSuccess(title: nil, subtitle: "Success"), delay: 1)
                        self.parent.onSuccess?()
                    }
                } else {
                    DispatchQueue.main.async { [self] in
                        HUD.flash(.labeledError(title: nil, subtitle: "Uncompress error"), delay: 1)
                        self.parent.onSuccess?()
                    }
                }
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
