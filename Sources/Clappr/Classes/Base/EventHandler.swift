import Foundation
#if SWIFT_PACKAGE
import ClapprObjC
#endif

public typealias EventUserInfo = [AnyHashable: Any]?

public typealias EventCallback = (_ userInfo: EventUserInfo) -> Void

open class EventHandler: NSObject {

    fileprivate var callback: EventCallback?

    @objc public init(callback: @escaping EventCallback) {
        self.callback = callback
    }

    @objc open func handleEvent(_ notification: Notification) {
        do {
            try ObjC.catchException { [weak self] in
                self?.callback?(notification.userInfo)
            }
        } catch {
            Logger.logError("A plugin crashed during invocation of an event (\(error.localizedDescription))", scope: "EventHandler")
        }
    }
}
