import Foundation
import ProgressHUD
import UIKit

extension MinipApi {
    func setNavigationBarTitle(param: Parameter) throws {
        try param.viewController.title = param.string("title")
    }

    func setNavigationBarColor(param: Parameter) throws {
        let controller = try param.viewController
        guard let foreground = UIColor(hexOrCSSName: try param.string("foregroundColor")),
              let background = UIColor(hexOrCSSName: try param.string("backgroundColor")) else {
            throw MinipError(.invalidArgument, "Invalid navigation bar color")
        }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = background
        appearance.titleTextAttributes = [.foregroundColor: foreground]
        appearance.shadowColor = .clear
        for child in controller.tabBarController?.viewControllers ?? [controller] {
            let navigation = (child as? UINavigationController) ?? child.navigationController
            navigation?.navigationBar.standardAppearance = appearance
            navigation?.navigationBar.scrollEdgeAppearance = appearance
        }
    }

    func enablePullDownRefresh(param: Parameter) throws { try param.viewController.addRefreshControl() }

    func disablePullDownRefresh(param: Parameter) throws {
        let controller = try param.viewController
        controller.refreshControl?.endRefreshing()
        controller.refreshControl?.removeFromSuperview()
        controller.refreshControl = nil
    }

    func startPullDownRefresh(param: Parameter) throws { try param.viewController.refreshControl?.beginRefreshing() }
    func stopPullDownRefresh(param: Parameter) throws { try param.viewController.refreshControl?.endRefreshing() }

    func showHUD(param: Parameter) throws {
        let type = try param.string("type")
        let title = try param.optionalString("title")
        let message = try param.optionalString("message")
        let delay = try param.number("delay")
        guard delay == nil || delay! >= 0 else { throw MinipError.invalidArgument("delay") }
        let seconds = delay.map { $0 / 1000 }
        let interaction = try param.bool("interaction", default: true)
        let text = [title, message].compactMap { $0 }.joined(separator: "\n")
        switch type {
        case "success": ProgressHUD.succeed(text, interaction: interaction, delay: seconds)
        case "error": ProgressHUD.failed(text, interaction: interaction, delay: seconds)
        case "progress": ProgressHUD.animate(text, interaction: interaction)
        case "banner":
            if let seconds { ProgressHUD.banner(title, message, delay: seconds) }
            else { ProgressHUD.banner(title, message) }
        default: throw MinipError.invalidArgument("type")
        }
    }

    func hideHUD(param: Parameter) throws { ProgressHUD.dismiss() }

    struct AlertInput {
        let key: String
        let type: String?
        let title: String?
        let defaultValue: String?
    }

    struct AlertAction {
        let title: String?
        let style: String?
        let key: String
    }

    struct AlertConfig {
        let title: String?
        let message: String?
        let preferredStyle: String?
        let actions: [AlertAction]
    }

    struct AlertResult: Encodable {
        let action: String
        let inputs: [String: String]
    }

    func showAlert(param: Parameter) async throws -> AlertResult? {
        let controller = try param.requirePresentation()
        let actions = try param.array("actions").map { value in
            let action = try param.object(value, name: "actions")
            return try AlertAction(title: action.optionalString("title"), style: action.optionalString("style"), key: action.string("key"))
        }
        let inputs = try (param.optionalArray("inputs") ?? []).map { value in
            let input = try param.object(value, name: "inputs")
            return try AlertInput(key: input.string("key"), type: input.optionalString("type"), title: input.optionalString("title"), defaultValue: input.optionalString("defaultValue"))
        }
        let config = try AlertConfig(title: param.optionalString("title"), message: param.optionalString("message"), preferredStyle: param.optionalString("preferredStyle"), actions: actions)
        guard !config.actions.isEmpty,
              Set(config.actions.map(\.key)).count == config.actions.count,
              config.actions.filter({ $0.style == "cancel" }).count <= 1,
              config.actions.allSatisfy({ $0.style == nil || ["cancel", "destructive"].contains($0.style!) }),
              config.preferredStyle == nil || ["alert", "actionSheet"].contains(config.preferredStyle!) else {
            throw MinipError(.invalidArgument, "Invalid alert configuration")
        }
        guard Set(inputs.map(\.key)).count == inputs.count,
              inputs.allSatisfy({ $0.type == nil || ["text", "number", "password"].contains($0.type!) }),
              inputs.isEmpty || config.preferredStyle != "actionSheet" else {
            throw MinipError.invalidArgument("inputs")
        }
        return try await withCheckedThrowingContinuation { continuation in
            let completion = BridgeContinuation(continuation)
            var selection: AlertResult?
            let alert = UIAlertController(title: config.title, message: config.message, preferredStyle: config.preferredStyle == "actionSheet" ? .actionSheet : .alert)
            for input in inputs {
                alert.addTextField { field in
                    field.placeholder = input.title
                    field.text = input.defaultValue
                    field.isSecureTextEntry = input.type == "password"
                    if input.type == "number" { field.keyboardType = .numberPad }
                }
            }
            for action in config.actions {
                let style: UIAlertAction.Style = action.style == "cancel" ? .cancel : action.style == "destructive" ? .destructive : .default
                alert.addAction(UIAlertAction(title: action.title ?? action.key, style: style) { [weak alert] _ in
                    var values: [String: String] = [:]
                    for (input, field) in zip(inputs, alert?.textFields ?? []) { values[input.key] = field.text ?? "" }
                    selection = AlertResult(action: action.key, inputs: values)
                    alert?.dismiss(animated: true) { completion.finish(.success(selection)) }
                })
            }
            alert.view.tintColor = controller.view.tintColor
            if let popover = alert.popoverPresentationController {
                popover.sourceView = controller.view
                popover.sourceRect = controller.view.bounds
            }
            controller.present(alert, animated: true)
            AlertDismissalObserver.attach(to: alert) { completion.finish(.success(selection)) }
        }
    }

    func showPicker(param: Parameter) async throws -> BridgeValue {
        let controller = try param.requirePresentation()
        guard let type = PickerType(rawValue: try param.string("type")) else { throw MinipError.invalidArgument("type") }
        let data = try param.object(param.value("data"), name: "data")
        let picker = PickerViewController()
        picker.pickerType = type
        do {
            switch type {
            case .singleColumn:
                let value = try SingleColumnPickerView.Data(column: data.strings("column"), index: data.int("index"))
                guard value.column.indices.contains(value.index) else { throw MinipError.invalidArgument("index") }
                picker.singlePickerData = value
            case .multipleColumns:
                let columns = try data.array("columns").map { value -> [String] in
                    guard case .array(let column) = value else { throw MinipError.invalidArgument("columns") }
                    return try column.map { value in
                        guard case .string(let text) = value else { throw MinipError.invalidArgument("columns") }
                        return text
                    }
                }
                let indices = try data.array("index").map { value -> Int in
                    guard let integer = value.int64, let index = Int(exactly: integer) else { throw MinipError.invalidArgument("index") }
                    return index
                }
                let value = MultiColumnsPickerView.Data(columns: columns, index: indices)
                guard !value.columns.isEmpty, value.columns.count == value.index.count,
                      zip(value.columns, value.index).allSatisfy({ $0.0.indices.contains($0.1) }) else { throw MinipError.invalidArgument("index") }
                picker.multiPickerData = value
            case .date, .time:
                let value = try DatePickerView.Data(start: data.optionalString("start"), end: data.optionalString("end"), value: data.optionalString("value"), dateFormat: data.string("dateFormat"))
                guard !value.dateFormat.isEmpty else { throw MinipError.invalidArgument("dateFormat") }
                let formatter = DateFormatter()
                formatter.dateFormat = value.dateFormat
                for text in [value.start, value.end, value.value].compactMap({ $0 }) {
                    guard formatter.date(from: text) != nil else { throw MinipError(.invalidArgument, "Date does not match dateFormat") }
                }
                if let start = value.start.flatMap(formatter.date), let end = value.end.flatMap(formatter.date), start > end {
                    throw MinipError(.invalidArgument, "Date range starts after it ends")
                }
                picker.datePickerData = value
            }
        } catch {
            if let error = error as? MinipError { throw error }
            throw MinipError.invalidArgument("data")
        }
        return try await withCheckedThrowingContinuation { continuation in
            let completion = BridgeContinuation(continuation)
            picker.onConfirmed = { [weak picker] in
                guard let picker else { completion.finish(.failure(MinipError(.invalidState, "Picker is unavailable"))); return }
                switch type {
                case .singleColumn:
                    completion.finish(.success(picker.singlePickerResult.map { .signed(Int64($0)) } ?? .null))
                case .multipleColumns:
                    completion.finish(.success(picker.multiPickerResult.map { .array($0.map { .signed(Int64($0)) }) } ?? .null))
                case .date, .time:
                    completion.finish(.success(picker.datePickerResult.map(BridgeValue.string) ?? .null))
                }
            }
            picker.onCanceled = { completion.finish(.success(.null)) }
            picker.view.tintColor = controller.view.tintColor
            controller.present(picker, animated: true)
        }
    }
}
