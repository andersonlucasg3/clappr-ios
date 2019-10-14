#if SWIFT_PACKAGE
import UIKit
#endif

open class UIContainerPlugin: SimpleContainerPlugin, UIPlugin {
    var uiObject = UIObject()

    public var view: UIView {
        get {
            return uiObject.view
        } set(newValue) {
            return uiObject.view = newValue
        }
    }
    
    open func render() {
        NSException(name: NSExceptionName("RenderNotOverriden"), reason: "UIContainerPlugins should always override the render method").raise()
    }
}
