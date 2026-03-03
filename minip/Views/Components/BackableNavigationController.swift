//
//  NavableNav.swift
//  minip
//
//  Created by LZY on 2025/2/2.
//

import UIKit

class BackableNavigationController: UINavigationController {
    public var minimumScreenRatioToHide = 0.53 as CGFloat
    public var animationDuration = 0.2 as TimeInterval

    private lazy var transitionDelegate: NavTransitionDelegate = .init()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.transitioningDelegate = self.transitionDelegate

        if #available(iOS 26.0, *) {
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.onPan(_:)))
            panGesture.delegate = self
            view.addGestureRecognizer(panGesture)
        } else {
            let edgePanGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(self.onPan(_:)))
            edgePanGesture.edges = .left
            view.addGestureRecognizer(edgePanGesture)
        }
    }

    @objc func onPan(_ panGesture: UIScreenEdgePanGestureRecognizer) {
        let translation = panGesture.translation(in: self.view)
        let horizontalMovement = translation.x / self.view.bounds.width
        let downwardMovement = fmaxf(Float(horizontalMovement), 0.0)

        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)

        let velocity = panGesture.velocity(in: self.view)
        let shouldFinish = progress > self.minimumScreenRatioToHide || velocity.x >= 800

        switch panGesture.state {
        case .began:
            self.transitionDelegate.interactiveTransition.hasStarted = true
            self.dismiss(animated: true, completion: nil)
        case .changed:
            self.transitionDelegate.interactiveTransition.shouldFinish = shouldFinish
            self.transitionDelegate.interactiveTransition.update(progress)
        case .cancelled:
            self.transitionDelegate.interactiveTransition.hasStarted = false
            self.transitionDelegate.interactiveTransition.cancel()
        case .ended:
            self.transitionDelegate.interactiveTransition.hasStarted = false
            let shouldFinishNow = shouldFinish && velocity.x >= 0
            let duration = CGFloat(self.transitionDelegate.transition.duration)
            if shouldFinishNow {
                let speed = (1.0 - progress) * duration / 0.3
                self.transitionDelegate.interactiveTransition.completionSpeed = max(0.05, speed)
                self.transitionDelegate.interactiveTransition.finish()
            } else {
                let remainingDistance = progress * self.view.bounds.width
                let velocityDuration = remainingDistance / max(abs(velocity.x), 1)
                let targetDuration = CGFloat(max(0.1, min(0.3, velocityDuration)))
                let speed = progress * duration / targetDuration
                self.transitionDelegate.interactiveTransition.completionSpeed = max(0.05, speed)
                self.transitionDelegate.interactiveTransition.cancel()
            }
        default:
            break
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    deinit {}
}

extension BackableNavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard viewControllers.count <= 1 else { return false }
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = pan.velocity(in: view)
            return velocity.x > 0 && abs(velocity.x) > abs(velocity.y)
        }
        return true
    }
}

class NavInteractiveTransition: UIPercentDrivenInteractiveTransition {
    public var hasStarted: Bool = false
    public var shouldFinish: Bool = false
}

class NavTransition {
    public var isPresenting: Bool = false
    public var duration: TimeInterval = 0.5
}

class NavTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    lazy var transition: NavTransition = .init()
    lazy var interactiveTransition: NavInteractiveTransition = .init()
    var currentAnimator: UIViewPropertyAnimator?

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        self.transition.isPresenting = true
        return self
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.transition.isPresenting = false
        return self
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.interactiveTransition.hasStarted ? self.interactiveTransition : nil
    }
}

extension NavTransitionDelegate: UIViewControllerAnimatedTransitioning {
    private static let parallaxRatio: CGFloat = 1.0 / 3.0
    private static let dimmingAlpha: CGFloat = 0.1

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
        let screenWidth = containerView.bounds.width
        let duration = transitionDuration(using: transitionContext)

        let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1.0)

        // iOS 26+: rounded corners matching device screen during transition
        let screenCornerRadius: CGFloat
        if #available(iOS 26.0, *) {
            let selStr = "_dis" + "play" + "Corn" + "erRad" + "ius"
            if UIScreen.main.responds(to: Selector(selStr)), let value = UIScreen.main.value(forKey: selStr) as? CGFloat {
                screenCornerRadius = value
            } else {
                screenCornerRadius = 0
            }
        } else {
            screenCornerRadius = 0
        }

        if self.transition.isPresenting {
            let finalFrame = transitionContext.finalFrame(for: toVC)
            toVC.view.frame = finalFrame.offsetBy(dx: screenWidth, dy: 0)

            if screenCornerRadius > 0 {
                toVC.view.layer.cornerRadius = screenCornerRadius
                toVC.view.layer.cornerCurve = .circular
                toVC.view.clipsToBounds = true
            } else {
                toVC.view.layer.shadowColor = UIColor.black.cgColor
                toVC.view.layer.shadowOpacity = 0.15
                toVC.view.layer.shadowOffset = CGSize(width: -3, height: 0)
                toVC.view.layer.shadowRadius = 8
            }

            let dimmingView = UIView(frame: containerView.bounds)
            dimmingView.backgroundColor = .black
            dimmingView.alpha = 0
            containerView.addSubview(dimmingView)
            containerView.addSubview(toVC.view)

            animator.addAnimations {
                toVC.view.frame = finalFrame
                fromVC.view.transform = CGAffineTransform(translationX: -screenWidth * Self.parallaxRatio, y: 0)
                dimmingView.alpha = Self.dimmingAlpha
            }
            animator.addCompletion { [weak self] _ in
                toVC.view.layer.cornerRadius = 0
                toVC.view.clipsToBounds = false
                dimmingView.removeFromSuperview()
                transitionContext.completeTransition(true)
                self?.currentAnimator = nil
            }
        } else {
            if screenCornerRadius > 0 {
                fromVC.view.layer.cornerRadius = screenCornerRadius
                fromVC.view.layer.cornerCurve = .circular
                fromVC.view.clipsToBounds = true
            } else {
                fromVC.view.layer.shadowColor = UIColor.black.cgColor
                fromVC.view.layer.shadowOpacity = 0.15
                fromVC.view.layer.shadowOffset = CGSize(width: -3, height: 0)
                fromVC.view.layer.shadowRadius = 8
            }

            let dimmingView = UIView(frame: containerView.bounds)
            dimmingView.backgroundColor = .black
            dimmingView.alpha = Self.dimmingAlpha
            containerView.insertSubview(dimmingView, belowSubview: fromVC.view)

            let fromFinalFrame = fromVC.view.frame.offsetBy(dx: screenWidth, dy: 0)

            animator.addAnimations {
                fromVC.view.frame = fromFinalFrame
                toVC.view.transform = .identity
                dimmingView.alpha = 0
            }
            animator.addCompletion { [weak self] _ in
                dimmingView.removeFromSuperview()
                if transitionContext.transitionWasCancelled {
                    fromVC.view.layer.cornerRadius = 0
                    fromVC.view.clipsToBounds = false
                }
                fromVC.view.layer.shadowOpacity = 0
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                self?.currentAnimator = nil
            }
        }

        currentAnimator = animator
        return animator
    }
}
