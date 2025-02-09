//
//  Device.swift
//  minip
//
//  Created by LZY on 2025/2/9.
//

import UIKit

extension MinipApi {
    func vibrate(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let data = param.data as? [String: String],
              let tp = data["type"] else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        var generator = UIImpactFeedbackGenerator(style: .medium)
        if tp == "light" {
            generator = UIImpactFeedbackGenerator(style: .light)
        } else if tp == "medium" {
            generator = UIImpactFeedbackGenerator(style: .medium)
        } else if tp == "heavy" {
            generator = UIImpactFeedbackGenerator(style: .heavy)
        }
        generator.impactOccurred()
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }
    
    func getClipboardData(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        if let txt = UIPasteboard.general.string {
            replyHandler(InteropUtils.succeedWithData(data: txt).toJsonString(), nil)
            return
        }
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }
    
    func setClipboardData(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let data = (param.data as? [String: Any])?["data"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        UIPasteboard.general.string = data
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }
}
