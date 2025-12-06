//
//  ZoomableImageView.swift
//  minip
//
//  Created by LZY on 2025/3/19.
//

import UIKit

class ZoomableImageView: UIView {
    var tapHandler: (() -> Void)?
    var panGestureChangedHandler: ((_ scale: CGFloat) -> Void)?
    var panGestureReleasedHandler: ((_ downSwipe: Bool) -> Void)?
    var longPressedHandler: ((_ gesture: UILongPressGestureRecognizer) -> Void)?

    var imageView = UIImageView()
    var scrollView = UIScrollView()

    var errorLabel: UILabel?

    lazy var parentVC: UIViewController? = nil
    var parentBackground: UIColor = .clear

    private var beganFrame: CGRect = .zero
    private var beganTouch: CGPoint = .zero

    public init(disablePanGesture: Bool) {
        super.init(frame: .zero)
        setup(disablePanGesture: disablePanGesture)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    func setup(disablePanGesture: Bool = false) {
        addSubview(scrollView)
        scrollView.addSubview(imageView)

        scrollView.delegate = self
        scrollView.maximumZoomScale = 5.0
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.contentInsetAdjustmentBehavior = .never

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
        addGestureRecognizer(longPressGesture)

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapGesture(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        addGestureRecognizer(tapGesture)
        tapGesture.require(toFail: doubleTapGesture)

        if !disablePanGesture {
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
            panGesture.delegate = self
            scrollView.addGestureRecognizer(panGesture)
        }
    }

    func onSuccessLoadImage() {
        layoutSubviews()
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        scrollView.frame = bounds
        scrollView.setZoomScale(1.0, animated: false)
        imageView.frame = fitFrame
        scrollView.setZoomScale(1.0, animated: false)
    }

    private var fitSize: CGSize {
        guard let imageSize = imageView.image?.size else { return bounds.size }
        var width: CGFloat
        var height: CGFloat
        if scrollView.bounds.width < scrollView.bounds.height {
            width = scrollView.bounds.width
            height = (imageSize.height / imageSize.width) * width
        } else {
            height = scrollView.bounds.height
            width = (imageSize.width / imageSize.height) * height
            if width > scrollView.bounds.width {
                width = scrollView.bounds.width
                height = (imageSize.height / imageSize.width) * width
            }
        }
        return CGSize(width: width, height: height)
    }

    private var resettingCenter: CGPoint {
        let deltaWidth = bounds.width - scrollView.contentSize.width
        let offsetX = deltaWidth > 0 ? deltaWidth * 0.5 : 0
        let deltaHeight = bounds.height - scrollView.contentSize.height
        let offsetY = deltaHeight > 0 ? deltaHeight * 0.5 : 0
        return CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX,
                       y: scrollView.contentSize.height * 0.5 + offsetY)
    }

    private var fitFrame: CGRect {
        let size = fitSize
        let y = scrollView.bounds.height > size.height
            ? (scrollView.bounds.height - size.height) * 0.5 : 0
        let x = scrollView.bounds.width > size.width
            ? (scrollView.bounds.width - size.width) * 0.5 : 0
        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }

    private func panResult(_ pan: UIPanGestureRecognizer) -> PanGestureResult {
        let translation = pan.translation(in: scrollView)
        let currentTouch = pan.location(in: scrollView)

        let scale = min(1.0, max(0.3, 1 - translation.y / bounds.height))

        let width = beganFrame.size.width * scale
        let height = beganFrame.size.height * scale

        let xRate = (beganTouch.x - beganFrame.origin.x) / beganFrame.size.width
        let currentTouchDeltaX = xRate * width
        let x = currentTouch.x - currentTouchDeltaX

        let yRate = (beganTouch.y - beganFrame.origin.y) / beganFrame.size.height
        let currentTouchDeltaY = yRate * height
        let y = currentTouch.y - currentTouchDeltaY

        return PanGestureResult(frame: CGRect(x: x.isNaN ? 0 : x, y: y.isNaN ? 0 : y, width: width, height: height), scale: scale)
    }

    private func resetImageView() {
        let size = fitSize
        let needResetSize = imageView.bounds.size.width < size.width
            || imageView.bounds.size.height < size.height
        UIView.animate(withDuration: 0.25) {
            self.imageView.center = self.resettingCenter
            if needResetSize {
                self.imageView.bounds.size = size
            }
            if let vc = self.parentVC {
                vc.view.backgroundColor = self.parentBackground
            }
        }
    }
}

extension ZoomableImageView {
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        tapHandler?()
    }

    @objc private func handleDoubleTapGesture(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale == 1.0 {
            let pointInView = gesture.location(in: imageView)
            let width = scrollView.bounds.size.width / min(scrollView.maximumZoomScale, 2.0)
            let height = scrollView.bounds.size.height / min(scrollView.maximumZoomScale, 2.0)
            let x = pointInView.x - (width / 2.0)
            let y = pointInView.y - (height / 2.0)
            scrollView.zoom(to: CGRect(x: x, y: y, width: width, height: height), animated: true)
        } else {
            scrollView.setZoomScale(1.0, animated: true)
        }
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            beganFrame = imageView.frame
            beganTouch = gesture.location(in: scrollView)
        case .changed:
            let result = panResult(gesture)
            imageView.frame = result.frame
            panGestureChangedHandler?(result.scale)
            let alpha = max(0.1, parentBackground.cgColor.alpha - (1 - result.scale) / 0.6)
            parentVC?.view.backgroundColor = parentBackground.withAlphaComponent(alpha)
        case .ended, .cancelled:
            let result = panResult(gesture)
            imageView.frame = result.frame
            let isDownSwipe = gesture.velocity(in: self).y > 0
            if isDownSwipe && result.scale <= 0.8 {
                panGestureReleasedHandler?(isDownSwipe)
            } else {
                resetImageView()
            }
        default:
            resetImageView()
        }
    }

    @objc private func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            longPressedHandler?(gesture)
        }
    }
}

extension ZoomableImageView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        imageView.center = resettingCenter
    }
}

extension ZoomableImageView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        let velocity = pan.velocity(in: self)
        if velocity.y < 0 {
            return false
        }
        if abs(Int(velocity.x)) > Int(velocity.y) {
            return false
        }
        if scrollView.contentOffset.y > 0 {
            return false
        }
        return true
    }
}

fileprivate struct PanGestureResult {
    var frame: CGRect
    var scale: CGFloat
}
