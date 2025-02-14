//
//  SwipeModalViewController.swift
//  minip
//
//  Created by LZY on 2025/1/31.
//

import UIKit

class PannableNavigationViewController: UINavigationController {
    public var minimumScreenRatioToHide = 0.5 as CGFloat
    public var animationDuration = 0.2 as TimeInterval

    private lazy var transitionDelegate: SheetTransitionDelegate = .init()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.transitioningDelegate = self.transitionDelegate
    }

    @objc func onPan(_ panGesture: UIScreenEdgePanGestureRecognizer) {
        let translation = panGesture.translation(in: self.view)
        let horizontalMovement = translation.x / self.view.bounds.width
        let downwardMovement = fmaxf(Float(horizontalMovement), 0.0)

        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)

        let velocity = panGesture.velocity(in: self.view)
        let shouldFinish = progress > self.minimumScreenRatioToHide

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
            self.transitionDelegate.interactiveTransition.shouldFinish ? self.transitionDelegate.interactiveTransition.finish() : self.transitionDelegate.interactiveTransition.cancel()
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

    deinit {
        logger.info("[PannableNavigationViewController] nav controller deinit, deleting edgePanGestures")
        for gesture in edgePanGestures {
            gesture.view?.removeGestureRecognizer(gesture)
        }

        // TODO: clear twice when click close button
        // logger.info("[PannableNavigationViewController] clear open app info & reset orientation")
        if MiniAppManager.shared.openedApp?.landscape == true {
            if #available(iOS 16.0, *) {
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.unknown.rawValue, forKey: "orientation")
            }
        }
        MiniAppManager.shared.clearOpenedApp()
    }

    var edgePanGestures: [UIScreenEdgePanGestureRecognizer] = []
    func addPanGesture(vc: UIViewController) {
        let panGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(self.onPan(_:)))
        panGesture.edges = .left
        vc.view.addGestureRecognizer(panGesture)
        self.edgePanGestures.append(panGesture)
    }
}

class PannableTabBarController: UITabBarController {
    public var minimumScreenRatioToHide = 0.53 as CGFloat
    public var animationDuration = 0.2 as TimeInterval

    private lazy var transitionDelegate: SheetTransitionDelegate = .init()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.transitioningDelegate = self.transitionDelegate
    }

    @objc func onPan(_ panGesture: UIScreenEdgePanGestureRecognizer) {
        let translation = panGesture.translation(in: self.view)
        let horizontalMovement = translation.x / self.view.bounds.width
        let downwardMovement = fmaxf(Float(horizontalMovement), 0.0)

        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)

        let velocity = panGesture.velocity(in: self.view)
        let shouldFinish = progress > self.minimumScreenRatioToHide

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
            self.transitionDelegate.interactiveTransition.shouldFinish ? self.transitionDelegate.interactiveTransition.finish() : self.transitionDelegate.interactiveTransition.cancel()
        default:
            break
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        logger.info("[PannableNavigationViewController] nav controller deinit, deleting edgePanGestures")
        for gesture in edgePanGestures {
            gesture.view?.removeGestureRecognizer(gesture)
        }

        // TODO: clear twice when click close button
        // logger.info("[PannableNavigationViewController] clear open app info & reset orientation")
        if MiniAppManager.shared.openedApp?.landscape == true {
            if #available(iOS 16.0, *) {
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.unknown.rawValue, forKey: "orientation")
            }
        }
        MiniAppManager.shared.clearOpenedApp()
    }

    var edgePanGestures: [UIScreenEdgePanGestureRecognizer] = []
    func addPanGesture(vc: UIViewController) {
        let panGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(self.onPan(_:)))
        panGesture.edges = .left
        vc.view.addGestureRecognizer(panGesture)
        self.edgePanGestures.append(panGesture)
    }
}

class SheetInteractiveTransition: UIPercentDrivenInteractiveTransition {
    public var hasStarted: Bool = false
    public var shouldFinish: Bool = false
}

class SheetTransition {
    public var isPresenting: Bool = false
    public var presentDuration: TimeInterval = 0.3
    public var dismissDuration: TimeInterval = 0.3
}

class SheetTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    lazy var transition: SheetTransition = .init()
    lazy var interactiveTransition: SheetInteractiveTransition = .init()

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
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
        return self.transition.isPresenting ? self.transition.presentDuration : self.transition.dismissDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
              let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView

        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        var finalFrame = fromVC.view.frame
        finalFrame.origin.y += finalFrame.height

        UIView.animate(withDuration: self.transition.dismissDuration,
                       delay: 0.0,
                       options: .transitionCrossDissolve,
                       animations: {
                           fromVC.view.frame = finalFrame
                       },
                       completion: { _ in
                           transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                       })
    }
}
