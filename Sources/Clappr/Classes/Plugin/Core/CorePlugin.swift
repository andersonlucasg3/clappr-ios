#if SWIFT_PACKAGE
import Foundation
#endif

open class CorePlugin: BaseObject, Plugin {
    @objc open weak var core: Core?
    open class var type: PluginType { return .core }
    
    @objc open class var name: String {
        NSException(name: NSExceptionName(rawValue: "MissingPluginName"), reason: "Core Plugins should always declare a name. \(self) does not.", userInfo: nil).raise()
        return ""
    }
    
    @objc public required init(context: UIObject) {
        super.init()
        if let core = context as? Core {
            self.core = core
        } else {
            NSException(name: NSExceptionName(rawValue: "WrongContextType"), reason: "Core Plugins should always be initialized with a Core context", userInfo: nil).raise()
        }
    }

    open func destroy() {
        Logger.logDebug("destroying", scope: "CorePlugin")
        Logger.logDebug("destroying listeners", scope: "CorePlugin")
        stopListening()
        Logger.logDebug("destroyed", scope: "CorePlugin")
    }
}
