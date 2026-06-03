//
//  ContentView.swift
//  minip-demo
//
//  Created by LZY on 2026/6/3.
//

import MinipRuntime
import SwiftUI

struct ContentView: View {
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "app.dashed")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Minip Runtime Demo")
                .font(.headline)

            Button {
                openDemoMiniApp()
            } label: {
                Text("Open Demo MiniApp")
                    .frame(maxWidth: 240)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    private func openDemoMiniApp() {
        let manager = MiniAppManager.shared

        // The runtime serves miniapps from the app's Documents directory, so on
        // first launch we install the bundled package there. Idempotent: once
        // installed, getAppInfos() finds it and we skip straight to opening.
        if manager.getAppInfos().isEmpty {
            guard let pkg = Bundle.main.url(forResource: "minip-demo", withExtension: "zip") else {
                errorMessage = "Bundled minip-demo.zip not found"
                return
            }
            InstallMiniApp(
                pkgFile: pkg,
                onSuccess: { presentFirstMiniApp() },
                onFailed: { msg in errorMessage = "Install failed: \(msg)" }
            )
        } else {
            presentFirstMiniApp()
        }
    }

    private func presentFirstMiniApp() {
        let manager = MiniAppManager.shared
        guard let app = manager.getAppInfos().first else {
            errorMessage = "No miniapp installed"
            return
        }
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.keyWindow?.rootViewController
        else {
            errorMessage = "No root view controller"
            return
        }
        errorMessage = nil
        manager.openMiniApp(parent: root, appInfo: app)
    }
}

#Preview {
    ContentView()
}
