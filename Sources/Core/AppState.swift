//
//  AppState.swift
//  habla-ios
//

import Foundation

struct AppState: Equatable {
    static let dialCountryCodeKey = "dialCountryCode"
    static let translationSourceLanguageKey = "translationSourceLanguage"
    static let translationTargetLanguageKey = "translationTargetLanguage"

    // Call state
    var callStatus: CallStatus = .idle
    var callSid: String? = nil
    var selectedDialCountryCode: String = UserDefaults.standard.string(forKey: AppState.dialCountryCodeKey)
        ?? PhoneCountryCatalog.defaultCountry.isoCode
    var phoneNumber: String = PhoneCountryCatalog.dialCode(
        for: UserDefaults.standard.string(forKey: AppState.dialCountryCodeKey)
            ?? PhoneCountryCatalog.defaultCountry.isoCode
    )
    var callDuration: TimeInterval = 0
    var callError: AppError? = nil

    // Audio state
    var isMuted: Bool = false
    var isSpeaker: Bool = false
    var inputAudioLevel: Float = 0.0
    var outputAudioLevel: Float = 0.0
    var isReceivingAudio: Bool = false

    // UI state
    var dialpadInput: String = ""
    var activeScreen: ActiveScreen = .dialer
    var callMode: CallMode = .translation

    // Agent mode
    var agentPrompt: String = ""
    var agentUserName: String = UserDefaults.standard.string(forKey: "agentUserName") ?? ""
    var agentTranscript: [TranscriptEntry] = []
    var agentStatus: AgentStatus = .idle
    var agentMidCallInput: String = ""

    // Settings
    var serverURL: String = AppConfig.backendURL
    var translationSourceLanguage: String = UserDefaults.standard.string(forKey: AppState.translationSourceLanguageKey)
        ?? TranslationLanguageCatalog.defaultSource.code
    var translationTargetLanguage: String = UserDefaults.standard.string(forKey: AppState.translationTargetLanguageKey)
        ?? TranslationLanguageCatalog.defaultTarget.code

    // Caller ID
    var callerId: CallerIdState = CallerIdState(
        selectedNumberSid: UserDefaults.standard.string(forKey: CallerIdState.selectedCallerIdKey)
    )

    // Call history
    var recentCalls: [CallRecord] = []
}

struct CallerIdState: Equatable, Sendable {
    static let selectedCallerIdKey = "selectedCallerIdSid"
    static let selectedCountryCodeKey = "callerIdCountryCode"

    var selectedCountryCode: String = UserDefaults.standard.string(forKey: CallerIdState.selectedCountryCodeKey)
        ?? PhoneCountryCatalog.defaultCountry.isoCode
    var phoneNumber: String = PhoneCountryCatalog.dialCode(
        for: UserDefaults.standard.string(forKey: CallerIdState.selectedCountryCodeKey)
            ?? PhoneCountryCatalog.defaultCountry.isoCode
    )
    var friendlyName: String = ""
    var verificationStatus: CallerIdVerificationStatus = .unknown
    var validationCode: String? = nil
    var verifiedNumbers: [VerifiedCallerId] = []
    var selectedNumberSid: String? = nil
    var isLoading: Bool = false
    var error: AppError? = nil
}

enum CallerIdVerificationStatus: Equatable, Sendable {
    case unknown
    case unverified
    case verifying
    case verified
    case failed(String)
}

enum CallStatus: Equatable, Sendable {
    case idle
    case initiating
    case connecting
    case ringing
    case connected
    case ended
    case failed(String)
}

enum ActiveScreen: Equatable, Hashable, Sendable {
    case dialer
    case callHistory
    case activeCall
    case agentSetup
    case agentCall
    case settings
}

enum CallMode: Equatable, Sendable {
    case translation
    case agent
}

enum AgentStatus: Equatable, Sendable {
    case idle
    case listening
    case speaking
    case thinking
}

struct PhoneCountry: Equatable, Sendable, Identifiable {
    let isoCode: String
    let name: String
    let dialCode: String

    var id: String { isoCode }
    var flagEmoji: String {
        if isoCode == PhoneCountryCatalog.manualCountry.isoCode {
            return "🌍"
        }
        return emojiFlag(forRegionCode: isoCode)
    }
    var label: String { "\(flagEmoji) \(name) (\(dialCode))" }
}

enum PhoneCountryCatalog {
    static let manualCountry = PhoneCountry(isoCode: "ZZ", name: "Any Country", dialCode: "+")

    static let countries: [PhoneCountry] = [
        manualCountry,
        .init(isoCode: "ES", name: "Spain", dialCode: "+34"),
        .init(isoCode: "US", name: "United States", dialCode: "+1"),
        .init(isoCode: "CA", name: "Canada", dialCode: "+1"),
        .init(isoCode: "GB", name: "United Kingdom", dialCode: "+44"),
        .init(isoCode: "AU", name: "Australia", dialCode: "+61"),
        .init(isoCode: "IN", name: "India", dialCode: "+91"),
        .init(isoCode: "DE", name: "Germany", dialCode: "+49"),
        .init(isoCode: "FR", name: "France", dialCode: "+33"),
        .init(isoCode: "IT", name: "Italy", dialCode: "+39"),
        .init(isoCode: "PT", name: "Portugal", dialCode: "+351"),
        .init(isoCode: "BR", name: "Brazil", dialCode: "+55"),
        .init(isoCode: "MX", name: "Mexico", dialCode: "+52"),
        .init(isoCode: "AR", name: "Argentina", dialCode: "+54"),
        .init(isoCode: "CL", name: "Chile", dialCode: "+56"),
        .init(isoCode: "CO", name: "Colombia", dialCode: "+57"),
        .init(isoCode: "PE", name: "Peru", dialCode: "+51"),
        .init(isoCode: "JP", name: "Japan", dialCode: "+81"),
    ]

    static let defaultCountry = manualCountry

    private static let countryByCode: [String: PhoneCountry] = Dictionary(
        uniqueKeysWithValues: countries.map { ($0.isoCode.uppercased(), $0) }
    )

    static func country(isoCode: String) -> PhoneCountry? {
        countryByCode[isoCode.uppercased()]
    }

    static func dialCode(for isoCode: String) -> String {
        country(isoCode: isoCode)?.dialCode ?? defaultCountry.dialCode
    }

    static func countryForPhoneNumber(_ phoneNumber: String) -> PhoneCountry? {
        let sortedByDialCodeLength = countries
            .filter { $0.isoCode != manualCountry.isoCode }
            .sorted { $0.dialCode.count > $1.dialCode.count }
        return sortedByDialCodeLength.first { phoneNumber.hasPrefix($0.dialCode) }
    }
}

struct SupportedTranslationLanguage: Equatable, Sendable, Identifiable {
    let code: String
    let name: String
    let localeLabel: String

    var id: String { code }
    var languageCode: String { code.split(separator: "-").first.map(String.init)?.lowercased() ?? "" }
    var regionCode: String { code.split(separator: "-").last.map(String.init) ?? "" }
    var flagEmoji: String {
        if languageCode == "es" {
            return emojiFlag(forRegionCode: "ES")
        }
        return emojiFlag(forRegionCode: regionCode)
    }
    var label: String {
        if localeLabel.isEmpty {
            return name
        }
        return "\(name) (\(localeLabel))"
    }
    var labelWithEmoji: String { "\(flagEmoji) \(label)" }
}

enum TranslationLanguageCatalog {
    static let languages: [SupportedTranslationLanguage] = [
        .init(code: "en-US", name: "English", localeLabel: "US"),
        .init(code: "en-GB", name: "English", localeLabel: "UK"),
        .init(code: "en-AU", name: "English", localeLabel: "Australia"),
        .init(code: "en-IN", name: "English", localeLabel: "India"),
        .init(code: "es-US", name: "Spanish", localeLabel: "US"),
        .init(code: "fr-FR", name: "French", localeLabel: "France"),
        .init(code: "de-DE", name: "German", localeLabel: "Germany"),
        .init(code: "it-IT", name: "Italian", localeLabel: "Italy"),
        .init(code: "pt-BR", name: "Portuguese", localeLabel: "Brazil"),
        .init(code: "hi-IN", name: "Hindi", localeLabel: "India"),
    ]

    static let defaultSource = languages[0]
    static let defaultTarget = languages[4]

    private static let aliases: [String: String] = [
        "en": "en-US",
        "es": "es-US",
        "fr": "fr-FR",
        "de": "de-DE",
        "it": "it-IT",
        "pt": "pt-BR",
        "hi": "hi-IN",
    ]

    private static let languageByNormalizedCode: [String: SupportedTranslationLanguage] = Dictionary(
        uniqueKeysWithValues: languages.map { (normalize(code: $0.code), $0) }
    )

    static func language(code: String) -> SupportedTranslationLanguage? {
        let normalized = normalize(code: code)
        if let canonical = aliases[normalized] {
            return languageByNormalizedCode[normalize(code: canonical)]
        }
        return languageByNormalizedCode[normalized]
    }

    static func languageLabel(for code: String) -> String {
        language(code: code)?.label ?? code
    }

    static func languageLabelWithEmoji(for code: String) -> String {
        guard let language = language(code: code) else { return code }
        return language.labelWithEmoji
    }

    static func fallbackLanguage(excluding code: String) -> SupportedTranslationLanguage {
        languages.first(where: { $0.code != code }) ?? defaultTarget
    }

    private static func normalize(code: String) -> String {
        code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()
    }
}

private func emojiFlag(forRegionCode rawCode: String) -> String {
    let regionCode = rawCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    guard regionCode.count == 2 else { return "🏳️" }

    let scalars = regionCode.unicodeScalars.compactMap { scalar -> UnicodeScalar? in
        let value = scalar.value
        guard (65...90).contains(value) else { return nil }
        return UnicodeScalar(127397 + value)
    }

    guard scalars.count == 2 else { return "🏳️" }
    return String(String.UnicodeScalarView(scalars))
}
