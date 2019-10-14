import Foundation
#if SWIFT_PACKAGE
import UIKit
#endif

open class UIObject: BaseObject {
    @objc open var view: UIView = UIView()
    @objc open func render() {}
}
