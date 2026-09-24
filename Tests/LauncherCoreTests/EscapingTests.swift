import XCTest
@testable import LauncherCore

final class EscapingTests: XCTestCase {
    func testPlainDirectoryOnlyCd() {
        XCTAssertEqual(
            Escaping.shellCommand(directory: "/Users/me/code", command: ""),
            "cd '/Users/me/code'"
        )
    }

    func testCommandAppendedAndTrimmed() {
        XCTAssertEqual(
            Escaping.shellCommand(directory: "/tmp", command: "  claude \n"),
            "cd '/tmp' && claude"
        )
    }

    func testSingleQuoteInDirectory() {
        XCTAssertEqual(
            Escaping.shellCommand(directory: "/Users/me/Bob's stuff", command: ""),
            "cd '/Users/me/Bob'\\''s stuff'"
        )
    }

    func testShellMetacharactersStayQuoted() {
        let dir = "/tmp/$HOME `x` \"q\" \\ 中文 空格"
        XCTAssertEqual(
            Escaping.shellCommand(directory: dir, command: ""),
            "cd '\(dir)'"
        )
    }

    func testAppleScriptStringEscapesBackslashAndQuote() {
        XCTAssertEqual(Escaping.appleScriptString(#"a\b"c"#), #""a\\b\"c""#)
    }

    func testAppleScriptStringOfFullCommand() {
        let shell = Escaping.shellCommand(directory: #"/tmp/a"b\c"#, command: #"echo "hi""#)
        XCTAssertEqual(shell, #"cd '/tmp/a"b\c' && echo "hi""#)
        XCTAssertEqual(
            Escaping.appleScriptString(shell),
            #""cd '/tmp/a\"b\\c' && echo \"hi\"""#
        )
    }
}
