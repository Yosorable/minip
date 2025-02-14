//
//  CreateProject.swift
//  minip
//
//  Created by LZY on 2025/2/9.
//

import UIKit

func ShowCreateNewProjectAlert(_ parentVC: UIViewController, onCreatedSuccess: @escaping (AppInfo) -> Void) {
    let alert = UIAlertController(title: "Create Project", message: nil, preferredStyle: .alert)
    alert.addTextField(configurationHandler: { tf in
        tf.placeholder = "name"
    })
    alert.addTextField(configurationHandler: { tf in
        tf.placeholder = "display name"
    })

    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
    let confirmAction = UIAlertAction(title: "Create", style: .default) { _ in
        let nameTF = alert.textFields?[0]
        let displayNameTF = alert.textFields?[1]
        let name = nameTF?.text
        let displayName = displayNameTF?.text

        do {
            let newApp = try MiniAppManager.shared.createMiniApp(name: name, displayName: displayName)
            ShowSimpleSuccess(msg: "Project created successfully.")
            onCreatedSuccess(newApp)
        } catch {
            ShowSimpleError(err: error)
        }
    }

    alert.addAction(cancelAction)
    alert.addAction(confirmAction)
    parentVC.present(alert, animated: true)
}
