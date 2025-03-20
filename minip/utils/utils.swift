//
//  utils.swift
//  minip
//
//  Created by ByteDance on 2023/7/6.
//

import AudioToolbox
import Foundation
import os.log
import ProgressHUD
import UIKit

func WriteToFile(data: Data, fileName: String) -> Bool {
    // get path of directory
    guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return false
    }
    // create file url
    let fileurl = directory.appendingPathComponent(fileName)

    logger.debug("[WriteToFile] file uri: \(fileurl)")

    do {
        try data.write(to: fileurl, options: .atomic)
        return true
    } catch {
        logger.error("[WriteToFile] Unable to write in new file.")
        return false
    }
}

func readFile(fileName: String) -> [UInt8] {
    guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return [UInt8]()
    }
    let fileurl = directory.appendingPathComponent(fileName)
    do {
        let rawData: Data = try Data(contentsOf: fileurl)
        return [UInt8](rawData)
    } catch {
        return [UInt8]()
    }
}

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

func ShowSimpleSuccess(msg: String? = nil) {
    ProgressHUD.succeed(msg ?? i18n("Success"))
}

func ShowSimpleError(err: Error? = nil) {
    ProgressHUD.failed(err?.localizedDescription ?? "Error")
}

func CleanTrashAsync(onComplete: (() -> Void)? = nil, onError: ((Error) -> Void)? = nil) {
    DispatchQueue.global().async {
        let trashURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPolyfill(path: ".Trash")

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: trashURL, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
            DispatchQueue.main.async {
                onComplete?()
            }
        } catch {
            DispatchQueue.main.async {
                onError?(error)
            }
        }
    }
}

// alert
extension UIAlertController {
    func showOnTopViewController(completion: (() -> Void)? = nil) {
        let kw = UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .last { $0.isKeyWindow }
        if var topController = kw?.rootViewController {
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

func PreviewImage(url: URL? = nil, vc: UIViewController? = nil) {
    guard let url = url else {
        return
    }

    let pvc = ImagePreviewViewController(imageURL: url)
    pvc.modalPresentationStyle = .overFullScreen
    pvc.modalTransitionStyle = .crossDissolve
    if let vc = vc {
        vc.present(pvc, animated: true)
        return
    }

    let tvc = GetTopViewController()

    if let nvc = tvc?.navigationController {
        nvc.present(pvc, animated: true)
    } else {
        tvc?.present(pvc, animated: true)
    }
}

// sound
func ShortShake() {
    let soundShort = SystemSoundID(1519)
    AudioServicesPlaySystemSound(soundShort)
}
