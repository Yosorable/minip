//
//  utils.swift
//  minip
//
//  Created by ByteDance on 2023/7/6.
//

import AudioToolbox
import Foundation
import ProgressHUD
import UIKit
import os.log

func showSimpleSuccess(msg: String? = nil) {
    ProgressHUD.succeed(msg ?? i18n("Success"))
}

func showSimpleError(err: Error? = nil) {
    ProgressHUD.failed(err?.localizedDescription ?? "Error")
}


func getKeyWindowUIViewController() -> UIViewController? {
    let kw = UIApplication
        .shared
        .connectedScenes
        .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
        .last { $0.isKeyWindow }
    return kw?.rootViewController
}

func getTopViewController(
    controller: UIViewController? = getKeyWindowUIViewController()
) -> UIViewController? {
    if let navigationController = controller as? UINavigationController {
        return getTopViewController(
            controller: navigationController.visibleViewController
        )
    }
    if let tabController = controller as? UITabBarController {
        if let selected = tabController.selectedViewController {
            return getTopViewController(controller: selected)
        }
    }
    if let presented = controller?.presentedViewController {
        return getTopViewController(controller: presented)
    }
    return controller
}

// image preview

func previewImage(url: URL? = nil, vc: UIViewController? = nil, sourceRect: CGRect? = nil, thumbnailImage: UIImage? = nil, onDismiss: (() -> Void)? = nil, onPresentSnapshotReady: (() -> Void)? = nil, fetchSourceRect: ((@escaping (CGRect?) -> Void) -> Void)? = nil) {
    guard let url = url else {
        return
    }

    let pvc = ImagePreviewViewController(imageURL: url, sourceRect: sourceRect, thumbnailImage: thumbnailImage)
    pvc.modalPresentationStyle = .overFullScreen
    if sourceRect == nil {
        pvc.modalTransitionStyle = .crossDissolve
    }
    pvc.onDismiss = onDismiss
    pvc.onPresentSnapshotReady = onPresentSnapshotReady
    pvc.fetchSourceRect = fetchSourceRect
    if let vc = vc {
        vc.present(pvc, animated: true)
        return
    }

    let tvc = getTopViewController()

    if let nvc = tvc?.navigationController {
        nvc.present(pvc, animated: true)
    } else {
        tvc?.present(pvc, animated: true)
    }
}

// sound
func shortShake() {
    let soundShort = SystemSoundID(1519)
    AudioServicesPlaySystemSound(soundShort)
}
