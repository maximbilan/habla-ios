import XCTest
@testable import habla_ios

class LogicTestCase: XCTestCase {
    private let defaultsKeys: [String] = [
        AppState.dialCountryCodeKey,
        AppState.translationSourceLanguageKey,
        AppState.translationTargetLanguageKey,
        AppState.selectedBackendServiceKey,
        AppState.selectedVoiceGenderKey,
        CallerIdState.selectedCallerIdKey,
        CallerIdState.selectedCountryCodeKey,
        "agentUserName",
    ]

    override func setUp() {
        super.setUp()
        clearPersistedState()
    }

    override func tearDown() {
        clearPersistedState()
        super.tearDown()
    }

    private func clearPersistedState() {
        for key in defaultsKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
