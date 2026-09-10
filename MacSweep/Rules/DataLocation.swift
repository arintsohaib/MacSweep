import Foundation

public enum DataLocation: String, CaseIterable, Sendable, Equatable {
    case applicationSupport
    case caches
    case container
    case groupContainer
    case preferences
    case webKit
    case httpStorages
    case savedState
    case logs
    case launchAgents

    public var displayName: String {
        switch self {
        case .applicationSupport: "Application Support"
        case .caches: "Caches"
        case .container: "Sandbox Container"
        case .groupContainer: "Group Container"
        case .preferences: "Preferences"
        case .webKit: "WebKit Storage"
        case .httpStorages: "HTTP Storages"
        case .savedState: "Saved Application State"
        case .logs: "Logs"
        case .launchAgents: "Launch Metadata"
        }
    }
}
