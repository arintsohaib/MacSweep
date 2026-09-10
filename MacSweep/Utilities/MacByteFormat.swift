import Foundation

public enum MacByteFormat {
    public static func format(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 B" }
        let units = ["B", "KB", "MB", "GB", "TB", "PB"]
        var value = Double(bytes)
        var unitIndex = 0
        while value >= 1024, unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        if unitIndex == 0 {
            return "\(bytes) B"
        }
        var decimals: Int = value < 10 ? 1 : 0
        var rounded = (value * pow(10, Double(decimals))).rounded() / pow(10, Double(decimals))
        if rounded >= 1024, unitIndex < units.count - 1 {
            rounded /= 1024
            unitIndex += 1
            decimals = rounded < 10 ? 1 : 0
        }
        let text: String
        if decimals == 1, rounded.truncatingRemainder(dividingBy: 1) != 0 {
            text = String(format: "%.1f", rounded)
        } else {
            text = String(format: "%.0f", rounded)
        }
        return "\(text) \(units[unitIndex])"
    }
}
