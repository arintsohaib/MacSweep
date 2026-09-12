import Darwin
import Foundation

/// Gathers `SystemInfo` from the running machine using only read-only syscalls
/// and Foundation APIs (no external processes, no network).
public enum SystemInfoProvider {
    public static func load() -> SystemInfo {
        let modelIdentifier = sysctlString("hw.model") ?? "Mac"
        let chip = sysctlString("machdep.cpu.brand_string")?.trimmingCharacters(in: .whitespaces)
            ?? sysctlString("hw.machine")
            ?? "Apple Silicon"
        let physical = Int(sysctlInt("hw.physicalcpu") ?? 0)
        let logical = Int(sysctlInt("hw.logicalcpu") ?? 0)
        let memory = ProcessInfo.processInfo.physicalMemory
        let (total, free) = volumeCapacity()
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let macOSVersion = "\(version.majorVersion).\(version.minorVersion)"
            + (version.patchVersion > 0 ? ".\(version.patchVersion)" : "")

        return SystemInfo(
            modelName: MacModel.friendlyName(for: modelIdentifier),
            modelIdentifier: modelIdentifier,
            chipName: chip,
            physicalCores: physical,
            logicalCores: logical,
            memoryBytes: memory,
            storageTotalBytes: total,
            storageFreeBytes: free,
            macOSVersion: macOSVersion
        )
    }

    private static func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        let value = String(cString: buffer)
        return value.isEmpty ? nil : value
    }

    private static func sysctlInt(_ name: String) -> Int64? {
        var value: Int64 = 0
        var size = MemoryLayout<Int64>.size
        guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return nil }
        return value
    }

    private static func volumeCapacity() -> (total: Int64, free: Int64) {
        let url = URL(fileURLWithPath: "/")
        let keys: Set<URLResourceKey> = [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey,
        ]
        guard let values = try? url.resourceValues(forKeys: keys) else { return (0, 0) }
        let total = Int64(values.volumeTotalCapacity ?? 0)
        let free = values.volumeAvailableCapacityForImportantUsage
            ?? Int64(values.volumeAvailableCapacity ?? 0)
        return (total, free)
    }
}

/// Best-effort mapping from Apple model identifiers (`hw.model`) to friendly
/// names. Unknown identifiers fall back to the raw identifier.
enum MacModel {
    private static let names: [String: String] = [
        // Mac mini
        "Macmini9,1": "Mac mini (M1, 2020)",
        "Mac14,3": "Mac mini (M2, 2023)",
        "Mac14,12": "Mac mini (M2 Pro, 2023)",
        "Mac16,10": "Mac mini (M4, 2024)",
        "Mac16,11": "Mac mini (M4 Pro, 2024)",
        // Mac Studio
        "Mac13,1": "Mac Studio (M1 Max, 2022)",
        "Mac13,2": "Mac Studio (M1 Ultra, 2022)",
        "Mac14,13": "Mac Studio (M2 Max, 2023)",
        "Mac14,14": "Mac Studio (M2 Ultra, 2023)",
        // MacBook Air
        "MacBookAir10,1": "MacBook Air (M1, 2020)",
        "Mac14,2": "MacBook Air (M2, 2022)",
        "Mac14,15": "MacBook Air (15-inch, M2, 2023)",
        "Mac15,12": "MacBook Air (13-inch, M3, 2024)",
        "Mac15,13": "MacBook Air (15-inch, M3, 2024)",
        "Mac16,12": "MacBook Air (13-inch, M4, 2025)",
        "Mac16,13": "MacBook Air (15-inch, M4, 2025)",
        // MacBook Pro
        "MacBookPro17,1": "MacBook Pro (13-inch, M1, 2020)",
        "MacBookPro18,1": "MacBook Pro (14-inch, M1 Pro, 2021)",
        "MacBookPro18,2": "MacBook Pro (16-inch, M1 Pro, 2021)",
        "MacBookPro18,3": "MacBook Pro (14-inch, M1 Max, 2021)",
        "MacBookPro18,4": "MacBook Pro (16-inch, M1 Max, 2021)",
        "Mac14,5": "MacBook Pro (14-inch, M2 Max, 2023)",
        "Mac14,6": "MacBook Pro (16-inch, M2 Max, 2023)",
        "Mac14,9": "MacBook Pro (14-inch, M2 Pro, 2023)",
        "Mac14,10": "MacBook Pro (16-inch, M2 Pro, 2023)",
        "Mac15,3": "MacBook Pro (14-inch, M3, 2023)",
        "Mac15,6": "MacBook Pro (14-inch, M3 Pro, 2023)",
        "Mac15,7": "MacBook Pro (16-inch, M3 Pro, 2023)",
        "Mac15,8": "MacBook Pro (14-inch, M3 Max, 2023)",
        "Mac15,9": "MacBook Pro (16-inch, M3 Max, 2023)",
        "Mac16,1": "MacBook Pro (14-inch, M4, 2024)",
        "Mac16,5": "MacBook Pro (16-inch, M4 Pro, 2024)",
        "Mac16,6": "MacBook Pro (16-inch, M4 Max, 2024)",
        // iMac / Mac Pro
        "iMac21,1": "iMac (24-inch, M1, 2021)",
        "iMac21,2": "iMac (24-inch, M1, 2021)",
        "Mac15,4": "iMac (24-inch, M3, 2023)",
        "Mac15,5": "iMac (24-inch, M3, 2023)",
        "Mac16,3": "iMac (24-inch, M4, 2024)",
        "Mac13,3": "Mac Pro (M2 Ultra, 2023)",
    ]

    static func friendlyName(for identifier: String) -> String {
        names[identifier] ?? identifier
    }
}
