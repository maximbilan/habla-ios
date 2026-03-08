import XCTest
@testable import habla_ios

final class AppReducerTranslationSettingsTests: LogicTestCase {
    func testCallerMemoryLoadedDoesNotOverrideTranslationSelections() {
        var state = AppState()
        state.translationSourceLanguage = "en-US"
        state.translationTargetLanguage = "es-US"
        state.phoneNumber = "+14155550123"

        let memory = CallerMemory(
            phoneKey: "+14155550123",
            phoneNumber: "+14155550123",
            consentGranted: true,
            preferredTargetLanguage: "en-US",
            preferredTone: .neutral,
            priorIssues: "",
            callCount: 3,
            lastCallAt: Date(),
            updatedAt: Date()
        )

        appReducer(
            state: &state,
            action: .callerMemoryLoaded(phoneKey: "+14155550123", memory: memory)
        )

        XCTAssertEqual(state.translationSourceLanguage, "en-US")
        XCTAssertEqual(state.translationTargetLanguage, "es-US")
        XCTAssertEqual(state.activeCallerMemoryPhoneKey, "+14155550123")
        XCTAssertEqual(state.activeCallerMemory, memory)
    }

    func testTranslationSourceLanguageChangedCanonicalizesAliasAndAvoidsTargetConflict() {
        var state = AppState()
        state.translationSourceLanguage = "en-US"
        state.translationTargetLanguage = "es-US"

        appReducer(state: &state, action: .translationSourceLanguageChanged("es"))

        XCTAssertEqual(state.translationSourceLanguage, "es-US")
        XCTAssertEqual(state.translationTargetLanguage, "en-US")
    }

    func testTranslationTargetLanguageChangedCanonicalizesAliasAndAvoidsSourceConflict() {
        var state = AppState()
        state.translationSourceLanguage = "en-US"
        state.translationTargetLanguage = "es-US"

        appReducer(state: &state, action: .translationTargetLanguageChanged("en"))

        XCTAssertEqual(state.translationTargetLanguage, "en-US")
        XCTAssertEqual(state.translationSourceLanguage, "en-GB")
    }

    func testInvalidTranslationSourceLanguageIsIgnored() {
        var state = AppState()
        state.translationSourceLanguage = "en-US"
        state.translationTargetLanguage = "es-US"

        appReducer(state: &state, action: .translationSourceLanguageChanged("xx-YY"))

        XCTAssertEqual(state.translationSourceLanguage, "en-US")
        XCTAssertEqual(state.translationTargetLanguage, "es-US")
    }
}
