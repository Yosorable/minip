//
//  ImagePreviewViewController.swift
//  minip
//
//  Created by ByteDance on 2023/7/15.
//

import UIKit
import Photos

class ImagePreviewViewController: UIViewController {
    var imageURL: URL?
    var zoomableImageView: ZoomableImageView!

    init(imageURL: URL? = nil) {
        self.imageURL = imageURL

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if navigationController != nil {
            view.backgroundColor = .systemBackground
            zoomableImageView = ZoomableImageView(disablePanGesture: true)

            navigationController?.navigationBar.scrollEdgeAppearance = UINavigationBarAppearance()
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), primaryAction: UIAction(handler: { [weak self] _ in
                self?.dismiss(animated: true)
            }))
        } else {
            zoomableImageView = ZoomableImageView()
            zoomableImageView.parentVC = self
            overrideUserInterfaceStyle = .dark
            view.backgroundColor = .black.withAlphaComponent(0.4)
            zoomableImageView.parentBackground = view.backgroundColor ?? .clear
            zoomableImageView.panGestureReleasedHandler = { [weak self] swipeDown in
                if (swipeDown) {
                    self?.dismiss(animated: true)
                }
            }
            zoomableImageView.tapHandler = { [weak self] in
                self?.dismiss(animated: true)
            }
        }

        if let url = imageURL {
            if url.scheme == "file" {
                if let img = UIImage(contentsOfFile: url.path) {
                    zoomableImageView.imageView.image = img
                    zoomableImageView.onSuccessLoadImage()
                } else {
                    zoomableImageView.showErrorMsg(err: ErrorMsg(errorDescription: "Cannot read this file."))
                }
            } else {
                zoomableImageView.imageView.kf.setImage(with: imageURL, completionHandler: { [weak self] result in
                    switch result {
                    case .success:
                        self?.zoomableImageView.onSuccessLoadImage()
                    case .failure:
                        self?.zoomableImageView.showErrorMsg(err: ErrorMsg(errorDescription: "Cannot load remote resource.\nTap to dismiss."))
                    }
                })
            }
        }

        zoomableImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(zoomableImageView)
        NSLayoutConstraint.activate([
            zoomableImageView.topAnchor.constraint(equalTo: view.topAnchor),
            zoomableImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            zoomableImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            zoomableImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        zoomableImageView.longPressedHandler = { [weak self] gesture in
            self?.longPressed(sender: gesture)
        }

        if let pnv = navigationController as? PannableNavigationViewController {
            pnv.addPanGesture(vc: self)
        }
    }

    func longPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            shortShake()

            let alertController = UIAlertController(title: "Actions", message: "Select an action", preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Save to album", style: .default, handler: { [weak self] _ in
                guard let img = self?.zoomableImageView.imageView.image, let pngData = img.pngData() else {
                    showSimpleError(err: ErrorMsg(errorDescription: "Error image"))
                    return
                }
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                    guard status == .authorized || status == .limited else {
                        DispatchQueue.main.async {
                            showSimpleError(err: ErrorMsg(errorDescription: "Cannot save to album, no permission or limitted"))
                        }
                        return
                    }
                    PHPhotoLibrary.shared().performChanges({
                        let request = PHAssetCreationRequest.forAsset()
                        request.addResource(with: .photo, data: pngData, options: nil)
                    }) { success, error in
                        DispatchQueue.main.async {
                            if success {
                                showSimpleSuccess()
                            } else {
                                showSimpleError(err: ErrorMsg(errorDescription: error?.localizedDescription ?? "Cannot save to album, unknown error"))
                            }
                        }
                    }
                }
            }))
            if let tintColor = MiniAppManager.shared.openedApp?.tintColor {
                alertController.view.tintColor = UIColor(hexOrCSSName: tintColor)
            }
            if let colorScheme = MiniAppManager.shared.openedApp?.colorScheme {
                if colorScheme == "dark" {
                    alertController.overrideUserInterfaceStyle = .dark
                } else if colorScheme == "light" {
                    alertController.overrideUserInterfaceStyle = .light
                }
            }

            alertController.popoverPresentationController?.sourceView = zoomableImageView
            alertController.popoverPresentationController?.sourceRect = zoomableImageView.bounds
            present(alertController, animated: true)
        }
    }
}
