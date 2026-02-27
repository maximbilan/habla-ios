import Foundation

enum BackendRequestContext {
    static let deviceIdHeader = "X-Habla-Device-ID"

    static func apply(to request: inout URLRequest) {
        let deviceId = DeviceIdentity.current.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !deviceId.isEmpty else {
            return
        }
        request.setValue(deviceId, forHTTPHeaderField: deviceIdHeader)
    }
}
