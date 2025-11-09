//
//  ZoomableImageView.swift
//  minip
//
//  Created by LZY on 2025/3/19.
//

import UIKit

class ZoomableImageView: UIScrollView, UIScrollViewDelegate {
    public enum ZoomMode {
        case fit
        case fill
    }

    var errorLabel: UILabel?

    var doubleTapGesture: UITapGestureRecognizer!
    var dragToDismissGesture: UIPanGestureRecognizer!

    // MARK: - Properties

    public let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.allowsEdgeAntialiasing = true
        return imageView
    }()

    public func setWebImage(url: URL?) {
        imageView.kf.setImage(with: url, completionHandler: { [weak self] result in
            switch result {
            case .success:
                self?.onSuccessLoadImage()
            case .failure:
                self?.showErrorMsg(err: ErrorMsg(errorDescription: "Cannot load remote resource.\nTap to dismiss."))
            }
        })
    }

    public func showErrorMsg(err: Error) {
        if let errL = errorLabel {
            errL.text = err.localizedDescription
            return
        }

        let label = UILabel()
        label.text = err.localizedDescription
        label.textColor = .secondaryLabel
        label.font = UIFont.systemFont(ofSize: 17)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -50)
        ])

        errorLabel = label
    }

    public func addDragToDismissGesture() {
        dragToDismissGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDragToDismiss(_:)))
        dragToDismissGesture.delegate = self
        addGestureRecognizer(dragToDismissGesture)
    }

    func onSuccessLoadImage(maximumZoomScale: CGFloat = 5) {
        self.maximumZoomScale = maximumZoomScale

        addGestureRecognizer(doubleTapGesture)

        updateImageView()
        scrollToCenter()
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

    open func setup() {
        contentInsetAdjustmentBehavior = .never

        delegate = self
        imageView.contentMode = .scaleAspectFill
        addSubview(imageView)

        doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
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
        imageView.center = ZoomableImageView.contentCenter(forBoundingSize: bounds.size, contentSize: contentSize)
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
        imageView.center = ZoomableImageView.contentCenter(forBoundingSize: bounds.size, contentSize: contentSize)
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

    // MARK: drag to dismiss
    private var parentBackgroundColor: UIColor = .black

    private var originalSize: CGSize = .zero
    private var originalCenter: CGPoint = .zero
    private var initialTouchLocation: CGPoint = .zero

    @objc private func handleDragToDismiss(_ gesture: UIPanGestureRecognizer) {
        guard let vc = findViewController() else { return }

        let translation = gesture.translation(in: self.superview)
        let distance = sqrt(translation.x * translation.x + translation.y * translation.y)

        let maxDistance: CGFloat = 200
        let scale = max(0.5, 1 - distance / (maxDistance * 2))
        let alpha = max(0.1, parentBackgroundColor.cgColor.alpha - distance / maxDistance)

        let velocity = gesture.velocity(in: self.superview)
        let speed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
        let velocityThreshold: CGFloat = 1000

        let touchLocation = gesture.location(in: self.superview)

        switch gesture.state {
        case .began:
            originalSize = self.bounds.size
            originalCenter = self.center
            initialTouchLocation = gesture.location(in: self)

            parentBackgroundColor = vc.view.backgroundColor ?? .black
        case .changed:
            vc.view.backgroundColor = parentBackgroundColor.withAlphaComponent(alpha)

            self.transform = CGAffineTransform(scaleX: scale, y: scale)

            let scaledTouchLocation = CGPoint(
                x: initialTouchLocation.x * scale,
                y: initialTouchLocation.y * scale
            )
            self.center = CGPoint(
                x: touchLocation.x - scaledTouchLocation.x + (self.bounds.width * scale) / 2,
                y: touchLocation.y - scaledTouchLocation.y + (self.bounds.height * scale) / 2
            )
        case .ended, .cancelled:
            if distance > maxDistance {
                vc.dismiss(animated: true)
            } else if speed > velocityThreshold {
                let newX = min(translation.x + velocity.x * 0.1, sqrt(20000))
                let newY = min(translation.y + velocity.y * 0.1, sqrt(20000))
                let newDistance = sqrt(newX * newX + newY * newY)
                let newScale = max(0.5, 1 - newDistance  / (newDistance * 2))
                let newAlpha = max(0.1, parentBackgroundColor.cgColor.alpha - newDistance / maxDistance)

                UIView.animate(withDuration: 0.20, delay: 0, options: .curveEaseOut) {
                    self.transform = CGAffineTransform(translationX: newX, y: newY)
                        .scaledBy(x: newScale, y: newScale)
                    vc.view.backgroundColor = self.parentBackgroundColor.withAlphaComponent(newAlpha)
                } completion: { _ in
                    vc.dismiss(animated: true)
                }
            } else {
                UIView.animate(withDuration: 0.25) {
                    self.transform = .identity
                    self.center = self.originalCenter
                    vc.view.backgroundColor = self.parentBackgroundColor
                }
            }
        default:
            break
        }
    }

    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if let vc = responder as? UIViewController { return vc }
            responder = responder?.next
        }
        return nil
    }
}

extension ZoomableImageView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == dragToDismissGesture {
            return zoomScale == 1
        }
        return true
    }
}
