//
//  PannableViews.swift
//  minip
//
//  Created by LZY on 2025/1/31.
//

import UIKit

// MARK: - Shared edge-pan dismiss logic

private func handleEdgePan(
    _ panGesture: UIScreenEdgePanGestureRecognizer,
    view: UIView,
    transitionDelegate: SheetTransitionDelegate,
    dismisser: UIViewController
) {
    let tx = panGesture.translation(in: view).x
    let width = view.bounds.width
    guard width > 0 else { return }
    let gestureProgress = CGFloat(fminf(fmaxf(Float(tx / width), 0.0), 1.0))
    let vx = panGesture.velocity(in: view).x

    switch panGesture.state {
    case .began:
        if let animator = transitionDelegate.dismissAnimator, animator.state == .active {
            animator.pauseAnimation()
            transitionDelegate.panStartFraction = animator.fractionComplete
            if animator.isReversed {
                transitionDelegate.panStartFraction = 1 - transitionDelegate.panStartFraction
                animator.isReversed = false
            }
        } else {
            transitionDelegate.panStartFraction = 0
            transitionDelegate.wantsInteractive = true
            dismisser.dismiss(animated: true)
            transitionDelegate.dismissAnimator?.pauseAnimation()
        }

    case .changed:
        let fraction = min(1, max(0, transitionDelegate.panStartFraction + gestureProgress))
        transitionDelegate.dismissAnimator?.fractionComplete = fraction

    case .ended, .cancelled:
        guard let animator = transitionDelegate.dismissAnimator else { return }
        let currentFraction = animator.fractionComplete
        let shouldFinish = panGesture.state == .ended && (currentFraction > 0.5 || vx >= 800) && vx >= 0

        animator.isReversed = !shouldFinish

        let remainingFraction = shouldFinish ? (1 - currentFraction) : currentFraction
        let velocitySpeed = abs(vx) / width
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

// MARK: - PannableNavigationViewController

class PannableNavigationViewController: UINavigationController, UIGestureRecognizerDelegate {
    private lazy var transitionDelegate: SheetTransitionDelegate = .init()

    private var orientations: UIInterfaceOrientationMask? = nil

    private var _moreButton: UIButton? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.transitioningDelegate = self.transitionDelegate

        let panGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(self.onPan(_:)))
        panGesture.edges = .left
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
    }

    @objc func onPan(_ panGesture: UIScreenEdgePanGestureRecognizer) {
        handleEdgePan(panGesture, view: view, transitionDelegate: transitionDelegate, dismisser: self)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count <= 1
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init(rootViewController: UIViewController, orientations: UIInterfaceOrientationMask? = nil) {
        self.orientations = orientations
        super.init(rootViewController: rootViewController)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.orientations ?? .all
    }

    deinit {
        // TODO: clear twice when click close button
        // logger.info("[PannableNavigationViewController] clear open app info & reset orientation")
        if MiniAppManager.shared.openedApp?.orientation == "landscape" {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
        }
        MiniAppManager.shared.clearOpenedApp()
    }
}

// MARK: - PannableTabBarController

class PannableTabBarController: UITabBarController, UIGestureRecognizerDelegate {
    private lazy var transitionDelegate: SheetTransitionDelegate = .init()

    private var orientations: UIInterfaceOrientationMask? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.transitioningDelegate = self.transitionDelegate

        let panGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(self.onPan(_:)))
        panGesture.edges = .left
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
    }

    @objc func onPan(_ panGesture: UIScreenEdgePanGestureRecognizer) {
        handleEdgePan(panGesture, view: view, transitionDelegate: transitionDelegate, dismisser: self)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let nav = selectedViewController as? UINavigationController {
            return nav.viewControllers.count <= 1
        }
        return true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init(orientations: UIInterfaceOrientationMask? = nil) {
        self.orientations = orientations
        super.init(nibName: nil, bundle: nil)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.orientations ?? .all
    }

    deinit {
        // TODO: clear twice when click close button
        // logger.info("[PannableNavigationViewController] clear open app info & reset orientation")
        if MiniAppManager.shared.openedApp?.orientation == "landscape" {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
        }
        MiniAppManager.shared.clearOpenedApp()
    }
}

// MARK: - Transition

class SheetTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    var wantsInteractive = false
    var dismissAnimator: UIViewPropertyAnimator?
    var panStartFraction: CGFloat = 0

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        // use default present animation
        return nil
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        wantsInteractive ? self : nil
    }
}

extension SheetTransitionDelegate: UIViewControllerInteractiveTransitioning {
    var wantsInteractiveStart: Bool { true }

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        let animator = makeDismissAnimator(using: transitionContext)
        dismissAnimator = animator
    }
}

extension SheetTransitionDelegate: UIViewControllerAnimatedTransitioning {
    private static let dimmingAlpha: CGFloat = 0.1

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { 0.5 }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // Non-interactive dismiss
        let animator = makeDismissAnimator(using: transitionContext)
        dismissAnimator = animator
        animator.startAnimation()
    }

    private func makeDismissAnimator(using ctx: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator {
        let fromVC = ctx.viewController(forKey: .from)!
        let toVC = ctx.viewController(forKey: .to)!
        let container = ctx.containerView

        container.insertSubview(toVC.view, belowSubview: fromVC.view)

        let dim = UIView(frame: container.bounds)
        dim.backgroundColor = .black
        dim.alpha = Self.dimmingAlpha
        container.insertSubview(dim, belowSubview: fromVC.view)

        let fromFinalFrame = fromVC.view.frame.offsetBy(dx: 0, dy: fromVC.view.frame.height)

        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1.0)
        animator.addAnimations {
            fromVC.view.frame = fromFinalFrame
            dim.alpha = 0
        }
        animator.addCompletion { [weak self] position in
            let completed = (position == .end)
            dim.removeFromSuperview()
            if !completed {
                // Cancelled — restore
            }
            ctx.completeTransition(completed)
            self?.dismissAnimator = nil
            self?.wantsInteractive = false
        }
        return animator
    }
}
