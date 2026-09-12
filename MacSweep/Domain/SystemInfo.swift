import Foundation

/// A read-only snapshot of the user's Mac, shown on the Overview dashboard.
public struct SystemInfo: Equatable, Sendable {
    public var modelName: String
    public var modelIdentifier: String
    public var chipName: String
    public var physicalCores: Int
    public var logicalCores: Int
    public var memoryBytes: UInt64
    public var storageTotalBytes: Int64
    public var storageFreeBytes: Int64
    public var macOSVersion: String

    public init(
        modelName: String,
        modelIdentifier: String,
        chipName: String,
        physicalCores: Int,
        logicalCores: Int,
        memoryBytes: UInt64,
        storageTotalBytes: Int64,
        storageFreeBytes: Int64,
        macOSVersion: String
    ) {
        self.modelName = modelName
        self.modelIdentifier = modelIdentifier
        self.chipName = chipName
        self.physicalCores = physicalCores
        self.logicalCores = logicalCores
        self.memoryBytes = memoryBytes
        self.storageTotalBytes = storageTotalBytes
        self.storageFreeBytes = storageFreeBytes
        self.macOSVersion = macOSVersion
    }

    public var storageUsedBytes: Int64 {
        max(0, storageTotalBytes - storageFreeBytes)
    }

    public var storageUsedFraction: Double {
        guard storageTotalBytes > 0 else { return 0 }
        return min(1, max(0, Double(storageUsedBytes) / Double(storageTotalBytes)))
    }

    /// Reads the current machine. Never spawns processes and works offline.
    public static func current() -> SystemInfo {
        SystemInfoProvider.load()
    }
}
