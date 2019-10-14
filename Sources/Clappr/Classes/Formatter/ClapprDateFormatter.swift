#if SWIFT_PACKAGE
import Foundation
#endif

open class ClapprDateFormatter {
    fileprivate static let hourInSeconds: Double = 1 * 60 * 60

    open class func formatSeconds(_ totalSeconds: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: totalSeconds)
        let formatter = Foundation.DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = totalSeconds < hourInSeconds ? "mm:ss" : "HH:mm:ss"
        return formatter.string(from: date)
    }
}
