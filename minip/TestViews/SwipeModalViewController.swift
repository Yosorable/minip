//
//  SwipeModalViewController.swift
//  minip
//
//  Created by LZY on 2025/1/31.
//

import UIKit

class SwipeModalViewController : UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.overrideUserInterfaceStyle = .light
        self.view.backgroundColor = .white
        self.title = "SwipeModalViewController"
        
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(panGestureRecognizerHandler))
        gesture.edges = .left
        self.view.addGestureRecognizer(gesture)
    }
    
    var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
    @objc func panGestureRecognizerHandler(_ sender: UIScreenEdgePanGestureRecognizer) {
        let touchPoint = sender.location(in: self.view?.window)
        
        if sender.state == UIGestureRecognizer.State.began {
            initialTouchPoint = touchPoint
            print(touchPoint)
        } else if sender.state == UIGestureRecognizer.State.changed {
            if touchPoint.x - initialTouchPoint.x > 0 {
                let offset = max(0, touchPoint.x - initialTouchPoint.x)
                let newY = (offset / self.view.frame.size.width) * self.view.frame.size.height
                self.view.frame = CGRect(x: 0, y: newY, width: self.view.frame.size.width, height: self.view.frame.size.height)
            }
        } else if sender.state == UIGestureRecognizer.State.ended || sender.state == UIGestureRecognizer.State.cancelled {
            if touchPoint.x - initialTouchPoint.x >= self.view.frame.size.width / 1.7 {
                self.dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                })
            }
        }
    }
}

class PannableNavigationViewController: UINavigationController {
    public var minimumScreenRatioToHide = 0.53 as CGFloat
    public var animationDuration = 0.2 as TimeInterval
    
    private lazy var transitionDelegate: TransitionDelegate = TransitionDelegate()
    
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
        
        // toto: clear twice when click close button
        logger.info("[PannableNavigationViewController] clear open app info & reset orientation")
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
        let panGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        panGesture.edges = .left
        vc.view.addGestureRecognizer(panGesture)
        edgePanGestures.append(panGesture)
    }
    
    func removePanGesture(vc: UIViewController) {
        //vc.view.removeGestureRecognizer(panGesture)
    }
}

class InteractiveTransition: UIPercentDrivenInteractiveTransition {
    public var hasStarted: Bool = false
    public var shouldFinish: Bool = false
}

class Transition {
    public var isPresenting: Bool = false
    public var presentDuration: TimeInterval = 0.3
    public var dismissDuration: TimeInterval = 0.3
}

class TransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    lazy var transition: Transition = Transition()
    lazy var interactiveTransition: InteractiveTransition = InteractiveTransition()
    
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


extension TransitionDelegate:  UIViewControllerAnimatedTransitioning {
    
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
            toVC.view.frame = finalFrameForVC.offsetBy(dx: 0, dy: UIScreen.main.bounds.size.height)
            containerView.addSubview(toVC.view)
            
            // Additional ways to animate, Spring velocity & damping
            UIView.animate(withDuration: self.transition.presentDuration,
                           delay: 0.0,
                           options: .transitionCrossDissolve,
                           animations: {
                fromVC.view.alpha = 0.3
                toVC.view.frame = finalFrameForVC
                fromVC.view.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
            }, completion: { _ in
                transitionContext.completeTransition(true)
            })
            
        } else {
            
            var finalFrame = fromVC.view.frame
            finalFrame.origin.y += finalFrame.height
            
            // Additional ways to animate, Spring velocity & damping
            UIView.animate(withDuration: self.transition.dismissDuration,
                           delay: 0.0,
                           options: .transitionCrossDissolve,
                           animations: {
                fromVC.view.frame = finalFrame
                toVC.view.alpha = 1.0
                toVC.view.transform = .identity
            },
                           completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}
