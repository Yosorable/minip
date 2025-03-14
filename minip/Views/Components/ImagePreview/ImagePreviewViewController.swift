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
    var imageView: ZoomImageView!
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
        imageView = ZoomImageView()
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

        imageView.maximumZoomScale = 5
        if let url = imageURL {
            if url.scheme == "file" {
                imageView.image = UIImage(contentsOfFile: url.path)
            } else {
                imageView.setWebImage(url: url)
            }
        }
        view.backgroundColor = .black

        // not in a navigation view
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
        dismiss(animated: true)
    }

    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            ShortShake()

            let alertController = UIAlertController(title: "Action", message: "Select one action", preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
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

            if let ppc = alertController.popoverPresentationController {
                ppc.sourceView = view
                ppc.sourceRect = CGRectMake(view.bounds.size.width / 2.0, view.bounds.size.height / 2.0, 1.0, 1.0)
            }
            present(alertController, animated: true)
        }
    }
}

open class ZoomImageView: UIScrollView, UIScrollViewDelegate {
    public enum ZoomMode {
        case fit
        case fill
    }

    // MARK: - Properties

    public let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.allowsEdgeAntialiasing = true
        return imageView
    }()

    public func setWebImage(url: URL?) {
        imageView.kf.setImage(with: url, completionHandler: { [weak self] _ in
            self?.updateImageView()
            self?.scrollToCenter()
        })
    }

    public var zoomMode: ZoomMode = .fit {
        didSet {
            updateImageView()
            scrollToCenter()
        }
    }

    open var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            let oldImage = imageView.image
            imageView.image = newValue

            if oldImage?.size != newValue?.size {
                oldSize = nil
                updateImageView()
            }
            scrollToCenter()
        }
    }

    override open var intrinsicContentSize: CGSize {
        return imageView.intrinsicContentSize
    }

    private var oldSize: CGSize?

    // MARK: - Initializers

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public init(image: UIImage) {
        super.init(frame: CGRect.zero)
        self.image = image
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    // MARK: - Functions

    open func scrollToCenter() {
        let centerOffset = CGPoint(
            x: contentSize.width > bounds.width ? (contentSize.width / 2) - (bounds.width / 2) : 0,
            y: contentSize.height > bounds.height ? (contentSize.height / 2) - (bounds.height / 2) : 0
        )

        contentOffset = centerOffset
    }

    var doubleTapGesture: UITapGestureRecognizer!
    open func setup() {
        contentInsetAdjustmentBehavior = .never

        backgroundColor = UIColor.clear
        delegate = self
        imageView.contentMode = .scaleAspectFill
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        addSubview(imageView)

        doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)
    }

    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        if imageView.image != nil && oldSize != bounds.size {
            updateImageView()
            oldSize = bounds.size
        }

        if imageView.frame.width <= bounds.width {
            imageView.center.x = bounds.width * 0.5
        }

        if imageView.frame.height <= bounds.height {
            imageView.center.y = bounds.height * 0.5
        }
    }

    override open func updateConstraints() {
        super.updateConstraints()
        updateImageView()
    }

    private func updateImageView() {
        func fitSize(aspectRatio: CGSize, boundingSize: CGSize) -> CGSize {
            let widthRatio = (boundingSize.width / aspectRatio.width)
            let heightRatio = (boundingSize.height / aspectRatio.height)

            var boundingSize = boundingSize

            if widthRatio < heightRatio {
                boundingSize.height = boundingSize.width / aspectRatio.width * aspectRatio.height
            } else if heightRatio < widthRatio {
                boundingSize.width = boundingSize.height / aspectRatio.height * aspectRatio.width
            }
            return CGSize(width: ceil(boundingSize.width), height: ceil(boundingSize.height))
        }

        func fillSize(aspectRatio: CGSize, minimumSize: CGSize) -> CGSize {
            let widthRatio = (minimumSize.width / aspectRatio.width)
            let heightRatio = (minimumSize.height / aspectRatio.height)

            var minimumSize = minimumSize

            if widthRatio > heightRatio {
                minimumSize.height = minimumSize.width / aspectRatio.width * aspectRatio.height
            } else if heightRatio > widthRatio {
                minimumSize.width = minimumSize.height / aspectRatio.height * aspectRatio.width
            }
            return CGSize(width: ceil(minimumSize.width), height: ceil(minimumSize.height))
        }

        guard let image = imageView.image else { return }

        var size: CGSize

        switch zoomMode {
        case .fit:
            size = fitSize(aspectRatio: image.size, boundingSize: bounds.size)
        case .fill:
            size = fillSize(aspectRatio: image.size, minimumSize: bounds.size)
        }

        size.height = round(size.height)
        size.width = round(size.width)

        zoomScale = 1
        //    maximumZoomScale = image.size.width / size.width
        imageView.bounds.size = size
        contentSize = size
        imageView.center = ZoomImageView.contentCenter(forBoundingSize: bounds.size, contentSize: contentSize)
    }

    @objc private func handleDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if zoomScale == 1 {
            zoom(
                to: zoomRectFor(
                    scale: max(1, maximumZoomScale / 3),
                    with: gestureRecognizer.location(in: gestureRecognizer.view)
                ),
                animated: true
            )
        } else {
            setZoomScale(1, animated: true)
        }
    }

    private func zoomRectFor(scale: CGFloat, with center: CGPoint) -> CGRect {
        let center = imageView.convert(center, from: self)

        var zoomRect = CGRect()
        zoomRect.size.height = bounds.height / scale
        zoomRect.size.width = bounds.width / scale
        zoomRect.origin.x = center.x - zoomRect.width / 2.0
        zoomRect.origin.y = center.y - zoomRect.height / 2.0

        return zoomRect
    }

    // MARK: - UIScrollViewDelegate

    @objc public dynamic func scrollViewDidZoom(_ scrollView: UIScrollView) {
        imageView.center = ZoomImageView.contentCenter(forBoundingSize: bounds.size, contentSize: contentSize)
    }

    @objc public dynamic func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {}

    @objc public dynamic func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {}

    @objc public dynamic func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    @inline(__always)
    private static func contentCenter(forBoundingSize boundingSize: CGSize, contentSize: CGSize) -> CGPoint {
        /// When the zoom scale changes i.e. the image is zoomed in or out, the hypothetical center
        /// of content view changes too. But the default Apple implementation is keeping the last center
        /// value which doesn't make much sense. If the image ratio is not matching the screen
        /// ratio, there will be some empty space horizontaly or verticaly. This needs to be calculated
        /// so that we can get the correct new center value. When these are added, edges of contentView
        /// are aligned in realtime and always aligned with corners of scrollview.
        let horizontalOffest = (boundingSize.width > contentSize.width) ? ((boundingSize.width - contentSize.width) * 0.5) : 0.0
        let verticalOffset = (boundingSize.height > contentSize.height) ? ((boundingSize.height - contentSize.height) * 0.5) : 0.0

        return CGPoint(x: contentSize.width * 0.5 + horizontalOffest, y: contentSize.height * 0.5 + verticalOffset)
    }
}
