import XCTest
@testable import SwifterX

final class InputSanitizerTests: XCTestCase {

    // MARK: - clean / trim

    func testTrimLeadingTrailingWhitespace() {
        XCTAssertEqual(InputSanitizer.clean("  hello  ", limit: 100), "hello")
    }

    func testLengthCapEnforced() {
        let long = String(repeating: "a", count: 200)
        let result = InputSanitizer.clean(long, limit: 50)
        XCTAssertEqual(result.count, 50)
    }

    func testEmptyStringAfterTrimStaysEmpty() {
        XCTAssertEqual(InputSanitizer.clean("   ", limit: 100), "")
    }

    // MARK: - email

    func testEmailLowercased() {
        XCTAssertEqual(InputSanitizer.email("USER@EXAMPLE.COM"), "user@example.com")
    }

    func testEmailStripsSpaces() {
        XCTAssertEqual(InputSanitizer.email("  user@example.com  "), "user@example.com")
    }

    func testEmailCappedAt120() {
        let local  = String(repeating: "a", count: 110)
        let result = InputSanitizer.email("\(local)@example.com")
        XCTAssertLessThanOrEqual(result.count, FieldLimit.email)
    }

    // MARK: - promoCode

    func testPromoCodeUppercased() {
        XCTAssertEqual(InputSanitizer.promoCode("save10"), "SAVE10")
    }

    func testPromoCodeStripsSpaces() {
        XCTAssertEqual(InputSanitizer.promoCode("  SAVE10  "), "SAVE10")
    }

    func testPromoCodeAllowsHyphen() {
        XCTAssertEqual(InputSanitizer.promoCode("SAVE-10"), "SAVE-10")
    }

    func testPromoCodeStripsSpecialChars() {
        let result = InputSanitizer.promoCode("SAVE!@#10")
        XCTAssertFalse(result.contains("!"))
        XCTAssertFalse(result.contains("@"))
        XCTAssertFalse(result.contains("#"))
    }

    // MARK: - name

    func testNameAllowsLettersAndSpaces() {
        XCTAssertEqual(InputSanitizer.name("John Doe"), "John Doe")
    }

    func testNameAllowsHyphen() {
        XCTAssertEqual(InputSanitizer.name("Mary-Jane"), "Mary-Jane")
    }

    func testNameStripsNumbers() {
        let result = InputSanitizer.name("John123")
        XCTAssertFalse(result.contains("1"))
    }

    // MARK: - hourlyRate

    func testHourlyRateStripsLetters() {
        let result = InputSanitizer.hourlyRate("50abc")
        XCTAssertEqual(result, "50")
    }

    func testHourlyRateAllowsDot() {
        XCTAssertEqual(InputSanitizer.hourlyRate("75.50"), "75.50")
    }

    // MARK: - validateEmail

    func testValidEmailPassesValidation() {
        XCTAssertNil(InputSanitizer.validateEmail("user@example.com"))
    }

    func testMissingAtFailsValidation() {
        XCTAssertNotNil(InputSanitizer.validateEmail("userexample.com"))
    }

    func testMissingDomainFailsValidation() {
        XCTAssertNotNil(InputSanitizer.validateEmail("user@"))
    }

    func testEmptyEmailFailsValidation() {
        XCTAssertNotNil(InputSanitizer.validateEmail(""))
    }

    // MARK: - validatePassword

    func testShortPasswordFails() {
        XCTAssertNotNil(InputSanitizer.validatePassword("abc123"))   // 6 chars < 8
    }

    func testPasswordWithoutDigitFails() {
        XCTAssertNotNil(InputSanitizer.validatePassword("abcdefgh"))
    }

    func testValidPasswordPasses() {
        XCTAssertNil(InputSanitizer.validatePassword("SecurePass1"))
    }

    // MARK: - validateName

    func testEmptyNameFails() {
        XCTAssertNotNil(InputSanitizer.validateName(""))
    }

    func testSingleCharNameFails() {
        XCTAssertNotNil(InputSanitizer.validateName("A"))
    }

    func testValidNamePasses() {
        XCTAssertNil(InputSanitizer.validateName("Alice"))
    }

    // MARK: - validateHourlyRate

    func testZeroRateFails() {
        XCTAssertNotNil(InputSanitizer.validateHourlyRate("0"))
    }

    func testNegativeRateFails() {
        XCTAssertNotNil(InputSanitizer.validateHourlyRate("-10"))
    }

    func testReasonableRatePasses() {
        XCTAssertNil(InputSanitizer.validateHourlyRate("75"))
    }

    func testExcessiveRateFails() {
        XCTAssertNotNil(InputSanitizer.validateHourlyRate("99999"))
    }

    // MARK: - validateServiceRadius

    func testZeroRadiusFails() {
        XCTAssertNotNil(InputSanitizer.validateServiceRadius("0"))
    }

    func testOver100MilesFails() {
        XCTAssertNotNil(InputSanitizer.validateServiceRadius("101"))
    }

    func testValid50MilesPasses() {
        XCTAssertNil(InputSanitizer.validateServiceRadius("50"))
    }
}
