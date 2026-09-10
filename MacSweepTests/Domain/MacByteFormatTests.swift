import Testing

@testable import MacSweep

@Suite("MacByteFormat")
struct MacByteFormatTests {
    @Test("bytes under one kibibyte")
    func bytes() {
        #expect(MacByteFormat.format(0) == "0 B")
        #expect(MacByteFormat.format(1) == "1 B")
        #expect(MacByteFormat.format(512) == "512 B")
    }

    @Test("kibibytes and above")
    func kibibytes() {
        #expect(MacByteFormat.format(1024) == "1 KB")
        #expect(MacByteFormat.format(1536) == "1.5 KB")
        #expect(MacByteFormat.format(1024 * 1024) == "1 MB")
        #expect(MacByteFormat.format(1572864) == "1.5 MB")
        #expect(MacByteFormat.format(Int64(1024) * 1024 * 1024) == "1 GB")
    }

    @Test("rounding carries up instead of showing 1024 of the next unit")
    func rounding() {
        #expect(MacByteFormat.format(Int64(1024) * 1024 - 1) == "1 MB")
        #expect(MacByteFormat.format(Int64(1023) * 1024) == "1023 KB")
    }
}
