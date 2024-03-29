//
//  OpenProjectAction.swift
//  minip
//
//  Created by LZY on 2024/3/28.
//

import AppIntents
import UIKit


@available(iOS 16, *)
struct OpenProjectAction: AppIntent {
    static var title: LocalizedStringResource = "Open Project"
    
    static var description: IntentDescription = IntentDescription(
"""
Open a project in minip.
"""
    )
    
    static var openAppWhenRun = true
    
    @Parameter(title: "Id or Name", description: "Id or name of the project", requestValueDialog: IntentDialog("What is the id or name of the project?"))
    var idOrName: String
    
    @MainActor
    func perform() async throws -> some ReturnsValue<Bool> {
        print(idOrName)
        
        let window = UIApplication.shared.windows.first
        if MiniAppManager.shared.openedApp?.appId == idOrName || MiniAppManager.shared.openedApp?.name == idOrName {
            return .result(value: true)
        }
        if MiniAppManager.shared.openedApp != nil {
            window?.rootViewController?.children.first?.dismiss(animated: false)
            MiniAppManager.shared.clearOpenedApp()
        }

        var foundApp: AppInfo?

        for ele in MiniAppManager.shared.getAppInfos() {
            if ele.appId == idOrName || ele.name == idOrName {
                foundApp = ele
                break
            }
        }
        
        guard let app = foundApp else {
            return .result(value: false)
        }

        MiniAppManager.shared.openMiniApp(app: app, rc: window?.rootViewController, animated: false)
        
        return .result(value: true)
    }
}
