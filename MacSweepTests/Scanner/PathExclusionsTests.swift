import Foundation
import Testing

@testable import MacSweep

@Suite("PathExclusions")
struct PathExclusionsTests {
    private func url(_ path: String) -> URL {
        URL(fileURLWithPath: path)
    }

    @Test("exact path is excluded")
    func exact() {
        let exclusions = PathExclusions(paths: [url("/Users/u/Library/Caches/app")])
        #expect(exclusions.isExcluded(url("/Users/u/Library/Caches/app")))
    }

    @Test("descendants are excluded")
    func descendants() {
        let exclusions = PathExclusions(paths: [url("/Users/u/Library/Caches/app")])
        #expect(exclusions.isExcluded(url("/Users/u/Library/Caches/app/nested/file.bin")))
    }

    @Test("ancestors are not excluded")
    func ancestors() {
        let exclusions = PathExclusions(paths: [url("/Users/u/Library/Caches/app")])
        #expect(!exclusions.isExcluded(url("/Users/u/Library/Caches")))
    }

    @Test("sibling paths sharing a prefix are not excluded")
    func siblings() {
        let exclusions = PathExclusions(paths: [url("/Users/u/Library/Caches/app")])
        #expect(!exclusions.isExcluded(url("/Users/u/Library/Caches/app-b")))
    }

    @Test("empty exclusions exclude nothing")
    func empty() {
        let exclusions = PathExclusions(paths: [])
        #expect(exclusions.isEmpty)
        #expect(!exclusions.isExcluded(url("/Users/u/Library/Caches/app")))
    }
}
