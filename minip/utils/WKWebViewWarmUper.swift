//
//  WKWebViewWarmUper.swift
//  minip
//
//  Created by ByteDance on 2023/7/7.
//

import WebKit
import UIKit

public protocol WarmUpable {
    func warmUp()
}

public class WarmUper<Object: WarmUpable> {
    
    private let creationClosure: () -> Object
    private var warmedUpObjects: [Object] = []
    public var numberOfWamedUpObjects: Int = 5 {
        didSet {
            prepare()
        }
    }
    
    public init(creationClosure: @escaping () -> Object) {
        self.creationClosure = creationClosure
        prepare()
    }
    
    public func prepare() {
        while warmedUpObjects.count < numberOfWamedUpObjects {
            let object = creationClosure()
            object.warmUp()
            warmedUpObjects.append(object)
        }
    }
    
    private func createObjectAndWarmUp() -> Object {
        let object = creationClosure()
        object.warmUp()
        return object
    }
    
    public func dequeue() -> Object {
        let warmedUpObject: Object
        if let object = warmedUpObjects.first {
            warmedUpObjects.removeFirst()
            warmedUpObject = object
        } else {
            warmedUpObject = createObjectAndWarmUp()
        }
        prepare()
        return warmedUpObject
    }
    
}

extension WKWebView: WarmUpable {
    public func warmUp() {
        //        loadHTMLString("", baseURL: nil)
    }
}

public typealias WKWebViewWarmUper = WarmUper<WKWebView>
public extension WarmUper where Object == WKWebView {
    static let shared = WKWebViewWarmUper(creationClosure: {
        let cfg = WKWebViewConfiguration()
        cfg.mediaTypesRequiringUserActionForPlayback = []
        cfg.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        cfg.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        cfg.allowsInlineMediaPlayback = true
        
        let res = WKWebView(frame: .zero, configuration: cfg)
        
        res.isOpaque = false
        res.scrollView.contentInsetAdjustmentBehavior = .always
        
        return res
    })
}

class FWKWebView: WKWebView {
    override var safeAreaInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}
