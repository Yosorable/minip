//
//  CreateProject.swift
//  minip
//
//  Created by LZY on 2025/2/9.
//

import UIKit

func ShowCreateNewProjectAlert(_ parentVC: UIViewController, onCreatedSuccess: @escaping (AppInfo) -> Void) {
    let alert = UIAlertController(title: i18n("cp.create_project"), message: nil, preferredStyle: .alert)
    alert.addTextField(configurationHandler: { tf in
        tf.placeholder = i18n("cp.name")
    })
    alert.addTextField(configurationHandler: { tf in
        tf.placeholder = i18n("cp.display_name")
    })

    let cancelAction = UIAlertAction(title: i18n("Cancel"), style: .cancel)
    let confirmAction = UIAlertAction(title: i18n("Create"), style: .default) { _ in
        let nameTF = alert.textFields?[0]
        let displayNameTF = alert.textFields?[1]
        let name = nameTF?.text
        let displayName = displayNameTF?.text

        do {
            let newApp = try MiniAppManager.shared.createMiniApp(name: name, displayName: displayName)
            showSimpleSuccess(msg: i18n("project_created_successfully"))
            onCreatedSuccess(newApp)
        } catch {
            showSimpleError(err: error)
        }
    }

    alert.addAction(cancelAction)
    alert.addAction(confirmAction)
    parentVC.present(alert, animated: true)
}
