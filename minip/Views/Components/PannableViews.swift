//
//  PannableViews.swift
//  minip
//
//  Created by LZY on 2025/1/31.
//

import Defaults
import UIKit

// MARK: - Shared edge-pan dismiss logic

private func handleEdgePan(
    _ panGesture: UIScreenEdgePanGestureRecognizer,
    view: UIView,
    transitionDelegate: SheetTransitionDelegate,
    dismisser: UIViewController
) {
    let translation = panGesture.translation(in: view)
    let progress = CGFloat(fminf(fmaxf(Float(translation.x / view.bounds.width), 0.0), 1.0))
    let velocity = panGesture.velocity(in: view)
    let shouldFinish = progress > 0.5 || velocity.x >= 800

    switch panGesture.state {
    case .began:
        transitionDelegate.interactiveTransition.hasStarted = true
        dismisser.dismiss(animated: true)
    case .changed:
        transitionDelegate.interactiveTransition.shouldFinish = shouldFinish
        transitionDelegate.interactiveTransition.update(progress)
    case .cancelled:
        transitionDelegate.interactiveTransition.hasStarted = false
        transitionDelegate.interactiveTransition.cancel()
    case .ended:
        transitionDelegate.interactiveTransition.hasStarted = false
        let shouldFinishNow = shouldFinish && velocity.x >= 0
        let duration = CGFloat(transitionDelegate.transition.duration)
        if shouldFinishNow {
            let speed = (1.0 - progress) * duration / 0.3
            transitionDelegate.interactiveTransition.completionSpeed = max(0.05, speed)
            transitionDelegate.interactiveTransition.finish()
        } else {
            let remainingDistance = progress * view.bounds.width
            let velocityDuration = remainingDistance / max(abs(velocity.x), 1)
            let targetDuration = CGFloat(max(0.1, min(0.3, velocityDuration)))
            let speed = progress * duration / targetDuration
            transitionDelegate.interactiveTransition.completionSpeed = max(0.05, speed)
            transitionDelegate.interactiveTransition.cancel()
        }
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

class SheetInteractiveTransition: UIPercentDrivenInteractiveTransition {
    public var hasStarted: Bool = false
    public var shouldFinish: Bool = false
}

class SheetTransition {
    public var isPresenting: Bool = false
    public var duration: TimeInterval = 0.5
}

class SheetTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    lazy var transition: SheetTransition = .init()
    lazy var interactiveTransition: SheetInteractiveTransition = .init()
    var currentAnimator: UIViewPropertyAnimator?

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        self.transition.isPresenting = true
        // use default present animation
        return nil
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.transition.isPresenting = false
        return self
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.interactiveTransition.hasStarted ? self.interactiveTransition : nil
    }
}

extension SheetTransitionDelegate: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.transition.duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        interruptibleAnimator(using: transitionContext).startAnimation()
    }

    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        if let animator = currentAnimator {
            return animator
        }

        let fromVC = transitionContext.viewController(forKey: .from)!
        let toVC = transitionContext.viewController(forKey: .to)!
        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)

        let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1.0)

        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)

        let dimmingView = UIView(frame: containerView.bounds)
        dimmingView.backgroundColor = .black
        dimmingView.alpha = 0.1
        containerView.insertSubview(dimmingView, belowSubview: fromVC.view)

        let fromFinalFrame = fromVC.view.frame.offsetBy(dx: 0, dy: fromVC.view.frame.height)

        animator.addAnimations {
            fromVC.view.frame = fromFinalFrame
            dimmingView.alpha = 0
        }
        animator.addCompletion { [weak self] _ in
            dimmingView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            self?.currentAnimator = nil
        }

        currentAnimator = animator
        return animator
    }
}
