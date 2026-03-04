import Foundation
import Security

enum DeviceIdentity {
    private static let userDefaultsKey = "hablaDeviceId"
    private static let keychainAccount = "habla.device.id"

    static var current: String {
        if let cached = UserDefaults.standard.string(forKey: userDefaultsKey), !cached.isEmpty {
            return cached
        }

        if let stored = readFromKeychain(), !stored.isEmpty {
            UserDefaults.standard.set(stored, forKey: userDefaultsKey)
            return stored
        }

        let generated = generatedId()
        UserDefaults.standard.set(generated, forKey: userDefaultsKey)
        storeInKeychain(generated)
        return generated
    }

    private static func generatedId() -> String {
        return UUID().uuidString
    }

    private static func readFromKeychain() -> String? {
        var query = keychainQuery()
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private static func storeInKeychain(_ value: String) {
        let data = Data(value.utf8)

        var addQuery = keychainQuery()
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus == errSecDuplicateItem {
            let updateAttributes: [String: Any] = [kSecValueData as String: data]
            SecItemUpdate(keychainQuery() as CFDictionary, updateAttributes as CFDictionary)
        }
    }

    private static func keychainQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.maximbilan.habla-ios",
            kSecAttrAccount as String: keychainAccount,
        ]
    }
}
