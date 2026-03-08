import XCTest
@testable import habla_ios

final class AppReducerDialingAndNavigationTests: LogicTestCase {
    func testDialCountryChangedFromManualCountryReplacesDetectedDialCode() {
        var state = AppState()
        state.selectedDialCountryCode = PhoneCountryCatalog.manualCountry.isoCode
        state.phoneNumber = "+34600111222"

        appReducer(state: &state, action: .dialCountryChanged("US"))

        XCTAssertEqual(state.selectedDialCountryCode, "US")
        XCTAssertEqual(state.phoneNumber, "+1600111222")
    }

    func testPhoneNumberChangedAutoSelectsCountryCodeFromDialPrefix() {
        var state = AppState()
        state.selectedDialCountryCode = PhoneCountryCatalog.manualCountry.isoCode

        appReducer(state: &state, action: .phoneNumberChanged("+34911222333"))

        XCTAssertEqual(state.selectedDialCountryCode, "ES")
        XCTAssertEqual(state.phoneNumber, "+34911222333")
    }

    func testDialpadBackspaceDoesNotRemoveDialCode() {
        var state = AppState()
        state.selectedDialCountryCode = "US"
        state.phoneNumber = "+1"

        appReducer(state: &state, action: .dialpadBackspace)

        XCTAssertEqual(state.phoneNumber, "+1")
    }

    func testDialpadBackspaceRemovesLastDigitWhenBeyondDialCode() {
        var state = AppState()
        state.selectedDialCountryCode = "US"
        state.phoneNumber = "+1234"

        appReducer(state: &state, action: .dialpadBackspace)

        XCTAssertEqual(state.phoneNumber, "+123")
    }

    func testOpenAndCloseCallSummaryRestoresReturnScreen() {
        var state = AppState()
        state.activeScreen = .callHistory
        let record = CallRecord(phoneNumber: "+14155550123")

        appReducer(state: &state, action: .openCallSummary(record))
        XCTAssertEqual(state.activeScreen, .callSummary)
        XCTAssertEqual(state.callSummaryReturnScreen, .callHistory)

        appReducer(state: &state, action: .closeCallSummary)
        XCTAssertEqual(state.activeScreen, .callHistory)
        XCTAssertEqual(state.callSummaryReturnScreen, .dialer)
        XCTAssertNil(state.selectedCallSummaryRecord)
    }
}
