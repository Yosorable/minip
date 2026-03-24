//
//  PresentationControllerDelegate.swift
//  minip
//
//  Created by LZY on 2025/3/17.
//

import UIKit

extension FileBrowserViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        logger.debug("[FileBrowser] presented ViewController did dismiss, stop editing and fetching files")
        fetchFilesAndUpdateDataSource()
    }
}
