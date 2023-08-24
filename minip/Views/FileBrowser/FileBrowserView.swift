//
//  FileBrowserView.swift
//  minip
//
//  Created by ByteDance on 2023/7/9.
//

import SwiftUI

struct FileBrowserView: View {
    var body: some View {
        NavigationStack {
            FileBrowserPageView(path: "/")
        }
    }
}

struct FileBrowserPageView: View {
    @ObservedObject var viewModel: FileBrowserPageViewModel
    init(path: String) {
        viewModel = FileBrowserPageViewModel(path: path)
    }
    var body: some View {
        List {
            ForEach(viewModel.files, id: \.id) { ele in
                if ele.isFolder {
                    NavigationLink {
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
                        }
                    }
                    .swipeActions {
                        Button {
                            deleteFolder(url: ele.url)
                        } label: {
                            Text("Delete")
                        }
                        .tint(.red)
                    }
                } else {
                    HStack {
                        Image(systemName: FileManager.isImage(url: ele.url) ? "photo" : "doc")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .frame(width: 35, height: 35)
                        Text(ele.fileName)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectFile = ele
                    }
                    .swipeActions {
                        Button {
                            deleteFile(url: ele.url)
                        } label: {
                            Text("Delete")
                        }
                        .tint(.red)
                    }
                }
            }
        }
        .refreshable {
            viewModel.fetchFiles()
        }
        .navigationTitle(Text(viewModel.path == "/" ? "Files" : (viewModel.path.split(separator: "/").last ?? "")))
        .fullScreenCover(item: $viewModel.selectFile) { item in
            EditorView(fileInfo: item)
        }
        .toolbar {
            if viewModel.path == "/.Trash" {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        cleanTrash()
                    } label: {
                        Text("Clean")
                            .foregroundColor(.red)
                    }
                }
            } else if !viewModel.path.contains("/.Trash") {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            createFile()
                        } label: {
                            Label("Create file", systemImage: "doc")
                        }
                        Button {
                            createFolder()
                        } label: {
                            Label("Create folder", systemImage: "folder")
                        }
                    } label: {
                        Image(systemName: "plus.app.fill")
                    }
                }
            }
        }
    }
    
    
    func cleanTrash() {
        let alertController = UIAlertController(title: "Confirm", message: "Are you sure to clean the trash ?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Clean", style: .destructive, handler: { action in
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
        let alertController = UIAlertController(title: "Create file", message: "Please input file name", preferredStyle: .alert)
        var textField: UITextField?
        alertController.addTextField { tf in
            tf.placeholder = "File name"
            textField = tf
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Create", style: .default, handler: { action in
            guard let fileName = textField?.text else {
                return
            }
            
            let fileManager = FileManager.default
            let folderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appending(path: viewModel.path)
            let newFileURL = folderURL.appending(component: fileName)
            
            if !fileManager.fileExists(atPath: newFileURL.path) {
                if fileManager.createFile(atPath: newFileURL.path, contents: nil) {
                    ShowSimpleSuccess(msg: "Created success")
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
        let alertController = UIAlertController(title: "Create folder", message: "Please input folder name", preferredStyle: .alert)
        var textField: UITextField?
        alertController.addTextField { tf in
            tf.placeholder = "Folder name"
            textField = tf
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Create", style: .default, handler: { action in
            guard let fileName = textField?.text else {
                return
            }
            
            let fileManager = FileManager.default
            let folderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appending(path: viewModel.path)
            let newFileURL = folderURL.appending(component: fileName)
            
            if !fileManager.fileExists(atPath: newFileURL.path) {
                do {
                    try fileManager.createDirectory(at: newFileURL, withIntermediateDirectories: false)
                    ShowSimpleSuccess(msg: "Created success")
                    viewModel.fetchFiles()
                } catch let error {
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
        
        let alertController = UIAlertController(title: "Confirm", message: "Are you sure to delete this folder: \(url.lastPathComponent) ?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { action in
            do {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                ShowSimpleSuccess(msg: "Moved to trash")
                viewModel.fetchFiles()
            } catch let error {
                ShowSimpleError(err: error)
            }
        }))
        alertController.show()
    }
    
    func deleteFile(url: URL?) {
        guard let url = url else {
            return
        }
        let alertController = UIAlertController(title: "Confirm", message: "Are you sure to delete this file: \(url.lastPathComponent) ?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { action in
            do {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                ShowSimpleSuccess(msg: "Moved to trash")
                viewModel.fetchFiles()
            } catch let error {
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
    @Published var selectFile: FileInfo? = nil
    var path: String
    
    init(path: String) {
        self.path = path
        fetchFiles()
    }
    
    func fetchFiles() {
        print("fetch files")
        let fileManager = FileManager.default
        let folderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appending(path: path)
        var res = [FileInfo]()
        do {
            let (folderURLs, fileURLs) = try getFilesAndFolders(in: folderURL)
            folderURLs.forEach {
                res.append(FileInfo(fileName: $0.lastPathComponent, isFolder: true, url: $0))
            }
            fileURLs.forEach {
                res.append(FileInfo(fileName: $0.lastPathComponent, isFolder: false, url: $0))
            }
            files = res
        } catch let error {
            print("\(error)")
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
            return l.lastPathComponent < r.lastPathComponent
        })
        
        files.sort(by: { l, r in
            return l.lastPathComponent < r.lastPathComponent
        })
        return (folders, files)
    }
}


