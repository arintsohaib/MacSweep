import Foundation

public enum BundleIDMapping {
    public static func bundleID(fromFolderName name: String) -> BundleIdentifier? {
        BundleIdentifier(rawValue: name)
    }

    public static func folderNameMatchesBundleID(name: String, bundleID: BundleIdentifier) -> Bool {
        let lowered = name.lowercased()
        let id = bundleID.normalized
        if lowered == id {
            return true
        }
        let lastSegment = id.split(separator: ".").last.map(String.init).flatMap { $0.lowercased() }
        return lastSegment.map { lowered == $0 } ?? false
    }

    public static func expectedFolderNames(bundleID: BundleIdentifier, displayName: String?) -> [String] {
        var names: [String] = [bundleID.rawValue]
        let lastSegment = bundleID.rawValue.split(separator: ".").last.map(String.init)
        if let lastSegment {
            names.append(lastSegment)
        }
        if let displayName, !displayName.isEmpty {
            names.append(displayName)
        }
        var seen = Set<String>()
        return names.filter { seen.insert($0.lowercased()).inserted }
    }
}
