import Foundation

public enum RecommendedAction: String, CaseIterable, Codable, Sendable {
    case moveToTrash
    case reviewOnly

    public var description: String {
        switch self {
        case .moveToTrash: "Move to Trash"
        case .reviewOnly: "Review only — no cleanup offered"
        }
    }
}

public enum CleanupItemError: Error, Equatable {
    case emptyPaths
    case emptyTitle
    case emptyReason
    case invalidPath(URL)
    case duplicatePath(URL)
    case nestedPaths(URL, URL)
    case negativeSize(URL)
    case missingEvidence
    case protectedItemMustNotBeCleanable
    case protectedItemMustNotBeSelected
    case inconsistentAction
}

public struct CleanupItem: Identifiable, Hashable, Codable, Sendable {
    public let id: CleanupItemID
    public var category: ScanCategory
    public var application: ApplicationIdentity?
    public var title: String
    public var reason: String
    public var paths: [PathSnapshot]
    public var risk: RiskLevel
    public var confidence: Confidence
    public var evidence: [Evidence]
    public var recommendedAction: RecommendedAction
    public var selectedByDefault: Bool
    public var cleanupAllowed: Bool
    public var modifiedAt: Date?

    public var totalSize: Int64 {
        paths.reduce(0) { $0 + $1.size }
    }

    public var primaryPath: PathSnapshot? { paths.first }

    public init(
        category: ScanCategory,
        application: ApplicationIdentity? = nil,
        title: String,
        reason: String,
        paths: [PathSnapshot],
        risk: RiskLevel,
        confidence: Confidence,
        evidence: [Evidence],
        recommendedAction: RecommendedAction,
        selectedByDefault: Bool,
        cleanupAllowed: Bool,
        modifiedAt: Date? = nil
    ) throws {
        guard !paths.isEmpty else { throw CleanupItemError.emptyPaths }
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw CleanupItemError.emptyTitle }
        guard !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw CleanupItemError.emptyReason }
        guard !evidence.isEmpty else { throw CleanupItemError.missingEvidence }

        var seen = Set<URL>()
        let canonicalPaths: [PathSnapshot] = try paths.map { snapshot in
            let url = snapshot.url.standardizedFileURL
            guard url.isFileURL, url.path != "/", !url.path.isEmpty else {
                throw CleanupItemError.invalidPath(snapshot.url)
            }
            guard snapshot.size >= 0 else { throw CleanupItemError.negativeSize(snapshot.url) }
            guard seen.insert(url).inserted else { throw CleanupItemError.duplicatePath(url) }
            return PathSnapshot(url: url, kind: snapshot.kind, size: snapshot.size, modificationDate: snapshot.modificationDate)
        }

        for index in canonicalPaths.indices {
            for other in canonicalPaths[(index + 1)...] {
                if Self.pathsTouch(canonicalPaths[index].url, other.url) {
                    throw CleanupItemError.nestedPaths(canonicalPaths[index].url, other.url)
                }
            }
        }

        if risk == .protected {
            guard !cleanupAllowed else { throw CleanupItemError.protectedItemMustNotBeCleanable }
            guard !selectedByDefault else { throw CleanupItemError.protectedItemMustNotBeSelected }
        }
        if !cleanupAllowed {
            guard !selectedByDefault else { throw CleanupItemError.protectedItemMustNotBeSelected }
            guard recommendedAction == .reviewOnly else { throw CleanupItemError.inconsistentAction }
        } else {
            guard recommendedAction == .moveToTrash else { throw CleanupItemError.inconsistentAction }
        }

        self.id = Self.makeID(category: category, application: application, paths: canonicalPaths)
        self.category = category
        self.application = application
        self.title = title
        self.reason = reason
        self.paths = canonicalPaths
        self.risk = risk
        self.confidence = confidence
        self.evidence = evidence
        self.recommendedAction = recommendedAction
        self.selectedByDefault = selectedByDefault
        self.cleanupAllowed = cleanupAllowed
        self.modifiedAt = modifiedAt
    }

    private static func makeID(category: ScanCategory, application: ApplicationIdentity?, paths: [PathSnapshot]) -> CleanupItemID {
        var components = [category.rawValue]
        if let application {
            if let bundleIdentifier = application.bundleIdentifier {
                components.append("bundle:" + bundleIdentifier.normalized)
            } else {
                components.append("name:" + application.name.lowercased())
            }
        }
        components.append(contentsOf: paths.map { $0.url.path }.sorted())
        return CleanupItemID(stableComponents: components)
    }

    private static func pathsTouch(_ lhs: URL, _ rhs: URL) -> Bool {
        guard lhs != rhs else { return true }
        let lhsPath = lhs.path.hasSuffix("/") ? lhs.path : lhs.path + "/"
        let rhsPath = rhs.path.hasSuffix("/") ? rhs.path : rhs.path + "/"
        return rhs.path.hasPrefix(lhsPath) || lhs.path.hasPrefix(rhsPath)
    }
}
