//
//  ImagePreviewViewController.swift
//  minip
//
//  Created by ByteDance on 2023/7/15.
//

import Kingfisher
import Photos
import UIKit

class ImagePreviewViewController: UIViewController {
    var imageView: ZoomableImageView!
    var imageURL: URL?

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
        } else {
            overrideUserInterfaceStyle = .dark
            view.backgroundColor = .black.withAlphaComponent(0.4)
        }

        imageView = ZoomableImageView()
        imageView.zoomMode = .fit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        imageView.showsVerticalScrollIndicator = true
        imageView.showsHorizontalScrollIndicator = true

        if let url = imageURL {
            if url.scheme == "file" {
                if let img = UIImage(contentsOfFile: url.path) {
                    imageView.image = img
                    imageView.onSuccessLoadImage()
                } else {
                    imageView.showErrorMsg(err: ErrorMsg(errorDescription: "Cannot read this file."))
                }
            } else {
                imageView.setWebImage(url: url)
            }
        }

        if navigationController == nil {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
            view.addGestureRecognizer(tapGestureRecognizer)
            tapGestureRecognizer.require(toFail: imageView.doubleTapGesture)
        }

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        view.addGestureRecognizer(longPressRecognizer)

        if let pnv = navigationController as? PannableNavigationViewController {
            pnv.addPanGesture(vc: self)
            navigationController?.navigationBar.scrollEdgeAppearance = UINavigationBarAppearance()
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), primaryAction: UIAction(handler: { [weak self] _ in
                self?.dismiss(animated: true)
            }))
        }
    }

    @objc func tapped(sender: UITapGestureRecognizer) {
        if navigationController == nil {
            dismiss(animated: true)
        }
    }

    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            ShortShake()

            let alertController = UIAlertController(title: "Actions", message: "Select an action", preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Save to album", style: .default, handler: { [weak self] _ in
                guard let img = self?.imageView.image else {
                    ShowSimpleError(err: ErrorMsg(errorDescription: "Error image"))
                    return
                }
                PHPhotoLibrary.requestAuthorization { status in
                    if status == .authorized {
                        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                        DispatchQueue.main.async {
                            ShowSimpleSuccess()
                        }
                    } else {
                        DispatchQueue.main.async {
                            ShowSimpleError(err: ErrorMsg(errorDescription: "Cannot save to album, no permission or limitted"))
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

            alertController.popoverPresentationController?.sourceView = view
            alertController.popoverPresentationController?.sourceRect = view.bounds
            present(alertController, animated: true)
        }
    }
}
