#if SWIFT_PACKAGE
import UIKit
#endif

public extension UIImage {
    static func fromName(_ name: String, for aClass: AnyClass) -> UIImage? {
        return UIImage(named: name, in: Bundle(for: aClass), compatibleWith: nil)
    }
}
