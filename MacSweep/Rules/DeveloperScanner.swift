import Foundation

public struct DeveloperScanner: FindingsScanner {
    public let category = ScanCategory.developerCaches

    private struct Target {
        let title: String
        let subpath: String
        let reason: String
        let consequence: String
        let isDocker: Bool
    }

    public init() {}

    private var targets: [Target] {
        [
            Target(
                title: "Xcode DerivedData",
                subpath: "Library/Developer/Xcode/DerivedData",
                reason: "Xcode build intermediates, module caches, and symbol indexes.",
                consequence: "Consequence: Clean rebuilds will take longer initially as build artifacts and module caches regenerate.",
                isDocker: false
            ),
            Target(
                title: "CoreSimulator Caches",
                subpath: "Library/Developer/CoreSimulator/Caches",
                reason: "Runtime caches and temporary assets created by Apple device simulators.",
                consequence: "Consequence: Simulators will reload runtimes and recreate caches as needed.",
                isDocker: false
            ),
            Target(
                title: "Homebrew Cache",
                subpath: "Library/Caches/Homebrew",
                reason: "Downloaded package bottles, git clones, and source tarballs managed by Homebrew.",
                consequence: "Consequence: Formulae will re-download bottles upon reinstallation or upgrade.",
                isDocker: false
            ),
            Target(
                title: "Swift Package Manager Cache",
                subpath: "Library/Caches/org.swift.swiftpm",
                reason: "Cloned git repositories and binary package artifacts downloaded by SPM.",
                consequence: "Consequence: Package dependencies will be fetched again on the next clean build.",
                isDocker: false
            ),
            Target(
                title: "npm Cache",
                subpath: ".npm",
                reason: "Downloaded tarballs and index metadata from the npm registry.",
                consequence: "Consequence: Packages will be fetched from the registry upon next `npm install`.",
                isDocker: false
            ),
            Target(
                title: "Yarn Cache",
                subpath: "Library/Caches/Yarn",
                reason: "Package archives and metadata cached by the Yarn package manager.",
                consequence: "Consequence: Dependencies will be re-downloaded on subsequent Yarn installs.",
                isDocker: false
            ),
            Target(
                title: "pip Cache",
                subpath: "Library/Caches/pip",
                reason: "Pre-built Python wheels and source distributions cached by pip.",
                consequence: "Consequence: Python packages will be re-downloaded upon installation.",
                isDocker: false
            ),
            Target(
                title: "Gradle Caches",
                subpath: ".gradle/caches",
                reason: "Downloaded jar files, plugin artifacts, and build cache entries managed by Gradle.",
                consequence: "Consequence: Dependencies and plugin jars will be re-downloaded on the next build.",
                isDocker: false
            ),
            Target(
                title: "Playwright Browsers",
                subpath: "Library/Caches/ms-playwright",
                reason: "Headless Chromium, Firefox, and WebKit browser builds downloaded by Playwright.",
                consequence: "Consequence: Test suites will require `npx playwright install` before headless testing.",
                isDocker: false
            ),
            Target(
                title: "Docker VM & Storage",
                subpath: "Library/Containers/com.docker.docker",
                reason: "Docker Desktop virtual machine disk images, container volumes, and layer storage.",
                consequence: "Protected in v1: MacSweep does not perform automatic Docker pruning to prevent loss of active containers and images.",
                isDocker: true
            ),
        ]
    }

    public func scan(context: ScanContext) async throws -> [CleanupItem] {
        var items: [CleanupItem] = []

        for target in targets {
            try context.checkCancellation()
            let url = context.homeDirectory.appendingPathComponent(target.subpath)
            if context.exclusions.isExcluded(url) { continue }

            let meta: FileMetadata
            do {
                meta = try context.fileSystem.stat(url)
            } catch {
                continue
            }

            let size: Int64
            switch meta.kind {
            case .directory:
                size = (try? context.fileSystem.totalSize(of: meta.requestedURL)) ?? 0
            case .file:
                size = meta.size
            case .symbolicLink, .other:
                continue
            }

            guard size > 0 else { continue }

            let snapshot = PathSnapshot(
                url: meta.requestedURL,
                kind: meta.kind,
                size: size,
                modificationDate: meta.modificationDate
            )

            let risk: RiskLevel = target.isDocker ? .protected : .review
            let cleanupAllowed = !target.isDocker
            let action: RecommendedAction = target.isDocker ? .reviewOnly : .moveToTrash
            let reason = "\(target.reason) \(target.consequence)"

            do {
                let item = try CleanupItem(
                    category: category,
                    title: target.title,
                    reason: reason,
                    paths: [snapshot],
                    risk: risk,
                    confidence: .high,
                    evidence: [
                        Evidence(kind: .pathConvention, detail: "Standard developer directory: ~/\(target.subpath)."),
                        Evidence(kind: .sizeThreshold, detail: "Occupies \(MacByteFormat.format(size)) of developer storage."),
                    ],
                    recommendedAction: action,
                    selectedByDefault: false,
                    cleanupAllowed: cleanupAllowed,
                    modifiedAt: meta.modificationDate
                )
                items.append(item)
            } catch {
                continue
            }
        }

        return items
    }
}
