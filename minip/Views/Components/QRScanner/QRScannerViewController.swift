//
//  QRScannerViewController.swift
//  minip
//
//  Created by LZY on 2025/2/13.
//

import AVFoundation
import UIKit

class QRScannerViewController: UIViewController {
    var qrScannerView: QRScannerView!
    var flashButton: FlashButton!
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

        closeButton = UIButton()
        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.layer.cornerRadius = 18

        NSLayoutConstraint.activate([
            flashButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            flashButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            flashButton.widthAnchor.constraint(equalToConstant: 70),
            flashButton.heightAnchor.constraint(equalToConstant: 70),

            qrScannerView.topAnchor.constraint(equalTo: view.topAnchor),
            qrScannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            qrScannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            qrScannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36)
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
