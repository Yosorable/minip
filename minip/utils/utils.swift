//
//  utils.swift
//  minip
//
//  Created by ByteDance on 2023/7/6.
//

import Foundation
import PKHUD
import UIKit
import AudioToolbox
import os.log

func WriteToFile(data: Data, fileName: String) -> Bool {
    // get path of directory
    guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return false
    }
    // create file url
    let fileurl =  directory.appendingPathComponent(fileName)
    
    logger.debug("[WriteToFile] file uri: \(fileurl)")
    
    do{
        try data.write(to: fileurl, options: .atomic)
        return true
    }catch {
        logger.error("[WriteToFile] Unable to write in new file.")
        return false
    }
}

func readFile(fileName: String) -> [UInt8] {
    guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return [UInt8]()
    }
    let fileurl =  directory.appendingPathComponent(fileName)
    do {
        let rawData: Data = try Data(contentsOf: fileurl)
        return [UInt8](rawData)
    } catch {
        return [UInt8]()
    }
}


//func getFile(forResource resource: String, withExtension fileExt: String?) -> [UInt8]? {
//    // See if the file exists.
//    guard let fileUrl: URL = Bundle.main.url(forResource: resource, withExtension: fileExt) else {
//        return nil
//    }
//    
//    do {
//        // Get the raw data from the file.
//        let rawData: Data = try Data(contentsOf: fileUrl)
//
//        // Return the raw data as an array of bytes.
//        return [UInt8](rawData)
//    } catch {
//        // Couldn't read the file.
//        return nil
//    }
//}

func fileOrFolderExists(path: String) -> (Bool, Bool) {
    let fileManager = FileManager.default
    var isDirectory: ObjCBool = false
    let exists = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
    return (exists, isDirectory.boolValue)
}

func mkdir(path: String) {
    try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
}

func touch(path: String, content: Data? = nil) {
    FileManager.default.createFile(atPath: path, contents: content)
}

func cat(url: URL?) -> String {
    guard let url = url else {
        return ""
    }
    do {
        let dt = try Data(contentsOf: url, options: .mappedIfSafe)
        let res = String(data: dt, encoding: .utf8)
        return res ?? ""
    } catch {
        return ""
    }
}

func saveFile(url: URL?, content: String) {
    guard let url = url else {
        return
    }
    do {
        try content.write(to: url, atomically: true, encoding: .utf8)
    } catch {}
}

func ShowNotImplement() {
    HUD.flash(.labeledError(title: nil, subtitle: "Not implement"), delay: 1)
}

func ShowSimpleSuccess(msg: String? = nil) {
    HUD.flash(.labeledSuccess(title: nil, subtitle: msg ?? "Success"), delay: 1)
}

func ShowSimpleError(err: Error? = nil) {
    HUD.flash(.labeledError(title: nil, subtitle: err?.localizedDescription ?? "Error"), delay: 1)
}

func CleanTrashAsync(onComplete: (()->Void)? = nil, onError: ((Error)->Void)? = nil) {
    DispatchQueue.global().async {
        let trashURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPolyfill(path: ".Trash")
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: trashURL, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
            DispatchQueue.main.async {
                onComplete?()
            }
        } catch let error  {
            DispatchQueue.main.async {
                onError?(error)
            }
        }
    }
}


// alert
extension UIAlertController {
    func show(completion: (() -> Void)? = nil) {
        let kw = UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .last { $0.isKeyWindow }
        if var topController = kw?.rootViewController  {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            topController.present(self, animated: true, completion: completion)
        }
    }
}

func GetKeyWindowUIViewController() -> UIViewController? {
    let kw = UIApplication
        .shared
        .connectedScenes
        .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
        .last { $0.isKeyWindow }
    return kw?.rootViewController
}

func GetTopViewController(controller: UIViewController? = GetKeyWindowUIViewController()) -> UIViewController? {
    if let navigationController = controller as? UINavigationController {
        return GetTopViewController(controller: navigationController.visibleViewController)
    }
    if let tabController = controller as? UITabBarController {
        if let selected = tabController.selectedViewController {
            return GetTopViewController(controller: selected)
        }
    }
    if let presented = controller?.presentedViewController {
        return GetTopViewController(controller: presented)
    }
    return controller
}

// image preview

func PreviewImage(url: URL? = nil) {
    guard let url = url else {
        return
    }
    let tvc = GetTopViewController()
    
//    let videoSuffixs = ["mp4", "mov", "avi", "rmvb", "rm", "flv", "3gp", "wmv", "vob", "dat", "m4v", "f4v", "mkv"] // and more suffix
//    let vc = ZLImagePreviewController(datas: [url], index: 0, showSelectBtn: false, showBottomView: false) { url -> ZLURLType in
//        if let sf = url.absoluteString.split(separator: ".").last, videoSuffixs.contains(String(sf)) {
//            return .video
//        } else {
//            return .image
//        }
//    } urlImageLoader: { url, imageView, progress, loadFinish in
//        // Demo used Kingfisher.
//        imageView.kf.setImage(with: url) { receivedSize, totalSize in
//            let percent = (CGFloat(receivedSize) / CGFloat(totalSize))
//            progress(percent)
//        } completionHandler: { _ in
//            loadFinish()
//        }
//    }
//
//    
//    vc.doneBlock = { datas in
//        // your code
//    }
//
//    vc.modalPresentationStyle = .fullScreen
//    tvc?.showDetailViewController(vc, sender: nil)
    
    
    
    let vc = ImagePreviewViewController(imageURL: url)
    vc.modalPresentationStyle = .overFullScreen
    vc.modalTransitionStyle = .crossDissolve

    if let tabc = tvc?.navigationController {
        tabc.present(vc, animated: true)
    } else {
        tvc?.present(vc, animated: true)
    }
}

// sound

func ShortShake() {
    let soundShort = SystemSoundID(1519)
    AudioServicesPlaySystemSound(soundShort)
}
