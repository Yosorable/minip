//
//  FileBrowserView.swift
//  minip
//
//  Created by ByteDance on 2023/7/9.
//

import ProgressHUD
import SwiftUI
import UniformTypeIdentifiers

struct FileBrowserView: View {
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                FileBrowserPageView(path: "/")
            }
        } else {
            NavigationView {
                FileBrowserPageView(path: "/")
            }
        }
    }
}

struct FileBrowserPageView: View {
    @ObservedObject var viewModel: FileBrowserPageViewModel
    init(path: String) {
        viewModel = FileBrowserPageViewModel(path: path)
    }

    var list: some View {
        if #available(iOS 15.0, *) {
            return List {
                ForEach(viewModel.files, id: \.id) { ele in
                    if ele.isFolder {
                        folderItem(ele: ele)
                    } else {
                        fileItem(ele: ele)
                    }
                }
            }
            .refreshable {
                viewModel.fetchFiles()
            }
            .onAppear {
                viewModel.fetchFiles()
            }
        } else {
            return List {
                ForEach(viewModel.files, id: \.id) { ele in
                    if ele.isFolder {
                        folderItem(ele: ele)
                    } else {
                        fileItem(ele: ele)
                    }
                }
            }
            .onAppear {
                viewModel.fetchFiles()
            }
        }
    }

    var body: some View {
        list
            .navigationTitle(Text(viewModel.path == "/" ? i18n("Files") : (viewModel.path.splitPolyfill(separator: "/").last ?? "")))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.path == "/.Trash" {
                        Button {
                            cleanTrash()
                        } label: {
                            Text(i18n("f.clean_trash"))
                                .foregroundColor(.red)
                        }
                    } else if !viewModel.path.contains("/.Trash") {
                        Menu {
                            Button {
                                createFile()
                            } label: {
                                Label(i18n("f.create_file"), systemImage: "doc")
                            }
                            Button {
                                createFolder()
                            } label: {
                                Label(i18n("f.create_folder"), systemImage: "folder")
                            }
                        } label: {
                            Image(systemName: "plus.app.fill")
                        }
                    }
                }
            }
    }

    func fileItem(ele: FileInfo) -> some View {
        let openFileFunc = {
            var cannotOpen = false
            if let utType = try? ele.url.resourceValues(forKeys: [.contentTypeKey]).contentType {
                if utType.conforms(to: .text) {
                    let vc = CodeEditorViewController(fileInfo: ele)
                    let nvc = PannableNavigationViewController(rootViewController: vc)
                    nvc.modalPresentationStyle = .fullScreen
                    GetTopViewController()?.present(nvc, animated: true)
                } else if utType.conforms(to: .image) {
                    let imageVC = ImagePreviewViewController(imageURL: ele.url)
                    imageVC.title = ele.fileName
                    let nvc = PannableNavigationViewController(rootViewController: imageVC)
                    nvc.modalPresentationStyle = .fullScreen
                    nvc.overrideUserInterfaceStyle = .dark
                    GetTopViewController()?.present(nvc, animated: true)
                } else {
                    cannotOpen = true
                }
            } else {
                cannotOpen = true
            }

            if cannotOpen {
                ProgressHUD.failed("Cannot open this file.")
            }
        }
        if #available(iOS 15.0, *) {
            return HStack {
                Image(systemName: FileManager.isImage(url: ele.url) ? "photo" : "doc")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 35, height: 35)
                Text(ele.fileName)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }
            .swipeActions {
                Button {
                    deleteFile(url: ele.url)
                } label: {
                    Text(i18n("Delete"))
                }
                .tint(.red)
            }
            .contentShape(Rectangle())
            .onTapGesture { openFileFunc() }
        } else {
            // TODO: 支持滑动删除
            return HStack {
                Image(systemName: FileManager.isImage(url: ele.url) ? "photo" : "doc")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 35, height: 35)
                Text(ele.fileName)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture { openFileFunc() }
        }
    }

    func folderItem(ele: FileInfo) -> some View {
        if #available(iOS 15.0, *) {
            return NavigationLink {
                LazyView {
                    FileBrowserPageView(path: "\(viewModel.path == "/" ? "" : viewModel.path)/\(ele.fileName)")
                }
            } label: {
                HStack {
                    if viewModel.path == "/" && ele.fileName == ".Trash" {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .frame(width: 35, height: 35)
                    } else {
                        Image(systemName: "folder")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .frame(width: 35, height: 35)
                    }
                    Text(ele.fileName)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .swipeActions {
                    Button {
                        deleteFolder(url: ele.url)
                    } label: {
                        Text(i18n("Delete"))
                    }
                    .tint(.red)
                }
            }
        } else {
            return NavigationLink {
                LazyView {
                    FileBrowserPageView(path: "\(viewModel.path == "/" ? "" : viewModel.path)/\(ele.fileName)")
                }
            } label: {
                HStack {
                    if viewModel.path == "/" && ele.fileName == ".Trash" {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .frame(width: 35, height: 35)
                    } else {
                        Image(systemName: "folder")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .frame(width: 35, height: 35)
                    }
                    Text(ele.fileName)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
    }

    func cleanTrash() {
        let alertController = UIAlertController(title: i18n("Confirm"), message: i18n("f.clean_trash_confirm"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: i18n("f.clean_trash"), style: .destructive, handler: { _ in
            CleanTrashAsync {
                ShowSimpleSuccess()
                viewModel.fetchFiles()
            } onError: { err in
                ShowSimpleError(err: err)
            }
        }))
        alertController.show()
    }

    func createFile() {
        let alertController = UIAlertController(title: i18n("f.create_file"), message: i18n("f.create_file_tip"), preferredStyle: .alert)
        var textField: UITextField?
        alertController.addTextField { tf in
            tf.placeholder = i18n("f.file_name")
            textField = tf
        }
        alertController.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: i18n("Create"), style: .default, handler: { _ in
            guard let fileName = textField?.text else {
                return
            }

            let fileManager = FileManager.default
            let folderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPolyfill(path: viewModel.path)
            let newFileURL = folderURL.appendingPolyfill(component: fileName)

            if !fileManager.fileExists(atPath: newFileURL.path) {
                if fileManager.createFile(atPath: newFileURL.path, contents: nil) {
                    ShowSimpleSuccess(msg: i18n("created_successfully"))
                    viewModel.fetchFiles()
                } else {
                    ShowSimpleError()
                }
            } else {
                ShowSimpleError(err: ErrorMsg(errorDescription: "File exists"))
            }
        }))
        alertController.show()
    }

    func createFolder() {
        let alertController = UIAlertController(title: i18n("f.create_folder"), message: i18n("f.create_folder_tip"), preferredStyle: .alert)
        var textField: UITextField?
        alertController.addTextField { tf in
            tf.placeholder = i18n("f.folder_name")
            textField = tf
        }
        alertController.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: i18n("Create"), style: .default, handler: { _ in
            guard let fileName = textField?.text else {
                return
            }

            let fileManager = FileManager.default
            let folderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPolyfill(path: viewModel.path)
            let newFileURL = folderURL.appendingPolyfill(component: fileName)

            if !fileManager.fileExists(atPath: newFileURL.path) {
                do {
                    try fileManager.createDirectory(at: newFileURL, withIntermediateDirectories: false)
                    ShowSimpleSuccess(msg: i18n("created_successfully"))
                    viewModel.fetchFiles()
                } catch {
                    ShowSimpleError(err: error)
                }

            } else {
                ShowSimpleError(err: ErrorMsg(errorDescription: "Folder exists"))
            }
        }))
        alertController.show()
    }

    func deleteFolder(url: URL?) {
        guard let url = url else {
            return
        }
        if viewModel.path == "/" && url.lastPathComponent == ".Trash" {
            ShowSimpleError(err: ErrorMsg(errorDescription: "You cannot delete this folder"))
            return
        }

        let alertController = UIAlertController(title: i18n("Confirm"), message: i18nF("f.delete_folder_confirm_message", url.lastPathComponent), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: i18n("Delete"), style: .destructive, handler: { _ in
            do {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                ShowSimpleSuccess(msg: i18n("f.moved_to_trash"))
                viewModel.fetchFiles()
            } catch {
                ShowSimpleError(err: error)
            }
        }))
        alertController.show()
    }

    func deleteFile(url: URL?) {
        guard let url = url else {
            return
        }
        let alertController = UIAlertController(title: i18n("Confirm"), message: i18nF("f.delete_file_confirm_message", url.lastPathComponent), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: i18n("Delete"), style: .destructive, handler: { _ in
            do {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                ShowSimpleSuccess(msg: i18n("f.moved_to_trash"))
                viewModel.fetchFiles()
            } catch {
                ShowSimpleError(err: error)
            }
        }))
        alertController.show()
    }
}

struct FileInfo: Identifiable {
    var fileName: String
    var isFolder: Bool
    var url: URL

    var id: String {
        return fileName
    }
}

class FileBrowserPageViewModel: ObservableObject {
    @Published var files: [FileInfo] = []
    var path: String

    init(path: String) {
        self.path = path
    }

    func fetchFiles() {
        logger.debug("[fetchFiles] fetch files")
        let fileManager = FileManager.default
        let folderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPolyfill(path: path)
        var res = [FileInfo]()
        do {
            var (folderURLs, fileURLs) = try getFilesAndFolders(in: folderURL)
            folderURLs.sort {
                $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
            }
            // set trash folder to first
            if let idx = folderURLs.firstIndex(where: { $0.lastPathComponent == ".Trash" }) {
                folderURLs.insert(folderURLs.remove(at: idx), at: 0)
            }
            fileURLs.sort {
                $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
            }
            for folderURL in folderURLs {
                res.append(FileInfo(fileName: folderURL.lastPathComponent, isFolder: true, url: folderURL))
            }
            for fileURL in fileURLs {
                res.append(FileInfo(fileName: fileURL.lastPathComponent, isFolder: false, url: fileURL))
            }
            files = res
        } catch {
            logger.error("[fetchFiles] \(error)")
        }
    }

    func getFilesAndFolders(in directory: URL) throws -> (folders: [URL], files: [URL]) {
        var folders = [URL]()
        var files = [URL]()

        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)

        for content in contents {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: content.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    folders.append(content)
                } else {
                    files.append(content)
                }
            }
        }

        folders.sort(by: { l, r in
            l.lastPathComponent < r.lastPathComponent
        })

        files.sort(by: { l, r in
            l.lastPathComponent < r.lastPathComponent
        })
        return (folders, files)
    }
}
