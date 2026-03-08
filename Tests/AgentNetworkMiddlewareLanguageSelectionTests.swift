import XCTest
@testable import habla_ios

final class AgentNetworkMiddlewareLanguageSelectionTests: LogicTestCase {
    func testResolveCalleeLanguageUsesSettingsTargetLanguageWhenCallerMemoryDiffers() {
        let middleware = AgentNetworkMiddleware()
        var state = AppState()
        state.phoneNumber = "+14155550123"
        state.translationTargetLanguage = "es-US"
        state.activeCallerMemoryPhoneKey = "+14155550123"
        state.activeCallerMemory = CallerMemory(
            phoneKey: "+14155550123",
            phoneNumber: "+14155550123",
            consentGranted: true,
            preferredTargetLanguage: "en-US",
            preferredTone: .friendly,
            priorIssues: "",
            callCount: 2,
            lastCallAt: Date(),
            updatedAt: Date()
        )

        let resolved = middleware.resolveCalleeLanguage(for: state.phoneNumber, state: state)

        XCTAssertEqual(resolved, "es-US")
    }

    func testResolveCalleeLanguageNormalizesAliasFromSettings() {
        let middleware = AgentNetworkMiddleware()
        var state = AppState()
        state.translationTargetLanguage = "es"

        let resolved = middleware.resolveCalleeLanguage(for: "+14155550123", state: state)

        XCTAssertEqual(resolved, "es-US")
    }

    func testResolveCalleeLanguageFallsBackToDefaultWhenSettingsValueIsInvalid() {
        let middleware = AgentNetworkMiddleware()
        var state = AppState()
        state.translationTargetLanguage = "xx-YY"

        let resolved = middleware.resolveCalleeLanguage(for: "+14155550123", state: state)

        XCTAssertEqual(resolved, TranslationLanguageCatalog.defaultTarget.code)
    }

    func testResolveCalleeLanguageNormalizesUnderscoreVariant() {
        let middleware = AgentNetworkMiddleware()
        var state = AppState()
        state.translationTargetLanguage = "pt_BR"

        let resolved = middleware.resolveCalleeLanguage(for: "+14155550123", state: state)

        XCTAssertEqual(resolved, "pt-BR")
    }
}
