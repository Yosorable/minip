//
//  Transition.swift
//  minip
//
//  Created by LZY on 2025/2/12.
//

import UIKit

class BottomSheetTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return BottomSheetPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

class BottomSheetPresentationController: UIPresentationController {
    private let dimmingView = UIView()

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dimmingView.alpha = 0

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissController))
        dimmingView.addGestureRecognizer(tapGesture)
    }

    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }
        dimmingView.frame = containerView.bounds
        containerView.addSubview(dimmingView)
        containerView.addSubview(presentedViewController.view)

        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1
        }, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0
        }, completion: nil)
    }

    @objc private func dismissController() {
        presentedViewController.dismiss(animated: true, completion: nil)
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        dimmingView.frame = containerView!.bounds
        let height = min(max(containerView!.bounds.height, containerView!.bounds.width) / 3, containerView!.bounds.height)
        let width = min(containerView!.bounds.height, containerView!.bounds.width)
        presentedView?.frame = CGRect(x: (containerView!.bounds.width - width) / 2, y: containerView!.bounds.height - height, width: width, height: height)
    }
}
