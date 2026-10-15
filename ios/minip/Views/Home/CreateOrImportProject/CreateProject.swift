//
//  CreateProject.swift
//  minip
//
//  Created by LZY on 2025/2/9.
//

import UIKit

func ShowCreateNewProjectAlert(_ parentVC: UIViewController, onCreatedSuccess: @escaping (InstalledProject) -> Void) {
    let alert = UIAlertController(title: String(localized: "Create Project"), message: nil, preferredStyle: .alert)
    alert.addTextField(configurationHandler: { tf in
        tf.placeholder = String(localized: "Name")
    })
    alert.addTextField(configurationHandler: { tf in
        tf.placeholder = String(localized: "Display Name")
    })

    let cancelAction = UIAlertAction(title: String(localized: "Cancel"), style: .cancel)
    let confirmAction = UIAlertAction(title: String(localized: "Create"), style: .default) { _ in
        let nameTF = alert.textFields?[0]
        let displayNameTF = alert.textFields?[1]
        let name = nameTF?.text
        let displayName = displayNameTF?.text

        do {
            let newApp = try MiniAppManager.shared.createMiniApp(name: name, displayName: displayName)
            showSimpleSuccess(msg: String(localized: "Project created successfully."))
            onCreatedSuccess(newApp)
        } catch {
            showSimpleError(err: error)
        }
    }

    alert.addAction(cancelAction)
    alert.addAction(confirmAction)
    parentVC.present(alert, animated: true)
}
