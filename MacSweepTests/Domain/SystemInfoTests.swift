import Foundation
import Testing

@testable import MacSweep

@Suite("SystemInfo")
struct SystemInfoTests {
    @Test("model identifiers map to friendly names with a raw fallback")
    func modelNames() {
        #expect(MacModel.friendlyName(for: "Mac16,10") == "Mac mini (M4, 2024)")
        #expect(MacModel.friendlyName(for: "MacBookPro18,3") == "MacBook Pro (14-inch, M1 Max, 2021)")
        #expect(MacModel.friendlyName(for: "Mac99,99") == "Mac99,99")
    }

    @Test("current machine info is populated and consistent")
    func current() {
        let info = SystemInfo.current()
        #expect(!info.modelName.isEmpty)
        #expect(!info.chipName.isEmpty)
        #expect(info.logicalCores >= info.physicalCores)
        #expect(info.memoryBytes > 0)
        #expect(info.storageTotalBytes > 0)
        #expect(info.storageFreeBytes > 0)
        #expect(info.storageFreeBytes <= info.storageTotalBytes)
        #expect((0...1).contains(info.storageUsedFraction))
        #expect(!info.macOSVersion.isEmpty)

        print("[SystemInfo] \(info.modelName) | \(info.chipName) | \(info.logicalCores) cores | \(info.memoryBytes) B RAM | \(info.storageFreeBytes)/\(info.storageTotalBytes) B | macOS \(info.macOSVersion)")
    }

    @Test("storage usage is computed and clamped")
    func storageFraction() {
        let info = SystemInfo(
            modelName: "m",
            modelIdentifier: "Mac16,10",
            chipName: "c",
            physicalCores: 4,
            logicalCores: 8,
            memoryBytes: 1,
            storageTotalBytes: 100,
            storageFreeBytes: 25,
            macOSVersion: "1"
        )
        #expect(info.storageUsedBytes == 75)
        #expect(abs(info.storageUsedFraction - 0.75) < 0.0001)

        let empty = SystemInfo(
            modelName: "m",
            modelIdentifier: "x",
            chipName: "c",
            physicalCores: 0,
            logicalCores: 0,
            memoryBytes: 0,
            storageTotalBytes: 0,
            storageFreeBytes: 0,
            macOSVersion: "1"
        )
        #expect(empty.storageUsedFraction == 0)
    }
}
