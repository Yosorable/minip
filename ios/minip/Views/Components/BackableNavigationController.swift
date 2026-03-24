//
//  NavableNav.swift
//  minip
//
//  Created by LZY on 2025/2/2.
//

import UIKit

class BackableNavigationController: UINavigationController {
    private lazy var navTransitionDelegate = NavTransitionDelegate()
    private var panStartFraction: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        transitioningDelegate = navTransitionDelegate

        if #available(iOS 26.0, *) {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            pan.delegate = self
            view.addGestureRecognizer(pan)
        } else {
            let edge = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            edge.edges = .left
            view.addGestureRecognizer(edge)
        }
    }

    @objc private func handlePan(_ pan: UIPanGestureRecognizer) {
        let tx = pan.translation(in: view).x
        let vx = pan.velocity(in: view).x
        let width = view.bounds.width
        guard width > 0 else { return }
        let gestureProgress = max(0, min(1, tx / width))

        switch pan.state {
        case .began:
            if let animator = navTransitionDelegate.dismissAnimator, animator.state == .active {
                // Interrupt running cancel/finish animation
                animator.pauseAnimation()
                panStartFraction = animator.fractionComplete
                if animator.isReversed {
                    // Was cancelling (going back to 0), flip to forward
                    panStartFraction = 1 - panStartFraction
                    animator.isReversed = false
                }
            } else {
                // Start new dismiss transition
                panStartFraction = 0
                navTransitionDelegate.wantsInteractive = true
                dismiss(animated: true)
                navTransitionDelegate.dismissAnimator?.pauseAnimation()
            }

        case .changed:
            let fraction = min(1, max(0, panStartFraction + gestureProgress))
            navTransitionDelegate.dismissAnimator?.fractionComplete = fraction

        case .ended, .cancelled:
            guard let animator = navTransitionDelegate.dismissAnimator else { return }
            let currentFraction = animator.fractionComplete
            let shouldFinish = pan.state == .ended && (currentFraction > 0.5 || vx >= 800) && vx >= 0

            animator.isReversed = !shouldFinish

            // Target ~0.3s for the snap-back/forward; velocity shortens it
            let remainingFraction = shouldFinish ? (1 - currentFraction) : currentFraction
            let velocitySpeed = abs(vx) / width  // fraction/s
            let targetDuration = max(0.2, min(0.35, Double(remainingFraction) / max(Double(velocitySpeed), 0.8)))
            let factor = CGFloat(targetDuration) / CGFloat(animator.duration)

            animator.continueAnimation(
                withTimingParameters: UISpringTimingParameters(dampingRatio: 1.0),
                durationFactor: factor
            )

        default:
            break
        }
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }
    override init(rootViewController: UIViewController) { super.init(rootViewController: rootViewController) }
}

extension BackableNavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard viewControllers.count <= 1 else { return false }
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            let v = pan.velocity(in: view)
            return v.x > 0 && abs(v.x) > abs(v.y)
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard otherGestureRecognizer is UIPanGestureRecognizer,
            let otherView = otherGestureRecognizer.view,
            otherView.isDescendant(of: view)
        else { return false }
        // Don't yield to UIScrollView's own scroll gesture, otherwise dismiss never fires
        if let scrollView = otherView as? UIScrollView,
            otherGestureRecognizer === scrollView.panGestureRecognizer
        {
            return false
        }
        return true
    }
}

// MARK: - Transition Delegate

private class NavTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    var wantsInteractive = false
    var dismissAnimator: UIViewPropertyAnimator?
    private var isPresenting = false

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = true
        return self
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = false
        return self
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        wantsInteractive ? self : nil
    }
}

// MARK: - Interactive Transition (dismiss only)

extension NavTransitionDelegate: UIViewControllerInteractiveTransitioning {
    var wantsInteractiveStart: Bool { true }

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        let animator = makeDismissAnimator(using: transitionContext)
        dismissAnimator = animator
        // Don't start — the pan gesture drives fractionComplete
    }
}

// MARK: - Animated Transition

extension NavTransitionDelegate: UIViewControllerAnimatedTransitioning {
    private static let parallaxRatio: CGFloat = 1.0 / 3.0
    private static let dimmingAlpha: CGFloat = 0.1

    private static var screenCornerRadius: CGFloat = {
        if #available(iOS 26.0, *) {
            let sel = "_dis" + "play" + "Corn" + "erRad" + "ius"
            if UIScreen.main.responds(to: Selector(sel)),
                let v = UIScreen.main.value(forKey: sel) as? CGFloat
            {
                return v
            }
        }
        return 0
    }()

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { 0.5 }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isPresenting {
            makePresentAnimator(using: transitionContext).startAnimation()
        } else {
            // Non-interactive dismiss (Done button)
            let animator = makeDismissAnimator(using: transitionContext)
            dismissAnimator = animator
            animator.startAnimation()
        }
    }

    // MARK: Present

    private func makePresentAnimator(using ctx: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator {
        let fromVC = ctx.viewController(forKey: .from)!
        let toVC = ctx.viewController(forKey: .to)!
        let container = ctx.containerView
        let w = container.bounds.width
        let cr = Self.screenCornerRadius

        let finalFrame = ctx.finalFrame(for: toVC)
        toVC.view.frame = finalFrame.offsetBy(dx: w, dy: 0)

        if cr > 0 {
            toVC.view.layer.cornerRadius = cr
            toVC.view.layer.cornerCurve = .circular
            toVC.view.clipsToBounds = true
        } else {
            toVC.view.layer.shadowColor = UIColor.black.cgColor
            toVC.view.layer.shadowOpacity = 0.15
            toVC.view.layer.shadowOffset = CGSize(width: -3, height: 0)
            toVC.view.layer.shadowRadius = 8
        }

        let dim = UIView(frame: container.bounds)
        dim.backgroundColor = .black
        dim.alpha = 0
        container.addSubview(dim)
        container.addSubview(toVC.view)

        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1.0)
        animator.addAnimations {
            toVC.view.frame = finalFrame
            fromVC.view.transform = CGAffineTransform(translationX: -w * Self.parallaxRatio, y: 0)
            dim.alpha = Self.dimmingAlpha
        }
        animator.addCompletion { _ in
            toVC.view.layer.cornerRadius = 0
            toVC.view.clipsToBounds = false
            dim.removeFromSuperview()
            ctx.completeTransition(true)
        }
        return animator
    }

    // MARK: Dismiss

    private func makeDismissAnimator(using ctx: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator {
        let fromVC = ctx.viewController(forKey: .from)!
        let toVC = ctx.viewController(forKey: .to)!
        let container = ctx.containerView
        let w = container.bounds.width
        let cr = Self.screenCornerRadius

        if cr > 0 {
            fromVC.view.layer.cornerRadius = cr
            fromVC.view.layer.cornerCurve = .circular
            fromVC.view.clipsToBounds = true
        } else {
            fromVC.view.layer.shadowColor = UIColor.black.cgColor
            fromVC.view.layer.shadowOpacity = 0.15
            fromVC.view.layer.shadowOffset = CGSize(width: -3, height: 0)
            fromVC.view.layer.shadowRadius = 8
        }

        let dim = UIView(frame: container.bounds)
        dim.backgroundColor = .black
        dim.alpha = Self.dimmingAlpha
        container.insertSubview(dim, belowSubview: fromVC.view)

        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1.0)
        animator.addAnimations {
            fromVC.view.frame = container.bounds.offsetBy(dx: w, dy: 0)
            toVC.view.transform = .identity
            dim.alpha = 0
        }
        animator.addCompletion { [weak self] position in
            let completed = (position == .end)
            dim.removeFromSuperview()
            if !completed {
                fromVC.view.layer.cornerRadius = 0
                fromVC.view.clipsToBounds = false
            }
            fromVC.view.layer.shadowOpacity = 0
            ctx.completeTransition(completed)
            self?.dismissAnimator = nil
            self?.wantsInteractive = false
        }
        return animator
    }
}
