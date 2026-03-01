//
//  ImagePreviewTransition.swift
//  minip
//

import UIKit

// MARK: - Transition Delegate

class ImagePreviewTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    let sourceRect: CGRect
    let thumbnailImage: UIImage?

    init(sourceRect: CGRect, thumbnailImage: UIImage?) {
        self.sourceRect = sourceRect
        self.thumbnailImage = thumbnailImage
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        ImagePreviewPresentAnimator(sourceRect: sourceRect, thumbnailImage: thumbnailImage)
    }

    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        guard let vc = dismissed as? ImagePreviewViewController else { return nil }
        return ImagePreviewDismissAnimator(sourceRect: sourceRect, imagePreviewVC: vc)
    }
}

// MARK: - Present Animator

class ImagePreviewPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let sourceRect: CGRect
    let thumbnailImage: UIImage?

    init(sourceRect: CGRect, thumbnailImage: UIImage?) {
        self.sourceRect = sourceRect
        self.thumbnailImage = thumbnailImage
    }

    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        0.4
    }

    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) as? ImagePreviewViewController else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        toVC.view.frame = transitionContext.finalFrame(for: toVC)
        containerView.addSubview(toVC.view)
        toVC.view.layoutIfNeeded()

        guard let image = thumbnailImage else {
            // Fallback: fade in
            toVC.view.alpha = 0
            UIView.animate(withDuration: 0.25) {
                toVC.view.alpha = 1
            } completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
            return
        }

        let targetBgColor = toVC.view.backgroundColor ?? .black
        toVC.view.backgroundColor = .clear
        toVC.zoomableImageView.isHidden = true

        let snapshotView = UIImageView(image: image)
        snapshotView.contentMode = .scaleAspectFill
        snapshotView.clipsToBounds = true
        snapshotView.frame = sourceRect
        containerView.addSubview(snapshotView)

        // Snapshot now covers the source img position
        toVC.onPresentSnapshotReady?()

        let targetFrame = Self.targetFrame(for: image.size, in: toVC.view.bounds)

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0,
            options: .curveEaseInOut
        ) {
            snapshotView.frame = targetFrame
            toVC.view.backgroundColor = targetBgColor
        } completion: { _ in
            toVC.zoomableImageView.isHidden = false
            snapshotView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }

    static func targetFrame(for imageSize: CGSize, in bounds: CGRect) -> CGRect {
        //        var width: CGFloat
        //        var height: CGFloat
        //        if bounds.width < bounds.height {
        //            width = bounds.width
        //            height = (imageSize.height / imageSize.width) * width
        //        } else {
        //            height = bounds.height
        //            width = (imageSize.width / imageSize.height) * height
        //            if width > bounds.width {
        //                width = bounds.width
        //                height = (imageSize.height / imageSize.width) * width
        //            }
        //        }
        //        let y = bounds.height > height ? (bounds.height - height) * 0.5 : 0
        //        let x = bounds.width > width ? (bounds.width - width) * 0.5 : 0
        //        return CGRect(x: x, y: y, width: width, height: height)

        let ratio = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let width = imageSize.width * ratio
        let height = imageSize.height * ratio
        let x = (bounds.width - width) * 0.5
        let y = (bounds.height - height) * 0.5
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

// MARK: - Dismiss Animator

class ImagePreviewDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let sourceRect: CGRect
    weak var imagePreviewVC: ImagePreviewViewController?

    init(sourceRect: CGRect, imagePreviewVC: ImagePreviewViewController) {
        self.sourceRect = sourceRect
        self.imagePreviewVC = imagePreviewVC
    }

    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        0.35
    }

    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as? ImagePreviewViewController else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        let imageView = fromVC.zoomableImageView.imageView

        guard imageView.image != nil else {
            fadeOut(fromVC: fromVC, transitionContext: transitionContext)
            return
        }

        let currentFrame = imageView.convert(imageView.bounds, to: containerView)

        let snapshotView = UIImageView(image: imageView.image)
        snapshotView.contentMode = .scaleAspectFill
        snapshotView.clipsToBounds = true
        snapshotView.frame = currentFrame
        containerView.addSubview(snapshotView)

        fromVC.zoomableImageView.isHidden = true

        // Fetch real-time source rect from JS, then animate
        if let fetchRect = fromVC.fetchSourceRect {
            fetchRect { [weak self] newRect in
                guard let self else {
                    transitionContext.completeTransition(false)
                    return
                }
                if let newRect {
                    self.zoomOut(snapshotView: snapshotView, to: newRect, fromVC: fromVC, transitionContext: transitionContext)
                } else {
                    snapshotView.removeFromSuperview()
                    fromVC.zoomableImageView.isHidden = false
                    self.fadeOut(fromVC: fromVC, transitionContext: transitionContext)
                }
            }
        } else {
            zoomOut(snapshotView: snapshotView, to: sourceRect, fromVC: fromVC, transitionContext: transitionContext)
        }
    }

    private func zoomOut(snapshotView: UIImageView, to targetRect: CGRect, fromVC: ImagePreviewViewController, transitionContext: any UIViewControllerContextTransitioning) {
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0,
            options: .curveEaseInOut
        ) {
            snapshotView.frame = targetRect
            fromVC.view.backgroundColor = .clear
        } completion: { _ in
            fromVC.onDismiss?()
            fromVC.onDismiss = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                snapshotView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }

    private func fadeOut(fromVC: ImagePreviewViewController, transitionContext: any UIViewControllerContextTransitioning) {
        UIView.animate(withDuration: 0.25) {
            fromVC.view.alpha = 0
        } completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
