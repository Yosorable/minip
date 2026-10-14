import Foundation
import SafariServices

extension MinipApi {
    func navigateTo(param: Parameter) throws {
        let controller = try param.viewController
        guard let navigation = controller.navigationController else {
            throw MinipError(.invalidState, "The page has no navigation controller")
        }
        let page = try param.string("page")
        let next = MiniPageViewController(project: controller.project, page: page, title: try param.optionalString("title"))
        if controller.isRoot { next.hidesBottomBarWhenPushed = true }
        navigation.pushViewController(next, animated: true)
    }

    func navigateBack(param: Parameter) throws {
        let controller = try param.viewController
        let delta = try param.int("delta", default: 1)
        guard delta > 0 else { throw MinipError.invalidArgument("delta") }
        guard let navigation = controller.navigationController, navigation.topViewController === controller else {
            throw MinipError(.invalidState, "The calling page is not the active navigation page")
        }
        let index = max(0, navigation.viewControllers.count - 1 - delta)
        navigation.popToViewController(navigation.viewControllers[index], animated: true)
    }

    func redirectTo(param: Parameter) throws {
        try param.viewController.redirectTo(page: param.string("page"), title: param.optionalString("title"))
    }

    func openWebsite(param: Parameter) throws {
        let controller = try param.requirePresentation()
        guard let url = URL(string: try param.string("url")), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
            throw MinipError.invalidArgument("url")
        }
        let safari = SFSafariViewController(url: url)
        if let tint = controller.app.tintColor, let color = UIColor(hexOrCSSName: tint) {
            safari.preferredControlTintColor = color
        }
        controller.present(safari, animated: true)
    }

    func openSettings(param: Parameter) throws {
        let controller = try param.requirePresentation()
        let settings = MiniAppSettingsViewController(style: .insetGrouped, app: controller.app)
        let navigation = BackableNavigationController(rootViewController: settings)
        navigation.modalPresentationStyle = .overFullScreen
        controller.present(navigation, animated: true)
    }
}
