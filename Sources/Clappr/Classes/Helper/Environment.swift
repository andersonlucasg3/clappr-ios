#if SWIFT_PACKAGE
import Foundation
#endif

open class Environment: NSObject {
    @objc public let playerId: String = UUID().uuidString
}
