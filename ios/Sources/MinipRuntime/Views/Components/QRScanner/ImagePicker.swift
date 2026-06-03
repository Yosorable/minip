//
//  ImagePicker.swift
//  minip
//
//  Created by ByteDance on 2025/8/27.
//

import CoreImage
import Photos
import UIKit

extension QRScannerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAdaptivePresentationControllerDelegate {
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

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: { [weak self] in
            self?.qrScannerView.startRunning()
        })
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        qrScannerView.startRunning()
    }

    func checkPhotoLibraryPermission() {
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
        imagePicker.presentationController?.delegate = self
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true)
    }

    private func detectQRCode(in image: UIImage) -> String? {
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
}
