//
//  QRScannerViewController.swift
//  minip
//
//  Created by LZY on 2025/2/13.
//

import AVFoundation
import CoreImage
import Photos
import UIKit

class QRScannerViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var qrScannerView: QRScannerView!
    var flashButton: FlashButton!
    var albumButton: UIButton!
    var closeButton: UIButton!
    var onCanceled: (()->Void)?
    var onSucceed: ((String)->Void)?
    var onFailed: ((Error)->Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupQRScannerView()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    private func setupQRScannerView() {
        view.backgroundColor = .black
        qrScannerView = QRScannerView(frame: view.bounds)
        view.addSubview(qrScannerView)
        qrScannerView.translatesAutoresizingMaskIntoConstraints = false
        qrScannerView.configure(delegate: self, input: .init(isBlurEffectEnabled: true))
        qrScannerView.startRunning()

        flashButton = FlashButton()
        flashButton.addTarget(self, action: #selector(tapFlashButton(_:)), for: .touchUpInside)
        view.addSubview(flashButton)
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        flashButton.layer.cornerRadius = 35

        albumButton = UIButton()
        view.addSubview(albumButton)
        albumButton.translatesAutoresizingMaskIntoConstraints = false
        albumButton.layer.cornerRadius = 35

        closeButton = UIButton()
        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.layer.cornerRadius = 18

        NSLayoutConstraint.activate([
            flashButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            flashButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            flashButton.widthAnchor.constraint(equalToConstant: 70),
            flashButton.heightAnchor.constraint(equalToConstant: 70),

            albumButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            albumButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            albumButton.widthAnchor.constraint(equalToConstant: 70),
            albumButton.heightAnchor.constraint(equalToConstant: 70),

            qrScannerView.topAnchor.constraint(equalTo: view.topAnchor),
            qrScannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            qrScannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            qrScannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),
        ])

        let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
        closeButton.clipsToBounds = true

        blurEffectView.frame = closeButton.bounds
        blurEffectView.isUserInteractionEnabled = false
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        closeButton.insertSubview(blurEffectView, at: 0)

        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(textStyle: .body)), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(tapCloseButton), for: .touchUpInside)

        if let imageView = closeButton.imageView {
            closeButton.bringSubviewToFront(imageView)
        }

        let blurEffectView2 = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
        albumButton.clipsToBounds = true

        blurEffectView2.frame = albumButton.bounds
        blurEffectView2.isUserInteractionEnabled = false
        blurEffectView2.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        albumButton.insertSubview(blurEffectView2, at: 0)

        albumButton.setImage(UIImage(systemName: "photo", withConfiguration: UIImage.SymbolConfiguration(textStyle: .title1)), for: .normal)
        albumButton.tintColor = .white
        albumButton.addTarget(self, action: #selector(tapAlbumButton), for: .touchUpInside)

        if let imageView = albumButton.imageView {
            albumButton.bringSubviewToFront(imageView)
        }
    }

    @objc func tapCloseButton() {
        dismiss(animated: true)
        onCanceled?()
    }

    @objc func tapFlashButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        qrScannerView.setTorchActive(isOn: sender.isSelected)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    @objc func tapAlbumButton() {
        checkPhotoLibraryPermission()
    }

    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        qrScannerView.stopRunning()

        switch status {
        case .authorized, .limited:
            presentImagePicker()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self?.presentImagePicker()
                    } else {
                        self?.showPermissionDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionDeniedAlert()
        @unknown default:
            showPermissionDeniedAlert()
        }
    }

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Cannot Access Photo Library",
            message: "Please allow access to your photo library in Settings to select images.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.qrScannerView.startRunning()
        })
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(settingsURL)
        })
        present(alert, animated: true)
    }

    private func presentImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: { [weak self] in
            guard let image = info[.originalImage] as? UIImage else {
                self?.showError(message: "Cannot get image")
                return
            }

            if let qrCodeContent = self?.detectQRCode(in: image) {
                DispatchQueue.main.async { [weak self] in
                    self?.dismiss(animated: true)
                    self?.onSucceed?(qrCodeContent)
                }
            } else {
                self?.showError(message: "No QRCode in this image")
            }
        })
    }

    private func detectQRCode(in image: UIImage)->String? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: nil,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )

        let features = detector?.features(in: ciImage) ?? []

        for feature in features {
            if let qrFeature = feature as? CIQRCodeFeature {
                return qrFeature.messageString
            }
        }

        return nil
    }

    private func showError(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak self] _ in
            self?.qrScannerView.startRunning()
        }))
        present(alert, animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: { [weak self] in
            self?.qrScannerView.startRunning()
        })
    }
}

extension QRScannerViewController: QRScannerViewDelegate {
    func qrScannerView(_ qrScannerView: QRScannerView, didFailure error: QRScannerError) {
        onFailed?(error)
        dismiss(animated: true)
    }

    func qrScannerView(_ qrScannerView: QRScannerView, didSuccess code: String) {
        qrScannerView.stopRunning()
        DispatchQueue.main.asyncAfter(deadline: .now() + qrScannerView.animationDuration + 0.1) { [weak self] in
            self?.dismiss(animated: true)
            self?.onSucceed?(code)
        }
    }
}
