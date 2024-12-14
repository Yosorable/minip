//
//  MinipApiV3.swift
//  minip
//
//  Created by LZY on 2024/12/14.
//

import Foundation

extension MinipNativeInteraction {
    func getInstalledAppList(replyHandler: @escaping (Any?, String?) -> Void) {
        Task {
            let appInfos = MiniAppManager.shared.getAppInfos()
            await MainActor.run {
                replyHandler(InteropUtils.succeedWithData(data: appInfos).toJsonString(), nil)
            }
        }
    }
}
