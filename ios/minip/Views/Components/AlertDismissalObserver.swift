import ObjectiveC
import UIKit

@MainActor
final class AlertDismissalObserver: NSObject {
    private static var associationKey = 0
    private let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }
    deinit { onDismiss() }

    static func attach(to controller: UIViewController, onDismiss: @escaping () -> Void) {
        let observer = AlertDismissalObserver(onDismiss: onDismiss)
        // UIKit owns an alert's presentation delegate and throws if it is replaced.
        // Action handlers complete after dismissal; releasing the alert also completes
        // requests canceled by dismissing the presenter or tapping outside a popover.
        objc_setAssociatedObject(controller, &associationKey, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
