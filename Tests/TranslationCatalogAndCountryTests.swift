import XCTest
@testable import habla_ios

final class TranslationCatalogAndCountryTests: LogicTestCase {
    func testLanguageCatalogResolvesAliasAndNormalization() {
        XCTAssertEqual(TranslationLanguageCatalog.language(code: "es")?.code, "es-US")
        XCTAssertEqual(TranslationLanguageCatalog.language(code: "EN_us")?.code, "en-US")
    }

    func testLanguageCatalogReturnsNilForUnsupportedLanguage() {
        XCTAssertNil(TranslationLanguageCatalog.language(code: "xx-YY"))
    }

    func testLanguageLabelWithEmojiFallsBackToRawCodeForUnknownLanguage() {
        XCTAssertEqual(TranslationLanguageCatalog.languageLabelWithEmoji(for: "xx-YY"), "xx-YY")
    }

    func testFallbackLanguageExcludesRequestedLanguage() {
        let fallback = TranslationLanguageCatalog.fallbackLanguage(excluding: "es-US")
        XCTAssertNotEqual(fallback.code, "es-US")
    }

    func testSpanishLanguageFlagUsesSpainEmoji() {
        let spanish = TranslationLanguageCatalog.language(code: "es-US")
        XCTAssertEqual(spanish?.flagEmoji, "🇪🇸")
    }

    func testPhoneCountryLookupIsCaseInsensitive() {
        XCTAssertEqual(PhoneCountryCatalog.country(isoCode: "us")?.dialCode, "+1")
    }

    func testCountryForPhoneNumberResolvesKnownPrefix() {
        XCTAssertEqual(PhoneCountryCatalog.countryForPhoneNumber("+351912345678")?.isoCode, "PT")
    }

    func testCountryForPhoneNumberReturnsNilForUnknownPrefix() {
        XCTAssertNil(PhoneCountryCatalog.countryForPhoneNumber("+99912345"))
    }
}
