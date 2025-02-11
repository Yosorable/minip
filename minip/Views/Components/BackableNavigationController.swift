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
    
    private lazy var transitionDelegate: NavTransitionDelegate = NavTransitionDelegate()
    
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
        for gesture in edgePanGestures {
            gesture.view?.removeGestureRecognizer(gesture)
        }
    }
    
    var edgePanGestures: [UIScreenEdgePanGestureRecognizer] = []
    func addPanGesture(vc: UIViewController) {
        let panGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        panGesture.edges = .left
        vc.view.addGestureRecognizer(panGesture)
        edgePanGestures.append(panGesture)
    }
}

class NavInteractiveTransition: UIPercentDrivenInteractiveTransition {
    public var hasStarted: Bool = false
    public var shouldFinish: Bool = false
}

class NavTransition {
    public var isPresenting: Bool = false
    public var presentDuration: TimeInterval = 0.3
    public var dismissDuration: TimeInterval = 0.3
}

class NavTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    lazy var transition: NavTransition = NavTransition()
    lazy var interactiveTransition: NavInteractiveTransition = NavInteractiveTransition()
    
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
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


extension NavTransitionDelegate:  UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.transition.isPresenting ? self.transition.presentDuration : self.transition.dismissDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
              let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        
        if self.transition.isPresenting {
            
            let finalFrameForVC = transitionContext.finalFrame(for: toVC)
            toVC.view.frame = finalFrameForVC.offsetBy(dx: UIScreen.main.bounds.size.width, dy: 0)
            containerView.addSubview(toVC.view)
            
            // Additional ways to animate, Spring velocity & damping
            UIView.animate(withDuration: self.transition.presentDuration,
                           delay: 0.0,
                           options: .transitionCrossDissolve,
                           animations: {
                toVC.view.frame = finalFrameForVC
                fromVC.view.transform = CGAffineTransform(translationX: -UIScreen.main.bounds.size.width / 3, y: 0)
            }, completion: { _ in
                transitionContext.completeTransition(true)
            })
            
        } else {
            var finalFrame = fromVC.view.frame
            finalFrame.origin.x += finalFrame.width
            
            // Additional ways to animate, Spring velocity & damping
            UIView.animate(withDuration: self.transition.dismissDuration,
                           delay: 0.0,
                           options: self.interactiveTransition.hasStarted ? .curveLinear : .transitionCrossDissolve,
                           animations: {
                fromVC.view.frame = finalFrame
                toVC.view.transform = .identity
            },
                           completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}
