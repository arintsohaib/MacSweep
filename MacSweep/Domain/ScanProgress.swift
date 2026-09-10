import Foundation

public struct ScanProgress: Equatable, Sendable {
    public enum Phase: String, Equatable, Sendable {
        case running
        case finishing
        case complete
        case cancelled
        case failed
    }

    public var phase: Phase
    public var currentCategory: ScanCategory?
    public var message: String
    public var fractionComplete: Double?

    public init(
        phase: Phase,
        currentCategory: ScanCategory? = nil,
        message: String,
        fractionComplete: Double? = nil
    ) {
        self.phase = phase
        self.currentCategory = currentCategory
        self.message = message
        self.fractionComplete = fractionComplete
    }

    public var isFinished: Bool {
        phase == .complete || phase == .cancelled || phase == .failed
    }
}
